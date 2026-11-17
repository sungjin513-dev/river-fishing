//
//  TimeOfDayService.swift
//  RiverFishing
//
//  현재 시각을 시간대(새벽/낮/노을/밤)로 바꾸고, 그에 맞는 하늘·조명·안개·물빛·랜턴
//  파라미터(RiverMood)를 계산한다. 키프레임 사이를 보간해 하루가 부드럽게 흐른다.
//

import Foundation
import Combine
import UIKit
import SwiftUI

// MARK: - 한 순간의 강가 분위기

/// SceneKit 씬에 그대로 적용되는 값 묶음. 시각이 바뀌면 이 값들이 바뀐다.
struct RiverMood: Equatable, @unchecked Sendable {

    var band: TimeBand

    // 하늘
    var skyTop: UIColor
    var skyHorizon: UIColor

    // 해 / 달
    var sunDisc: UIColor
    var sunColor: UIColor
    var sunIntensity: CGFloat
    var sunAltitude: Double        // 도(°), 0 = 지평선
    var sunAzimuth: Double         // 도(°), 0 = 정면, +면 오른쪽
    var sunOpacity: CGFloat
    var moonOpacity: CGFloat
    var moonAltitude: Double
    var starOpacity: CGFloat

    // 주변광 / 안개
    var ambientColor: UIColor
    var ambientIntensity: CGFloat
    var fogColor: UIColor
    var fogStart: CGFloat
    var fogEnd: CGFloat

    // 물
    var waterColor: UIColor
    var waterRoughness: CGFloat
    var waterMetalness: CGFloat

    // 밤 조명
    var lanternIntensity: CGFloat
    var fireIntensity: CGFloat

    /// HUD에서 쓰는 SwiftUI 색.
    var horizonColor: Color { Color(uiColor: skyHorizon) }
}

// MARK: - 프리셋

extension RiverMood {

    static let dawn = RiverMood(
        band: .dawn,
        skyTop: UIColor(red: 0.14, green: 0.21, blue: 0.40, alpha: 1),
        skyHorizon: UIColor(red: 0.96, green: 0.68, blue: 0.52, alpha: 1),
        sunDisc: UIColor(red: 1.00, green: 0.87, blue: 0.68, alpha: 1),
        sunColor: UIColor(red: 1.00, green: 0.80, blue: 0.62, alpha: 1),
        sunIntensity: 560,
        sunAltitude: 10,
        sunAzimuth: 8,
        sunOpacity: 0.95,
        moonOpacity: 0,
        moonAltitude: -30,
        starOpacity: 0.16,
        ambientColor: UIColor(red: 0.55, green: 0.63, blue: 0.82, alpha: 1),
        ambientIntensity: 360,
        fogColor: UIColor(red: 0.74, green: 0.74, blue: 0.80, alpha: 1),
        fogStart: 8,
        fogEnd: 62,
        waterColor: UIColor(red: 0.24, green: 0.32, blue: 0.40, alpha: 1),
        waterRoughness: 0.16,
        waterMetalness: 0.44,
        lanternIntensity: 140,
        fireIntensity: 220
    )

    static let day = RiverMood(
        band: .day,
        skyTop: UIColor(red: 0.28, green: 0.54, blue: 0.88, alpha: 1),
        skyHorizon: UIColor(red: 0.78, green: 0.90, blue: 0.98, alpha: 1),
        sunDisc: UIColor(red: 1.00, green: 0.98, blue: 0.90, alpha: 1),
        sunColor: UIColor(red: 1.00, green: 0.96, blue: 0.88, alpha: 1),
        sunIntensity: 1100,
        sunAltitude: 58,
        sunAzimuth: 4,
        sunOpacity: 1,
        moonOpacity: 0,
        moonAltitude: -30,
        starOpacity: 0,
        ambientColor: UIColor(red: 0.72, green: 0.82, blue: 0.95, alpha: 1),
        ambientIntensity: 460,
        fogColor: UIColor(red: 0.82, green: 0.89, blue: 0.96, alpha: 1),
        fogStart: 26,
        fogEnd: 130,
        waterColor: UIColor(red: 0.14, green: 0.38, blue: 0.44, alpha: 1),
        waterRoughness: 0.14,
        waterMetalness: 0.30,
        lanternIntensity: 0,
        fireIntensity: 0
    )

    static let sunset = RiverMood(
        band: .sunset,
        skyTop: UIColor(red: 0.17, green: 0.18, blue: 0.40, alpha: 1),
        skyHorizon: UIColor(red: 0.99, green: 0.55, blue: 0.34, alpha: 1),
        sunDisc: UIColor(red: 1.00, green: 0.72, blue: 0.44, alpha: 1),
        sunColor: UIColor(red: 1.00, green: 0.60, blue: 0.34, alpha: 1),
        sunIntensity: 950,
        sunAltitude: 7,
        sunAzimuth: -7,
        sunOpacity: 1,
        moonOpacity: 0.15,
        moonAltitude: -14,
        starOpacity: 0.10,
        ambientColor: UIColor(red: 0.54, green: 0.45, blue: 0.60, alpha: 1),
        ambientIntensity: 400,
        fogColor: UIColor(red: 0.66, green: 0.46, blue: 0.44, alpha: 1),
        fogStart: 12,
        fogEnd: 80,
        waterColor: UIColor(red: 0.28, green: 0.20, blue: 0.24, alpha: 1),
        waterRoughness: 0.12,
        waterMetalness: 0.52,
        lanternIntensity: 430,
        fireIntensity: 400
    )

    static let night = RiverMood(
        band: .night,
        skyTop: UIColor(red: 0.02, green: 0.03, blue: 0.09, alpha: 1),
        skyHorizon: UIColor(red: 0.06, green: 0.09, blue: 0.18, alpha: 1),
        sunDisc: UIColor(red: 0.72, green: 0.80, blue: 1.00, alpha: 1),
        sunColor: UIColor(red: 0.62, green: 0.74, blue: 1.00, alpha: 1),
        sunIntensity: 170,
        sunAltitude: -32,
        sunAzimuth: 0,
        sunOpacity: 0,
        moonOpacity: 0.95,
        moonAltitude: 14,
        starOpacity: 0.92,
        ambientColor: UIColor(red: 0.34, green: 0.44, blue: 0.72, alpha: 1),
        ambientIntensity: 190,
        fogColor: UIColor(red: 0.04, green: 0.06, blue: 0.13, alpha: 1),
        fogStart: 14,
        fogEnd: 95,
        waterColor: UIColor(red: 0.03, green: 0.06, blue: 0.12, alpha: 1),
        waterRoughness: 0.08,
        waterMetalness: 0.62,
        lanternIntensity: 950,
        fireIntensity: 820
    )

    /// 0~24시 키프레임. 값 사이는 선형 보간된다.
    private static let keyframes: [(hour: Double, mood: RiverMood)] = [
        (0.0, night),
        (4.3, night),
        (5.8, dawn),
        (7.2, dawn),
        (8.8, day),
        (15.4, day),
        (17.5, sunset),
        (18.9, sunset),
        (20.4, night),
        (24.0, night)
    ]

    /// 특정 시각(소수 시간)의 분위기를 계산한다.
    static func mood(atHour hour: Double) -> RiverMood {
        let normalized = ((hour.truncatingRemainder(dividingBy: 24)) + 24)
            .truncatingRemainder(dividingBy: 24)

        for index in 0..<(keyframes.count - 1) {
            let lower = keyframes[index]
            let upper = keyframes[index + 1]
            if normalized >= lower.hour && normalized <= upper.hour {
                let span = max(upper.hour - lower.hour, 0.0001)
                let t = (normalized - lower.hour) / span
                var blended = lerp(lower.mood, upper.mood, t)
                blended.band = TimeBand(hour: normalized)
                return blended
            }
        }

        var fallback = night
        fallback.band = TimeBand(hour: normalized)
        return fallback
    }

    private static func lerp(_ a: RiverMood, _ b: RiverMood, _ t: Double) -> RiverMood {
        let f = CGFloat(t)
        var m = a
        m.skyTop = UIColor.blend(a.skyTop, b.skyTop, f)
        m.skyHorizon = UIColor.blend(a.skyHorizon, b.skyHorizon, f)
        m.sunDisc = UIColor.blend(a.sunDisc, b.sunDisc, f)
        m.sunColor = UIColor.blend(a.sunColor, b.sunColor, f)
        m.sunIntensity = a.sunIntensity + (b.sunIntensity - a.sunIntensity) * f
        m.sunAltitude = a.sunAltitude + (b.sunAltitude - a.sunAltitude) * t
        m.sunAzimuth = a.sunAzimuth + (b.sunAzimuth - a.sunAzimuth) * t
        m.sunOpacity = a.sunOpacity + (b.sunOpacity - a.sunOpacity) * f
        m.moonOpacity = a.moonOpacity + (b.moonOpacity - a.moonOpacity) * f
        m.moonAltitude = a.moonAltitude + (b.moonAltitude - a.moonAltitude) * t
        m.starOpacity = a.starOpacity + (b.starOpacity - a.starOpacity) * f
        m.ambientColor = UIColor.blend(a.ambientColor, b.ambientColor, f)
        m.ambientIntensity = a.ambientIntensity + (b.ambientIntensity - a.ambientIntensity) * f
        m.fogColor = UIColor.blend(a.fogColor, b.fogColor, f)
        m.fogStart = a.fogStart + (b.fogStart - a.fogStart) * f
        m.fogEnd = a.fogEnd + (b.fogEnd - a.fogEnd) * f
        m.waterColor = UIColor.blend(a.waterColor, b.waterColor, f)
        m.waterRoughness = a.waterRoughness + (b.waterRoughness - a.waterRoughness) * f
        m.waterMetalness = a.waterMetalness + (b.waterMetalness - a.waterMetalness) * f
        m.lanternIntensity = a.lanternIntensity + (b.lanternIntensity - a.lanternIntensity) * f
        m.fireIntensity = a.fireIntensity + (b.fireIntensity - a.fireIntensity) * f
        return m
    }
}

extension UIColor {
    /// 두 색을 sRGB 성분으로 선형 보간한다.
    static func blend(_ from: UIColor, _ to: UIColor, _ t: CGFloat) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        from.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        to.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let k = min(max(t, 0), 1)
        return UIColor(
            red: r1 + (r2 - r1) * k,
            green: g1 + (g2 - g1) * k,
            blue: b1 + (b2 - b1) * k,
            alpha: a1 + (a2 - a1) * k
        )
    }
}

// MARK: - 서비스

/// 시계를 15초마다 다시 읽어 시간대와 분위기를 발행한다.
/// `forcedBand`를 지정하면 테스트/미리보기용으로 그 시간대를 고정한다.
@MainActor
final class TimeOfDayService: ObservableObject {

    @Published private(set) var now: Date

    /// nil이면 실제 시각을 따른다.
    @Published var forcedBand: TimeBand?

    private var tickTask: Task<Void, Never>?
    private lazy var clockFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "a h:mm"
        return formatter
    }()

    nonisolated init(now: Date = Date()) {
        self.now = now
    }

    deinit {
        tickTask?.cancel()
    }

    // MARK: 생명주기

    func start() {
        guard tickTask == nil else { return }
        tickTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 15_000_000_000)
                guard let self, !Task.isCancelled else { return }
                self.refresh()
            }
        }
    }

    func stop() {
        tickTask?.cancel()
        tickTask = nil
    }

    func refresh() {
        now = Date()
    }

    // MARK: 계산 값

    var isPreviewing: Bool { forcedBand != nil }

    /// 0~24 사이의 소수 시각.
    var currentHour: Double {
        if let forcedBand {
            return forcedBand.previewHour
        }
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: now)
        let hour = Double(components.hour ?? 0)
        let minute = Double(components.minute ?? 0)
        let second = Double(components.second ?? 0)
        return hour + minute / 60 + second / 3600
    }

    var band: TimeBand {
        TimeBand(hour: currentHour)
    }

    var mood: RiverMood {
        RiverMood.mood(atHour: currentHour)
    }

    var clockText: String {
        if isPreviewing {
            return "미리보기"
        }
        return clockFormatter.string(from: now)
    }

    /// HUD 상단에 쓰는 "새벽 · 오전 6:12" 형태의 문구.
    var headerText: String {
        "\(band.displayName) · \(clockText)"
    }

    var previewBinding: TimeBand? {
        forcedBand
    }

    func togglePreview(_ band: TimeBand) {
        forcedBand = (forcedBand == band) ? nil : band
    }

    func clearPreview() {
        forcedBand = nil
    }
}
