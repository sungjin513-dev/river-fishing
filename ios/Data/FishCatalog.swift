//
//  FishCatalog.swift
//  RiverFishing
//
//  한국 민물고기와 조개·갑각류·연체동물 56종, 시간대별 출현 확률표.
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
            id: "gudgeon",
            name: "갈겨니",
            englishName: "Dark Chub",
            rarity: .common,
            minLengthCM: 8,
            maxLengthCM: 20,
            summary: "몸에 또렷한 세로줄이 있는 잔챙이. 여울에서 물이 부서지는 소리를 좋아한다."
        ),
        Fish(
            id: "dark-chub",
            name: "버들치",
            englishName: "Chinese Minnow",
            rarity: .common,
            minLengthCM: 6,
            maxLengthCM: 14,
            summary: "버들잎처럼 납작한 몸으로 차가운 물속을 잘도 빠져나간다."
        ),
        Fish(
            id: "korean-ayu",
            name: "은어",
            englishName: "Sweetfish",
            rarity: .common,
            minLengthCM: 12,
            maxLengthCM: 26,
            summary: "수박 향이 난다고 해서 붙은 이름. 여름 강에서 은빛으로 떼를 짓는다."
        ),
        Fish(
            id: "smelt",
            name: "빙어",
            englishName: "Smelt",
            rarity: .common,
            minLengthCM: 6,
            maxLengthCM: 13,
            summary: "겨울 강의 작은 손님. 얼음 아래에서도 물빛처럼 비치는 몸이다."
        ),
        Fish(
            id: "sand-gudgeon",
            name: "모래무지",
            englishName: "Sand Gudgeon",
            rarity: .common,
            minLengthCM: 7,
            maxLengthCM: 16,
            summary: "모래바닥에 몸을 붙이고 지내는 수줍은 물고기. 밤에 더 자주 움직인다."
        ),
        Fish(
            id: "oily-bitterling",
            name: "납자루",
            englishName: "Oily Bitterling",
            rarity: .common,
            minLengthCM: 5,
            maxLengthCM: 9,
            summary: "몸집이 작지만 무리 지어 헤엄치는 솜씨는 일품이다."
        ),
        Fish(
            id: "striped-bitterling",
            name: "줄납자루",
            englishName: "Striped Bitterling",
            rarity: .common,
            minLengthCM: 5,
            maxLengthCM: 10,
            summary: "등 쪽에 줄이 하나 그어진 조그만 물고기. 수초 사이를 좋아한다."
        ),
        Fish(
            id: "korean-shiner",
            name: "참마자",
            englishName: "Korean Shiner",
            rarity: .common,
            minLengthCM: 12,
            maxLengthCM: 28,
            summary: "길쭉한 주둥이로 돌 밑을 조심조심 뒤진다. 강가에서 흔히 만나는 얼굴."
        ),
        Fish(
            id: "hwang-eo",
            name: "황어",
            englishName: "Chub",
            rarity: .common,
            minLengthCM: 15,
            maxLengthCM: 30,
            summary: "노을 무렵 누렇게 물든 몸으로 얕은 물가를 배회한다."
        ),
        Fish(
            id: "tteokbungeo",
            name: "떡붕어",
            englishName: "Tteok Carp",
            rarity: .common,
            minLengthCM: 18,
            maxLengthCM: 40,
            summary: "붕어보다 둥글고 두툼한 몸. 노을 강에서 유독 잘 걸린다."
        ),
        Fish(
            id: "rosy-bitterling",
            name: "각시붕어",
            englishName: "Rosy Bitterling",
            rarity: .common,
            minLengthCM: 4,
            maxLengthCM: 7,
            summary: "작고 화려한 혼인색을 가진 물고기. 노을빛 아래서 유독 곱다."
        ),
        Fish(
            id: "daseulgi",
            name: "다슬기",
            englishName: "River Snail",
            rarity: .common,
            minLengthCM: 3,
            maxLengthCM: 8,
            summary: "돌에 붙어 느릿느릿 기어 다니는 나사 조개. 새벽 강바닥에서 흔히 만난다."
        ),
        Fish(
            id: "nonurongi",
            name: "논우렁이",
            englishName: "Pond Snail",
            rarity: .common,
            minLengthCM: 2,
            maxLengthCM: 5,
            summary: "물풀 사이를 굴러다니는 동그란 우렁. 낮에는 물 위로 올라와 숨을 쉰다."
        ),
        Fish(
            id: "jaecheop",
            name: "재첩",
            englishName: "Corbicula",
            rarity: .common,
            minLengthCM: 3,
            maxLengthCM: 6,
            summary: "모래를 걸러 먹고 사는 작은 조개. 해 질 무렵 바닥에 흔적을 남긴다."
        ),
        Fish(
            id: "minmul-saeu",
            name: "민물새우",
            englishName: "River Shrimp",
            rarity: .common,
            minLengthCM: 3,
            maxLengthCM: 7,
            summary: "돌 틈에서 더듬이만 내밀고 기다리는 청소부. 밤이 되면 활발해진다."
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
            id: "korean-perch",
            name: "꺽지",
            englishName: "Korean Perch",
            rarity: .uncommon,
            minLengthCM: 10,
            maxLengthCM: 22,
            summary: "돌 틈에 숨어 있다가 눈앞에서 사라진다. 얼룩무늬가 사냥감을 속인다."
        ),
        Fish(
            id: "dotted-gudgeon",
            name: "동자개",
            englishName: "Dotted Gudgeon",
            rarity: .uncommon,
            minLengthCM: 15,
            maxLengthCM: 30,
            summary: "밤이 되면 수염을 세우고 바닥을 기어 다닌다."
        ),
        Fish(
            id: "snakehead",
            name: "가물치",
            englishName: "Snakehead",
            rarity: .uncommon,
            minLengthCM: 30,
            maxLengthCM: 70,
            summary: "물속의 제왕. 조용하지만 한 번 물면 쉽게 놓지 않는다."
        ),
        Fish(
            id: "eel",
            name: "뱀장어",
            englishName: "Eel",
            rarity: .uncommon,
            minLengthCM: 40,
            maxLengthCM: 100,
            summary: "밤 강의 미끈한 손님. 잡고 나면 손에서 계속 빠져나간다."
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
            id: "nuchi",
            name: "누치",
            englishName: "Nuchi",
            rarity: .uncommon,
            minLengthCM: 20,
            maxLengthCM: 45,
            summary: "길고 뾰족한 주둥이로 바닥을 훑는다. 낮에는 좀처럼 모습을 보이지 않는다."
        ),
        Fish(
            id: "gang-junchi",
            name: "강준치",
            englishName: "Gang Junchi",
            rarity: .uncommon,
            minLengthCM: 25,
            maxLengthCM: 60,
            summary: "은빛 몸을 번뜩이며 물 위를 가른다. 힘이 세고 잽싸다."
        ),
        Fish(
            id: "kkeuri",
            name: "끄리",
            englishName: "Kkeuri",
            rarity: .uncommon,
            minLengthCM: 30,
            maxLengthCM: 70,
            summary: "수면 가까이를 조용히 순찰하는 은빛 사냥꾼."
        ),
        Fish(
            id: "brocade-carp",
            name: "비단잉어",
            englishName: "Brocade Carp",
            rarity: .uncommon,
            minLengthCM: 30,
            maxLengthCM: 70,
            summary: "비단처럼 번지는 무늬. 오래 걸어 두고 싶은 강의 귀빈이다."
        ),
        Fish(
            id: "miro",
            name: "밀어",
            englishName: "Miro",
            rarity: .uncommon,
            minLengthCM: 6,
            maxLengthCM: 12,
            summary: "작은 빨판으로 돌에 붙어 사는 물고기. 여울의 틈새가 집이다."
        ),
        Fish(
            id: "maljogae",
            name: "말조개",
            englishName: "Swan Mussel",
            rarity: .uncommon,
            minLengthCM: 12,
            maxLengthCM: 25,
            summary: "손바닥만 한 민물 조개. 물속에서 입을 살짝 벌리고 물을 거른다."
        ),
        Fish(
            id: "chamge",
            name: "참게",
            englishName: "Mitten Crab",
            rarity: .uncommon,
            minLengthCM: 6,
            maxLengthCM: 12,
            summary: "집게발에 털이 수북한 강의 미식가. 밤이면 옆으로 빠르게 달아난다."
        ),
        Fish(
            id: "gajae",
            name: "가재",
            englishName: "Crayfish",
            rarity: .uncommon,
            minLengthCM: 8,
            maxLengthCM: 15,
            summary: "돌 밑에 숨어 살다가 밤에 나와 바닥을 기어 다닌다. 집게발이 단단하다."
        ),
        Fish(
            id: "softshell",
            name: "자라",
            englishName: "Softshell Turtle",
            rarity: .uncommon,
            minLengthCM: 20,
            maxLengthCM: 40,
            summary: "물속을 유유히 떠다니는 늙은 등껍질. 바늘을 물고도 미동이 없다."
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
            id: "sunset-perch",
            name: "노을농어",
            englishName: "Sunset Perch",
            rarity: .rare,
            minLengthCM: 30,
            maxLengthCM: 52,
            summary: "해가 지는 쪽으로 몸을 돌리는 습성이 있다. 지느러미 끝이 붉다."
        ),
        Fish(
            id: "swiri",
            name: "쉬리",
            englishName: "Swiri",
            rarity: .rare,
            minLengthCM: 10,
            maxLengthCM: 20,
            summary: "몸 한가운데 붉은 줄이 지나간다. 맑고 찬 물에서만 산다."
        ),
        Fish(
            id: "eorunchi",
            name: "어름치",
            englishName: "Eorunchi",
            rarity: .rare,
            minLengthCM: 20,
            maxLengthCM: 40,
            summary: "천연기념물로 불리는 물고기. 지느러미 끝에 붉은 기운이 어린다."
        ),
        Fish(
            id: "lenok",
            name: "열목어",
            englishName: "Lenok",
            rarity: .rare,
            minLengthCM: 30,
            maxLengthCM: 60,
            summary: "눈이 붉어 열목이라 불린다. 아주 찬 상류에서만 산다."
        ),
        Fish(
            id: "masu-salmon",
            name: "산천어",
            englishName: "Masu Salmon",
            rarity: .rare,
            minLengthCM: 20,
            maxLengthCM: 45,
            summary: "산과 시내를 오가는 물고기. 새벽 물빛 속에서 등이 붉다."
        ),
        Fish(
            id: "cham-jonggae",
            name: "참종개",
            englishName: "Cham Jonggae",
            rarity: .rare,
            minLengthCM: 8,
            maxLengthCM: 14,
            summary: "돌 밑에서 지내는 작은 수염 물고기. 밤에 더 자주 다닌다."
        ),
        Fish(
            id: "kkuguri",
            name: "꾸구리",
            englishName: "Kkuguri",
            rarity: .rare,
            minLengthCM: 8,
            maxLengthCM: 15,
            summary: "모래바닥에 딱 붙어 숨는 물고기. 한낮에도 밤에도 조심스럽다."
        ),
        Fish(
            id: "dongsa-ri",
            name: "동사리",
            englishName: "Dongsa-ri",
            rarity: .rare,
            minLengthCM: 10,
            maxLengthCM: 18,
            summary: "바닥에 앉아 낙엽처럼 굴러다닌다. 노을 무렵 작은 입질을 보낸다."
        ),
        Fish(
            id: "kumgang-loach",
            name: "금강모치",
            englishName: "Kumgang Loach",
            rarity: .rare,
            minLengthCM: 8,
            maxLengthCM: 15,
            summary: "새벽 물안개 속에서 반짝이는 물고기. 이름은 금강에서 왔다."
        ),
        Fish(
            id: "susumikkuri",
            name: "수수미꾸리",
            englishName: "Susu Mikkuri",
            rarity: .rare,
            minLengthCM: 6,
            maxLengthCM: 11,
            summary: "밤에만 나타나는 가느다란 미꾸리. 촉수를 조심스럽게 뻗는다."
        ),
        Fish(
            id: "dol-sangeo",
            name: "돌상어",
            englishName: "Dol Sangeo",
            rarity: .rare,
            minLengthCM: 10,
            maxLengthCM: 18,
            summary: "돌 아래에 엎드리는 것이 유일한 재주. 밤에만 움직인다."
        ),
        Fish(
            id: "jinju-jogae",
            name: "진주조개",
            englishName: "Pearl Mussel",
            rarity: .rare,
            minLengthCM: 10,
            maxLengthCM: 20,
            summary: "속을 열면 작은 진주가 반짝인다는 조개. 새벽과 밤의 물빛을 닮았다."
        ),
        Fish(
            id: "agi-muneo",
            name: "아기문어",
            englishName: "Baby Octopus",
            rarity: .rare,
            minLengthCM: 8,
            maxLengthCM: 15,
            summary: "돌 틈에서 여덟 팔을 말고 있던 깜짝 손님. 만지면 물을 뿜고 도망간다."
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
        ),
        Fish(
            id: "dawn-sweetfish",
            name: "여명의은어",
            englishName: "Dawn Sweetfish",
            rarity: .legendary,
            minLengthCM: 30,
            maxLengthCM: 52,
            summary: "해가 뜨기 직전 물안개가 걷힐 때, 은어 떼에서 가장 은빛인 한 마리."
        ),
        Fish(
            id: "rainbow-chub",
            name: "무지개버들치",
            englishName: "Rainbow Chub",
            rarity: .legendary,
            minLengthCM: 25,
            maxLengthCM: 45,
            summary: "한낮의 물보라에 몸을 드러내면 등에 일곱 빛이 걸린다."
        ),
        Fish(
            id: "abyss-catfish",
            name: "심연의메기",
            englishName: "Abyss Catfish",
            rarity: .legendary,
            minLengthCM: 70,
            maxLengthCM: 140,
            summary: "강이 깊어지는 밤, 소용돌이 아래에서 서로에게만 들리는 수염 소리."
        ),
        Fish(
            id: "galaxy-eel",
            name: "은하수뱀장어",
            englishName: "Galaxy Eel",
            rarity: .legendary,
            minLengthCM: 80,
            maxLengthCM: 160,
            summary: "별이 물에 지는 밤, 강을 가로질러 은하가 흐른다는 목격담."
        ),
        Fish(
            id: "gang-muneo",
            name: "강문어",
            englishName: "River Octopus",
            rarity: .legendary,
            minLengthCM: 40,
            maxLengthCM: 90,
            summary: "깊은 물 아래에서 여덟 팔로 수면을 두드린다는 전설의 문어. 소문만 무성하다."
        ),
        Fish(
            id: "byeolbit-jjukkumi",
            name: "별빛쭈꾸미",
            englishName: "Starlight Bobtail",
            rarity: .legendary,
            minLengthCM: 25,
            maxLengthCM: 45,
            summary: "노을이 지고 별이 뜨는 사이에만 물 위로 떠오르는 쭈꾸미. 몸에 별가루가 붙어 있다."
        )
    ]

    // MARK: - 시간대별 확률표 (가중치 합 100)

    static let spawnTable: [TimeBand: [SpawnEntry]] = [
        .dawn: [
            SpawnEntry(fishID: "pale-chub", weight: 13),
            SpawnEntry(fishID: "gudgeon", weight: 9),
            SpawnEntry(fishID: "dark-chub", weight: 10),
            SpawnEntry(fishID: "korean-ayu", weight: 7),
            SpawnEntry(fishID: "smelt", weight: 6),
            SpawnEntry(fishID: "daseulgi", weight: 8),
            SpawnEntry(fishID: "korean-perch", weight: 3),
            SpawnEntry(fishID: "silver-ayu", weight: 11),
            SpawnEntry(fishID: "miro", weight: 6),
            SpawnEntry(fishID: "mandarin-fish", weight: 5),
            SpawnEntry(fishID: "swiri", weight: 5),
            SpawnEntry(fishID: "lenok", weight: 4),
            SpawnEntry(fishID: "kumgang-loach", weight: 3),
            SpawnEntry(fishID: "jinju-jogae", weight: 3),
            SpawnEntry(fishID: "starlight-trout", weight: 1),
            SpawnEntry(fishID: "dawn-sweetfish", weight: 4),
            SpawnEntry(fishID: "abyss-catfish", weight: 2)
        ],
        .day: [
            SpawnEntry(fishID: "pale-chub", weight: 8),
            SpawnEntry(fishID: "gudgeon", weight: 7),
            SpawnEntry(fishID: "dark-chub", weight: 7),
            SpawnEntry(fishID: "sand-gudgeon", weight: 8),
            SpawnEntry(fishID: "oily-bitterling", weight: 4),
            SpawnEntry(fishID: "striped-bitterling", weight: 2),
            SpawnEntry(fishID: "korean-shiner", weight: 7),
            SpawnEntry(fishID: "daseulgi", weight: 5),
            SpawnEntry(fishID: "nonurongi", weight: 4),
            SpawnEntry(fishID: "common-carp", weight: 7),
            SpawnEntry(fishID: "silver-ayu", weight: 4),
            SpawnEntry(fishID: "nuchi", weight: 3),
            SpawnEntry(fishID: "gang-junchi", weight: 5),
            SpawnEntry(fishID: "kkeuri", weight: 3),
            SpawnEntry(fishID: "miro", weight: 2),
            SpawnEntry(fishID: "maljogae", weight: 3),
            SpawnEntry(fishID: "eorunchi", weight: 4),
            SpawnEntry(fishID: "masu-salmon", weight: 3),
            SpawnEntry(fishID: "cham-jonggae", weight: 2),
            SpawnEntry(fishID: "kumgang-loach", weight: 2),
            SpawnEntry(fishID: "starlight-trout", weight: 3),
            SpawnEntry(fishID: "golden-carp", weight: 1),
            SpawnEntry(fishID: "dawn-sweetfish", weight: 2),
            SpawnEntry(fishID: "rainbow-chub", weight: 4)
        ],
        .sunset: [
            SpawnEntry(fishID: "pale-chub", weight: 8),
            SpawnEntry(fishID: "crucian-carp", weight: 11),
            SpawnEntry(fishID: "striped-bitterling", weight: 2),
            SpawnEntry(fishID: "korean-shiner", weight: 5),
            SpawnEntry(fishID: "hwang-eo", weight: 5),
            SpawnEntry(fishID: "tteokbungeo", weight: 8),
            SpawnEntry(fishID: "rosy-bitterling", weight: 4),
            SpawnEntry(fishID: "nonurongi", weight: 2),
            SpawnEntry(fishID: "jaecheop", weight: 4),
            SpawnEntry(fishID: "common-carp", weight: 9),
            SpawnEntry(fishID: "nuchi", weight: 3),
            SpawnEntry(fishID: "brocade-carp", weight: 6),
            SpawnEntry(fishID: "chamge", weight: 3),
            SpawnEntry(fishID: "softshell", weight: 4),
            SpawnEntry(fishID: "mandarin-fish", weight: 6),
            SpawnEntry(fishID: "sunset-perch", weight: 9),
            SpawnEntry(fishID: "cham-jonggae", weight: 2),
            SpawnEntry(fishID: "dongsa-ri", weight: 3),
            SpawnEntry(fishID: "golden-carp", weight: 4),
            SpawnEntry(fishID: "galaxy-eel", weight: 1),
            SpawnEntry(fishID: "byeolbit-jjukkumi", weight: 1)
        ],
        .night: [
            SpawnEntry(fishID: "pale-chub", weight: 4),
            SpawnEntry(fishID: "crucian-carp", weight: 8),
            SpawnEntry(fishID: "gudgeon", weight: 2),
            SpawnEntry(fishID: "sand-gudgeon", weight: 7),
            SpawnEntry(fishID: "jaecheop", weight: 1),
            SpawnEntry(fishID: "minmul-saeu", weight: 6),
            SpawnEntry(fishID: "catfish", weight: 12),
            SpawnEntry(fishID: "dotted-gudgeon", weight: 4),
            SpawnEntry(fishID: "snakehead", weight: 5),
            SpawnEntry(fishID: "eel", weight: 8),
            SpawnEntry(fishID: "chamge", weight: 3),
            SpawnEntry(fishID: "gajae", weight: 4),
            SpawnEntry(fishID: "night-eel", weight: 5),
            SpawnEntry(fishID: "cham-jonggae", weight: 4),
            SpawnEntry(fishID: "kkuguri", weight: 3),
            SpawnEntry(fishID: "dongsa-ri", weight: 2),
            SpawnEntry(fishID: "susumikkuri", weight: 4),
            SpawnEntry(fishID: "dol-sangeo", weight: 2),
            SpawnEntry(fishID: "jinju-jogae", weight: 2),
            SpawnEntry(fishID: "agi-muneo", weight: 4),
            SpawnEntry(fishID: "starlight-trout", weight: 2),
            SpawnEntry(fishID: "abyss-catfish", weight: 2),
            SpawnEntry(fishID: "galaxy-eel", weight: 2),
            SpawnEntry(fishID: "gang-muneo", weight: 2),
            SpawnEntry(fishID: "byeolbit-jjukkumi", weight: 2)
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
