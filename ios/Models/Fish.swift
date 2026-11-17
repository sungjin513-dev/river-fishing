//
//  Fish.swift
//  RiverFishing
//
//  물고기 모델, 희귀도, 출현 시간대, 도감 기록(FishCatchRecord / FishBook).
//

import Foundation
import SwiftUI

// MARK: - 시간대

/// 하루를 네 구간으로 나눈 시간대. 현실 시각에 따라 하늘/조명/물빛이 바뀐다.
enum TimeBand: String, Codable, CaseIterable, Identifiable {
    case dawn
    case day
    case sunset
    case night

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dawn: return "새벽"
        case .day: return "낮"
        case .sunset: return "노을"
        case .night: return "밤"
        }
    }

    var hours: String {
        switch self {
        case .dawn: return "05:00 – 08:00"
        case .day: return "08:00 – 17:00"
        case .sunset: return "17:00 – 20:00"
        case .night: return "20:00 – 05:00"
        }
    }

    var symbolName: String {
        switch self {
        case .dawn: return "sunrise.fill"
        case .day: return "sun.max.fill"
        case .sunset: return "sunset.fill"
        case .night: return "moon.stars.fill"
        }
    }

    /// HUD에 한 줄로 띄우는 분위기 문구.
    var moodLine: String {
        switch self {
        case .dawn: return "물안개가 강 위를 천천히 떠다녀요"
        case .day: return "햇살이 수면에 부서지고 있어요"
        case .sunset: return "강물이 노을빛으로 물들고 있어요"
        case .night: return "별빛과 랜턴 불빛만 남았어요"
        }
    }

    var accent: Color {
        switch self {
        case .dawn: return Color(red: 0.98, green: 0.72, blue: 0.56)
        case .day: return Color(red: 0.55, green: 0.80, blue: 1.00)
        case .sunset: return Color(red: 1.00, green: 0.60, blue: 0.36)
        case .night: return Color(red: 0.62, green: 0.72, blue: 1.00)
        }
    }

    /// 미리보기(강제 시간대)에서 사용할 대표 시각.
    var previewHour: Double {
        switch self {
        case .dawn: return 6.4
        case .day: return 12.5
        case .sunset: return 18.4
        case .night: return 22.5
        }
    }

    /// 0시 기준 시각(소수 시간)으로 시간대를 판별한다.
    init(hour: Double) {
        let normalized = ((hour.truncatingRemainder(dividingBy: 24)) + 24)
            .truncatingRemainder(dividingBy: 24)
        switch normalized {
        case 5.0..<8.0:
            self = .dawn
        case 8.0..<17.0:
            self = .day
        case 17.0..<20.0:
            self = .sunset
        default:
            self = .night
        }
    }
}

// MARK: - 희귀도

enum Rarity: String, Codable, CaseIterable, Comparable {
    case common
    case uncommon
    case rare
    case legendary

    var displayName: String {
        switch self {
        case .common: return "흔함"
        case .uncommon: return "조금 희귀"
        case .rare: return "희귀"
        case .legendary: return "전설"
        }
    }

    /// 도감에 표시하는 별 개수.
    var stars: Int {
        switch self {
        case .common: return 1
        case .uncommon: return 2
        case .rare: return 3
        case .legendary: return 4
        }
    }

    var sortIndex: Int {
        switch self {
        case .common: return 0
        case .uncommon: return 1
        case .rare: return 2
        case .legendary: return 3
        }
    }

    var tint: Color {
        switch self {
        case .common: return Color(red: 0.72, green: 0.80, blue: 0.86)
        case .uncommon: return Color(red: 0.55, green: 0.86, blue: 0.72)
        case .rare: return Color(red: 0.58, green: 0.72, blue: 1.00)
        case .legendary: return Color(red: 1.00, green: 0.82, blue: 0.42)
        }
    }

    static func < (lhs: Rarity, rhs: Rarity) -> Bool {
        lhs.sortIndex < rhs.sortIndex
    }
}

// MARK: - 물고기

struct Fish: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let englishName: String
    let rarity: Rarity
    let minLengthCM: Double
    let maxLengthCM: Double
    /// 도감에 표시되는 한 줄 설명.
    let summary: String
    /// 어떤 시간대에 출현하는지는 카탈로그의 확률표에서 자동으로 채운다.
    var activeBands: [TimeBand] = []

    var lengthRangeText: String {
        String(format: "%.0f–%.0fcm", minLengthCM, maxLengthCM)
    }

    var bandText: String {
        activeBands.map(\.displayName).joined(separator: " · ")
    }

    var starText: String {
        String(repeating: "★", count: rarity.stars) + String(repeating: "☆", count: max(0, 4 - rarity.stars))
    }
}

// MARK: - 도감 기록

/// 한 어종에 대한 누적 기록. `Codable` 그대로 UserDefaults에 JSON으로 저장된다.
struct FishCatchRecord: Codable, Hashable, Identifiable {
    let fishID: String
    var catchCount: Int
    var longestLengthCM: Double
    var firstCaughtAt: Date
    var lastCaughtAt: Date

    var id: String { fishID }
}

/// 도감 전체. 어종 ID → 기록.
struct FishBook: Codable, Equatable {
    private(set) var records: [String: FishCatchRecord] = [:]

    init() {}

    var totalCatches: Int {
        records.values.reduce(0) { $0 + $1.catchCount }
    }

    var caughtSpeciesCount: Int { records.count }

    var longestLengthCM: Double {
        records.values.map(\.longestLengthCM).max() ?? 0
    }

    func record(for fishID: String) -> FishCatchRecord? {
        records[fishID]
    }

    func hasCaught(_ fishID: String) -> Bool {
        records[fishID] != nil
    }

    struct Registration: Equatable {
        let isNewSpecies: Bool
        let isPersonalBest: Bool
    }

    /// 한 마리 등록. 신규 어종/최대 길이 갱신 여부를 함께 돌려준다.
    @discardableResult
    mutating func register(fishID: String, lengthCM: Double, at date: Date) -> Registration {
        if var record = records[fishID] {
            let isPersonalBest = lengthCM > record.longestLengthCM
            record.catchCount += 1
            record.longestLengthCM = max(record.longestLengthCM, lengthCM)
            record.lastCaughtAt = date
            records[fishID] = record
            return Registration(isNewSpecies: false, isPersonalBest: isPersonalBest)
        }
        records[fishID] = FishCatchRecord(
            fishID: fishID,
            catchCount: 1,
            longestLengthCM: lengthCM,
            firstCaughtAt: date,
            lastCaughtAt: date
        )
        return Registration(isNewSpecies: true, isPersonalBest: true)
    }

    mutating func removeAll() {
        records.removeAll()
    }
}

// MARK: - 방금 잡은 결과

/// 토스트 배너와 3D 연출에 쓰이는 한 번의 낚시 결과.
struct CatchResult: Identifiable, Equatable {
    let id = UUID()
    let fish: Fish
    let lengthCM: Double
    let isNewSpecies: Bool
    let isPersonalBest: Bool
    let isPerfectTiming: Bool
    let caughtAt: Date

    init(
        fish: Fish,
        lengthCM: Double,
        isNewSpecies: Bool,
        isPersonalBest: Bool,
        isPerfectTiming: Bool,
        caughtAt: Date
    ) {
        self.fish = fish
        self.lengthCM = lengthCM
        self.isNewSpecies = isNewSpecies
        self.isPersonalBest = isPersonalBest
        self.isPerfectTiming = isPerfectTiming
        self.caughtAt = caughtAt
    }

    var lengthText: String {
        String(format: "%.1fcm", lengthCM)
    }

    var badgeText: String {
        if isNewSpecies { return "새 도감 등록" }
        if isPerfectTiming { return "완벽한 타이밍" }
        if isPersonalBest { return "최대 기록 갱신" }
        return "획득"
    }
}
