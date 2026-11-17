//
//  FishingEngine.swift
//  RiverFishing
//
//  낚시 상태 머신(idle → casting → waiting → biting → caught)과 도감 영속화.
//  자동 낚시(방치형)와 화면 탭 챔질(보너스)을 모두 지원한다.
//

import Foundation
import Combine

// MARK: - 상태

enum FishingPhase: String, Equatable {
    case idle
    case casting
    case waiting
    case biting
    case caught
    case missed

    var title: String {
        switch self {
        case .idle: return "낚시 준비"
        case .casting: return "찌를 던지는 중"
        case .waiting: return "입질을 기다리는 중"
        case .biting: return "입질! 지금 낚아채세요"
        case .caught: return "낚아챘어요"
        case .missed: return "놓쳤어요"
        }
    }

    var detail: String {
        switch self {
        case .idle: return "잠시 뒤 캐스팅합니다"
        case .casting: return "낚싯줄이 물 위로 날아갑니다"
        case .waiting: return "찌의 움직임을 지켜보세요. 탭하면 조금 더 일찍 챔질할 수 있어요"
        case .biting: return "찌가 흔들리는 순간입니다"
        case .caught: return "도감에 기록하는 중"
        case .missed: return "다시 찌를 던집니다"
        }
    }

    var symbolName: String {
        switch self {
        case .idle: return "figure.fishing"
        case .casting: return "arrow.up.forward"
        case .waiting: return "water.waves"
        case .biting: return "exclamationmark.triangle.fill"
        case .caught: return "checkmark.circle.fill"
        case .missed: return "wind"
        }
    }
}

// MARK: - 저장소

/// 도감을 UserDefaults에 JSON으로 저장/복원한다.
struct FishBookStore: @unchecked Sendable {
    let key: String
    private let defaults: UserDefaults

    init(key: String, defaults: UserDefaults = .standard) {
        self.key = key
        self.defaults = defaults
    }

    func load() -> FishBook {
        guard let data = defaults.data(forKey: key) else { return FishBook() }
        return (try? JSONDecoder().decode(FishBook.self, from: data)) ?? FishBook()
    }

    func save(_ book: FishBook) {
        guard let data = try? JSONEncoder().encode(book) else { return }
        defaults.set(data, forKey: key)
    }
}

// MARK: - 엔진

@MainActor
final class FishingEngine: ObservableObject {

    // MARK: 발행 상태

    @Published private(set) var phase: FishingPhase = .idle
    /// 입질 창이 닫히기까지 남은 비율 (1 → 0).
    @Published private(set) var biteProgress: Double = 0
    @Published private(set) var book: FishBook
    @Published private(set) var toast: CatchResult?
    /// 3D 씬에 "지금 한 마리 잡았다"를 알리는 토큰.
    @Published private(set) var catchToken: Int = 0
    @Published private(set) var sessionCatches: Int = 0
    @Published private(set) var notice: String?
    @Published private(set) var isRunning: Bool = false

    /// 화면을 보지 않아도 알아서 낚시한다. 끄면 탭으로 챔질해야 한다.
    @Published var isAutoFishing: Bool = true

    // MARK: 내부

    private let store: FishBookStore
    private weak var timeOfDay: TimeOfDayService?
    private var loopTask: Task<Void, Never>?
    private var toastTask: Task<Void, Never>?
    private var noticeTask: Task<Void, Never>?
    private var pendingStrike = false
    private var manualStrike = false

    /// 입질 지속 시간(초). 이 안에 챔질해야 잡힌다.
    private let biteWindow: Double = 1.8

    nonisolated init(store: FishBookStore = FishBookStore(key: "riverFishing.fishBook.v1")) {
        self.store = store
        self.book = store.load()
    }

    deinit {
        loopTask?.cancel()
        toastTask?.cancel()
        noticeTask?.cancel()
    }

    /// 현재 시간대를 물고기 확률표에 연결한다.
    func attach(timeOfDay: TimeOfDayService) {
        self.timeOfDay = timeOfDay
    }

    /// 지금 출현 확률표를 고를 시간대.
    private var currentBand: TimeBand {
        timeOfDay?.band ?? .day
    }

    // MARK: 생명주기

    func start() {
        guard loopTask == nil else { return }
        isRunning = true
        loopTask = Task { [weak self] in
            await self?.runLoop()
        }
    }

    func stop() {
        loopTask?.cancel()
        loopTask = nil
        isRunning = false
        phase = .idle
        biteProgress = 0
    }

    /// 화면 탭 / 챔질 버튼.
    func strike() {
        switch phase {
        case .biting:
            pendingStrike = true
            manualStrike = true
        case .waiting:
            flashNotice("아직 입질이 없어요. 찌를 조금만 더 지켜봐 주세요")
        case .idle:
            if !isRunning {
                start()
            } else {
                flashNotice("찌를 다시 준비하고 있어요")
            }
        case .casting:
            flashNotice("찌가 물에 닿기를 기다리는 중이에요")
        case .caught, .missed:
            break
        }
    }

    func resetBook() {
        book.removeAll()
        store.save(book)
        sessionCatches = 0
        toast = nil
        flashNotice("도감을 초기화했어요")
    }

    // MARK: 낚시 루프

    private func runLoop() async {
        await wait(seconds: 0.5)
        while !Task.isCancelled {
            await fishOnce()
            if Task.isCancelled { return }
            await wait(seconds: 2.2)
        }
    }

    private func fishOnce() async {
        // 1) 캐스팅
        phase = .casting
        biteProgress = 0
        await wait(seconds: 1.5)
        if Task.isCancelled { return }

        // 2) 대기
        phase = .waiting
        let waitTime = Double.random(in: 4.5...11.0)
        await wait(seconds: waitTime)
        if Task.isCancelled { return }

        // 3) 입질 — 창이 닫히기 전에 챔질해야 한다
        phase = .biting
        pendingStrike = false
        manualStrike = false
        let autoDelay: Double? = isAutoFishing ? Double.random(in: 0.5...1.2) : nil
        var elapsed: Double = 0
        var hooked = false

        while elapsed < biteWindow {
            if Task.isCancelled { return }
            biteProgress = max(0, 1 - elapsed / biteWindow)

            if pendingStrike {
                pendingStrike = false
                hooked = true
                break
            }
            if let autoDelay, elapsed >= autoDelay {
                hooked = true
                manualStrike = false
                break
            }

            await wait(seconds: 0.05)
            elapsed += 0.05
        }

        biteProgress = 0

        // 4) 결과
        if hooked {
            landFish()
            await wait(seconds: 2.6)
        } else {
            phase = .missed
            flashNotice("놓쳤어요… 찌가 다시 잠잠해집니다")
            await wait(seconds: 1.8)
        }

        if Task.isCancelled { return }
        phase = .idle
    }

    private func landFish() {
        let fish = FishCatalog.roll(band: currentBand)

        // 손으로 챔질하면 조금 더 큰 개체가 걸린다.
        let bonus = manualStrike ? 1.12 : 1.0
        let rawLength = FishCatalog.length(for: fish) * bonus
        let length = min(fish.maxLengthCM, rawLength)

        let registration = book.register(fishID: fish.id, lengthCM: length, at: Date())
        let result = CatchResult(
            fish: fish,
            lengthCM: (length * 10).rounded() / 10,
            isNewSpecies: registration.isNewSpecies,
            isPersonalBest: registration.isPersonalBest,
            isPerfectTiming: manualStrike,
            caughtAt: Date()
        )

        store.save(book)
        phase = .caught
        catchToken += 1
        sessionCatches += 1
        showToast(result)

        if manualStrike {
            flashNotice("완벽한 타이밍! 조금 더 큰 개체가 올라왔어요")
        }
    }

    // MARK: 토스트 / 안내 문구

    private func showToast(_ result: CatchResult) {
        toastTask?.cancel()
        toast = result
        toastTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 3_600_000_000)
            guard let self, !Task.isCancelled else { return }
            self.toast = nil
        }
    }

    private func flashNotice(_ text: String) {
        noticeTask?.cancel()
        notice = text
        noticeTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_600_000_000)
            guard let self, !Task.isCancelled else { return }
            self.notice = nil
        }
    }

    // MARK: 유틸

    private func wait(seconds: Double) async {
        let nanoseconds = UInt64(max(0, seconds) * 1_000_000_000)
        try? await Task.sleep(nanoseconds: nanoseconds)
    }

    // MARK: 화면 표시용 값

    var caughtSpeciesCount: Int { book.caughtSpeciesCount }
    var speciesCount: Int { FishCatalog.speciesCount }

    var collectionProgress: Double {
        guard FishCatalog.speciesCount > 0 else { return 0 }
        return Double(book.caughtSpeciesCount) / Double(FishCatalog.speciesCount)
    }

    var statusText: String {
        if let notice { return notice }
        if phase == .caught, let toast {
            return "\(toast.fish.name) \(toast.lengthText) 획득"
        }
        return phase.detail
    }
}
