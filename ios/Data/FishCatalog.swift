//
//  FishCatalog.swift
//  RiverFishing
//
//  한국 민물고기 + 감성 희귀 어종 10종과 시간대별 출현 확률표.
//

import Foundation

enum FishCatalog {

    /// 시간대별 확률표의 한 줄. weight는 상대 가중치(합이 100이 되도록 맞춰 두었다).
    struct SpawnEntry {
        let fishID: String
        let weight: Double
    }

    // MARK: - 어종 정의

    private static let baseFish: [Fish] = [
        Fish(
            id: "pale-chub",
            name: "피라미",
            englishName: "Pale Chub",
            rarity: .common,
            minLengthCM: 7,
            maxLengthCM: 15,
            summary: "수면 가까이에서 빠르게 움직이는 작은 물고기. 낮에는 물빛에 몸이 반짝인다."
        ),
        Fish(
            id: "crucian-carp",
            name: "붕어",
            englishName: "Crucian Carp",
            rarity: .common,
            minLengthCM: 12,
            maxLengthCM: 32,
            summary: "어느 시간대에나 만날 수 있는 강의 오랜 친구. 느긋하게 찌를 흔든다."
        ),
        Fish(
            id: "common-carp",
            name: "잉어",
            englishName: "Common Carp",
            rarity: .uncommon,
            minLengthCM: 35,
            maxLengthCM: 85,
            summary: "등지느러미를 수면 위로 내밀며 유유히 헤엄친다. 한 번 걸리면 팔이 아프다."
        ),
        Fish(
            id: "catfish",
            name: "메기",
            englishName: "Catfish",
            rarity: .uncommon,
            minLengthCM: 28,
            maxLengthCM: 65,
            summary: "긴 수염으로 어둠 속을 더듬는다. 해가 진 뒤에만 입질이 온다."
        ),
        Fish(
            id: "mandarin-fish",
            name: "쏘가리",
            englishName: "Mandarin Fish",
            rarity: .rare,
            minLengthCM: 18,
            maxLengthCM: 38,
            summary: "새벽과 노을의 경계에서만 모습을 드러내는 강의 사냥꾼."
        ),
        Fish(
            id: "night-eel",
            name: "밤장어",
            englishName: "Night Eel",
            rarity: .rare,
            minLengthCM: 45,
            maxLengthCM: 95,
            summary: "밤물 속을 미끄러지는 긴 그림자. 잡고 나면 손이 한참 미끌미끌하다."
        ),
        Fish(
            id: "silver-ayu",
            name: "은빛은어",
            englishName: "Silver Sweetfish",
            rarity: .uncommon,
            minLengthCM: 12,
            maxLengthCM: 26,
            summary: "새벽 햇살을 등에 받으면 은가루를 뿌린 것처럼 반짝인다."
        ),
        Fish(
            id: "sunset-perch",
            name: "노을농어",
            englishName: "Sunset Perch",
            rarity: .rare,
            minLengthCM: 30,
            maxLengthCM: 52,
            summary: "해가 지는 쪽으로 몸을 돌리는 습성이 있다. 지느러미 끝이 붉다."
        ),
        Fish(
            id: "starlight-trout",
            name: "별빛송어",
            englishName: "Starlight Trout",
            rarity: .legendary,
            minLengthCM: 32,
            maxLengthCM: 58,
            summary: "별이 물에 비치는 밤에만 오른다. 비늘에 별자리가 새겨져 있다고 전해진다."
        ),
        Fish(
            id: "golden-carp",
            name: "황금잉어",
            englishName: "Golden Carp",
            rarity: .legendary,
            minLengthCM: 55,
            maxLengthCM: 105,
            summary: "노을이 강을 금빛으로 물들이는 몇 분 동안에만 낚이는 전설의 잉어."
        )
    ]

    // MARK: - 시간대별 확률표 (가중치 합 100)

    static let spawnTable: [TimeBand: [SpawnEntry]] = [
        .dawn: [
            SpawnEntry(fishID: "pale-chub", weight: 30),
            SpawnEntry(fishID: "silver-ayu", weight: 26),
            SpawnEntry(fishID: "crucian-carp", weight: 20),
            SpawnEntry(fishID: "mandarin-fish", weight: 12),
            SpawnEntry(fishID: "common-carp", weight: 12)
        ],
        .day: [
            SpawnEntry(fishID: "pale-chub", weight: 32),
            SpawnEntry(fishID: "crucian-carp", weight: 28),
            SpawnEntry(fishID: "common-carp", weight: 18),
            SpawnEntry(fishID: "silver-ayu", weight: 14),
            SpawnEntry(fishID: "mandarin-fish", weight: 6),
            SpawnEntry(fishID: "starlight-trout", weight: 2)
        ],
        .sunset: [
            SpawnEntry(fishID: "crucian-carp", weight: 22),
            SpawnEntry(fishID: "sunset-perch", weight: 22),
            SpawnEntry(fishID: "common-carp", weight: 20),
            SpawnEntry(fishID: "mandarin-fish", weight: 16),
            SpawnEntry(fishID: "pale-chub", weight: 12),
            SpawnEntry(fishID: "golden-carp", weight: 8)
        ],
        .night: [
            SpawnEntry(fishID: "catfish", weight: 30),
            SpawnEntry(fishID: "night-eel", weight: 24),
            SpawnEntry(fishID: "crucian-carp", weight: 18),
            SpawnEntry(fishID: "starlight-trout", weight: 12),
            SpawnEntry(fishID: "common-carp", weight: 10),
            SpawnEntry(fishID: "pale-chub", weight: 6)
        ]
    ]

    // MARK: - 조회

    /// 확률표에 등장하는 시간대를 각 어종의 `activeBands`로 채워 넣은 최종 목록.
    static let all: [Fish] = baseFish.map { fish in
        var copy = fish
        copy.activeBands = TimeBand.allCases.filter { band in
            (spawnTable[band] ?? []).contains { $0.fishID == fish.id }
        }
        return copy
    }

    static let byID: [String: Fish] = Dictionary(
        uniqueKeysWithValues: all.map { ($0.id, $0) }
    )

    static var speciesCount: Int { all.count }

    static func fish(id: String) -> Fish? {
        byID[id]
    }

    static func bands(for fish: Fish) -> [TimeBand] {
        fish.activeBands
    }

    // MARK: - 뽑기

    /// 해당 시간대의 확률표에서 물고기 한 마리를 뽑는다.
    static func roll(band: TimeBand) -> Fish {
        let entries = spawnTable[band] ?? spawnTable[.day] ?? []
        let total = entries.reduce(0.0) { $0 + $1.weight }
        guard total > 0 else {
            return all.first ?? baseFish[0]
        }
        var pick = Double.random(in: 0..<total)
        for entry in entries {
            pick -= entry.weight
            if pick <= 0, let fish = byID[entry.fishID] {
                return fish
            }
        }
        if let last = entries.last, let fish = byID[last.fishID] {
            return fish
        }
        return all.first ?? baseFish[0]
    }

    /// 길이(cm)를 뽑는다. 작은 쪽이 더 자주 나오도록 완만한 곡선을 준다.
    static func length(for fish: Fish, randomUnit: Double = Double.random(in: 0..<1)) -> Double {
        let unit = min(max(randomUnit, 0), 0.9999)
        let curved = pow(unit, 1.45)
        let raw = fish.minLengthCM + (fish.maxLengthCM - fish.minLengthCM) * curved
        return (raw * 10).rounded() / 10
    }

    /// 희귀도별 어종 수 (도감 요약에 사용).
    static func speciesCount(rarity: Rarity) -> Int {
        all.filter { $0.rarity == rarity }.count
    }
}
