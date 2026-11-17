# 🎣 River Fishing (아이폰 3D 낚시 앱)

강가에 앉은(서 있는) 3D 캐릭터 한 명이 **현실 시간에 맞춰 하루 종일 낚시하는** iPhone 앱입니다.
SwiftUI + SceneKit, **iOS 16.0+**, **외부 라이브러리 0개**(Apple 프레임워크만)로 동작합니다.
3D 모델 파일(.usdz) 없이 SceneKit 기본 도형만으로 강물·강둑·나무·캐릭터·낚싯대·찌를 조립해 두었기 때문에,
파일을 붙여넣고 실행하면 바로 화면에 강가 장면이 나옵니다.

---

## 1. 무엇을 하는 앱인가

| 요소 | 동작 |
| --- | --- |
| 환경 | iPhone의 **현재 시각**으로 새벽(05–08) / 낮(08–17) / 노을(17–20) / 밤(20–05)을 판별하고, 하늘 그라데이션·해와 달의 위치·조명 색온도·안개 농도·물빛과 반사·랜턴/모닥불 불빛·별의 밝기를 **보간해서** 바꿉니다. 경계 시각에서 툭 끊기지 않고 1~2시간에 걸쳐 서서히 변합니다. |
| 낚시 루프 | `idle → casting → waiting → biting → caught` 상태 머신. 캐릭터가 찌를 던지고(1.5초) 4.5~11초 기다리다가 입질(1.8초 창)이 오면 챔질. 자동 모드에서는 알아서 챔질하고, 화면을 탭하면 **완벽한 타이밍 보너스**(길이 +12%)를 받습니다. |
| 도감 | 시간대별 확률표에서 뽑힌 물고기를 `UserDefaults`에 JSON으로 저장. 수집률·어종별 마릿수·최대 길이를 시트에서 확인. |
| 방치 | 앱을 보고 있지 않아도 루프가 계속 돌아 도감이 채워집니다(자동 모드 기본값). |

### 시간대별 출현표 (가중치 합 100)

| 시간대 | 어종 (가중치) |
| --- | --- |
| 새벽 | 피라미 30 · 은빛은어 26 · 붕어 20 · 쏘가리 12 · 잉어 12 |
| 낮 | 피라미 32 · 붕어 28 · 잉어 18 · 은빛은어 14 · 쏘가리 6 · 별빛송어 2 |
| 노을 | 붕어 22 · 노을농어 22 · 잉어 20 · 쏘가리 16 · 피라미 12 · 황금잉어 8 |
| 밤 | 메기 30 · 밤장어 24 · 붕어 18 · 별빛송어 12 · 잉어 10 · 피라미 6 |

전설 어종은 **별빛송어**(밤)와 **황금잉어**(노을) 두 종입니다.

---

## 2. 폴더 / 파일 역할

```
river-fishing-ios/
├─ RiverFishingApp.swift        앱 진입점 (@main, WindowGroup → ContentView)
├─ Models/
│  └─ Fish.swift                TimeBand(시간대) · Rarity(희귀도) · Fish · FishCatchRecord · FishBook · CatchResult
├─ Data/
│  └─ FishCatalog.swift         어종 10종 정의 + 시간대별 확률표 + 가중치 뽑기 + 길이 분포
├─ Services/
│  ├─ TimeOfDayService.swift    현재 시각 → RiverMood(하늘/조명/안개/물/랜턴 파라미터) + 시간대 미리보기
│  └─ FishingEngine.swift       낚시 상태 머신, 탭 챔질, 도감 저장(FishBookStore)
├─ Scenes/
│  └─ RiverSceneView.swift      UIViewRepresentable + SCNView. 씬 조립/시간대 반영/캐스팅·입질·획득 애니메이션
└─ Views/
   ├─ ContentView.swift         3D 배경 + HUD(시간대 배지, 상태 카드, 챔질 버튼, 도감, 시간대 미리보기, 획득 토스트)
   └─ FishDexView.swift         도감 시트(수집률, 미발견 실루엣, 마릿수·최대 길이)
```

### 데이터 흐름

```
Date() ──TimeOfDayService──▶ RiverMood ──▶ RiverSceneView(SCNView) 하늘·조명·물·랜턴
                    │                              ▲
                    └─ TimeBand ──▶ FishingEngine ─┘ (phase, catchToken)
                                        │
                                   FishBook ──UserDefaults(JSON)
                                        │
                                     ContentView HUD / FishDexView
```

- `FishingEngine`은 `TimeBand`만 참조하므로, 시간대를 바꾸면 곧바로 다른 확률표에서 물고기가 나옵니다.
- 3D 씬은 `phase`와 `catchToken`이 바뀔 때만 애니메이션을 재생합니다(매 프레임 갱신은 `SCNSceneRendererDelegate`에서).

---

## 3. Xcode에서 실행하기

준비: **Xcode 15 이상**, 실기기(iPhone) 또는 시뮬레이터, iOS 16.0+.

1. Xcode → **File > New > Project… > iOS > App**
   - Product Name: `RiverFishing`
   - Interface: **SwiftUI**, Language: **Swift**
   - 저장 위치는 아무 곳이나 좋습니다. (테스트/UI 테스트는 꺼도 됩니다.)
2. 프로젝트 탐색기에서 템플릿이 만들어 준 `ContentView.swift`를 **삭제**하고, `RiverFishingApp.swift`는 아래 4번에서 교체합니다.
   - `Assets.xcassets`는 그대로 두어도 됩니다(이 앱은 이미지 에셋을 쓰지 않습니다).
3. 이 폴더의 파일을 프로젝트에 추가합니다.
   - Finder에서 `Models`, `Data`, `Services`, `Scenes`, `Views` 폴더를 프로젝트 탐색기의 `RiverFishing` 그룹에 **드래그 앤 드롭**
   - 대화상자에서 **Copy items if needed** 체크, **Create groups** 선택, 타깃 `RiverFishing` 체크
   - `RiverFishingApp.swift`도 같은 방식으로 추가(중복되면 기존 파일 삭제)
4. 타깃 설정 → **General**
   - Minimum Deployments: **iOS 16.0**
   - iPhone Orientation: **Portrait** 만 (가로 모드에서도 동작하지만 세로 구도에 맞춰져 있습니다)
5. **빌드(Cmd+B) → 실행(Cmd+R)**.

> ⚠️ 이 저장소의 코드는 Xcode가 없는 환경에서 작성되었습니다. 문법·구조를 정적으로 점검했지만, 실제 컴파일은 위 단계로 Xcode에서 한 번 확인해 주세요. 컴파일 오류가 나오면 Xcode의 빨간 표시 위치와 메시지를 그대로 알려주시면 바로 고쳐 드립니다.

### 조작

- 화면 아무 곳이나 **탭** = 챔질 (입질 중에 탭하면 보너스)
- 하단 **낚아채기** 버튼 = 같은 동작
- **자동 / 수동** 버튼 = 방치 모드 ↔ 직접 챔질 모드
- **도감** = 수집 현황 시트
- **시간대** 버튼 4개 = 새벽/낮/노을/밤 즉시 미리보기 (다시 누르면 실제 시간으로 복귀) — 배포 전에는 `ContentView.previewBar`를 지우면 됩니다.

---

## 4. 시간대 연출이 바뀌는 지점

`TimeOfDayService.swift`의 `RiverMood` 프리셋 4개(`dawn`, `day`, `sunset`, `night`)와
`keyframes` 배열이 전부입니다. 키프레임은 `(시각, 무드)` 쌍이고 사이 값은 선형 보간됩니다.

```swift
private static let keyframes: [(hour: Double, mood: RiverMood)] = [
    (0.0, night), (4.3, night), (5.8, dawn), (7.2, dawn), (8.8, day),
    (15.4, day), (17.5, sunset), (18.9, sunset), (20.4, night), (24.0, night)
]
```

조정하고 싶을 때:

| 원하는 것 | 건드릴 값 |
| --- | --- |
| 새벽 물안개 더 짙게 | `dawn.fogStart`↓ / `dawn.fogEnd`↓ |
| 노을을 더 붉게 | `sunset.skyHorizon`, `sunset.sunColor`, `sunset.sunIntensity` |
| 밤을 더 어둡게 | `night.ambientIntensity`↓, `night.sunIntensity`↓ (달빛) |
| 랜턴이 켜지는 시점 | `night.lanternIntensity`, `sunset.lanternIntensity` (120 이상이면 랜턴 메시가 밝아짐) |
| 하루 흐름 속도 | `TimeOfDayService.currentHour` (테스트 시 `return ...`로 시간을 압축) |

`RiverMood`의 필드는 모두 `CGFloat`/`Double`/`UIColor`라서 SceneKit에 그대로 넣을 수 있습니다.
해·달의 방향은 `positionCelestials()`가 `sunAltitude`/`sunAzimuth`(도)로 계산합니다.

---

## 5. `.usdz` 3D 모델로 교체하기

지금은 기본 도형 조립이지만, 같은 씬에 실제 모델을 얹을 수 있습니다.

### 5-1. 캐릭터 교체

1. 모델을 준비합니다. (Blender/Reality Composer Pro → **Reality Converter**로 `.usdz` 변환, 또는 Sketchfab/Apple 샘플)
2. `.usdz`를 프로젝트에 추가하고 타깃에 포함시킵니다.
3. `RiverSceneView.swift`의 `buildCharacter()`에서 만든 `characterRoot` 대신 모델을 넣습니다.

```swift
if let url = Bundle.main.url(forResource: "Fisherman", withExtension: "usdz"),
   let model = try? SCNScene(url: url, options: nil)?.rootNode.clone() {
    model.scale = SCNVector3(0.6, 0.6, 0.6)      // 모델 단위에 맞춰 조정
    model.eulerAngles = SCNVector3(0, .pi, 0)     // -z(강) 쪽을 바라보게
    characterRoot.addChildNode(model)

    // 애니메이션 클립이 있으면 이름으로 재생
    if let animationPlayer = model.animationPlayer(forKey: "Cast") { /* ... */ }
}
```

- `armPivot`/`rodPivot`/`rodTipNode`는 **낚싯줄 계산에 쓰이므로** 남겨 두세요.
  모델에 낚싯대가 포함되어 있다면 모델의 손 본 이름으로 `rodTipNode`를 옮겨 붙이면 됩니다.
- 캐스팅/입질/획득 연출은 `beginCast()`, `beginBite()`, `celebrateCatch()`에서 `SCNAction`으로 되어 있습니다.
  모델 애니메이션이 있으면 이 함수 안에서 `SCNAnimationPlayer`로 교체하는 편이 자연스럽습니다.

### 5-2. 배경(강둑·나무) 교체

- `buildGround()`, `buildScenery()`, `makeTree()`가 만든 노드를 지우고 원하는 `.usdz`를 배치합니다.
- 강물은 **PBR 재질 + 절차적 노멀맵**으로 흐르고 있습니다(`buildWater()`).
  실제 물 텍스처를 쓰려면 `material.normal.contents`를 이미지로 바꾸고 `waterNormalBase` 스케일만 맞추면 됩니다.
- 노드 이름을 정해 두면 나중에 코드에서 찾기 쉽습니다. 예: `scene.rootNode.childNode(withName: "River", recursively: true)`.

### 5-3. 성능 팁

- 모델 폴리곤이 많으면 `SCNView.preferredFramesPerSecond`를 30으로 낮추고, `antialiasingMode`를 `.multisampling2X`로.
- 그림자는 `sunLight.shadowMapSize`(기본 2048)와 `shadowSampleCount`(8)를 줄이면 빨라집니다.
- `view.rendersContinuously = true`는 애니메이션을 계속 돌리기 위한 설정입니다. 정지 화면이 많다면 `isPlaying`만 켜 두세요.

---

## 6. ASMR 물소리 넣기 (AVFoundation)

앱에 잔잔한 물소리를 깔아 두면 몰입감이 크게 올라갑니다. 외부 라이브러리 없이 `AVAudioPlayer` 루프로 충분합니다.

1. `water-loop.m4a`(30초~1분, 끊김 없이 이어지는 물소리)를 프로젝트에 추가.
2. `Services/AmbientSoundPlayer.swift` 새 파일:

```swift
import AVFoundation

@MainActor
final class AmbientSoundPlayer {
    static let shared = AmbientSoundPlayer()
    private var player: AVAudioPlayer?

    func start() {
        guard player == nil,
              let url = Bundle.main.url(forResource: "water-loop", withExtension: "m4a") else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            // 다른 앱 음악과 섞고, 무음 스위치를 존중
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)

            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1          // 무한 반복
            player.volume = 0.35
            player.prepareToPlay()
            player.play()
            self.player = player
        } catch {
            print("ambient sound failed: \(error)")
        }
    }

    func setVolume(_ value: Float) {
        player?.setVolume(value, fadeDuration: 0.4)
    }

    func stop() {
        player?.stop()
        player = nil
        try? AVAudioSession.sharedInstance().setActive(false)
    }
}
```

3. `ContentView`의 `.onAppear`에 `AmbientSoundPlayer.shared.start()` 추가.
4. 시간대에 따라 물소리를 다르게 하려면 `RiverMood`에 `ambientVolume`을 추가해 `.onChange(of: timeOfDay.band)`에서 `setVolume`을 호출하면 됩니다.
5. **앱이 백그라운드에서도 소리를 유지**하려면 Target > Signing & Capabilities > **Background Modes > Audio**를 켜고, `AVAudioSession` 카테고리를 `.playback`으로 바꿔야 합니다(App Store 심사 시 사유 필요).

낚시 효과음(찌 첨벙, 챔질)은 `AVAudioPlayer`를 짧게 재생하거나 `AVAudioEngine` + `AVAudioPlayerNode`로 겹쳐 재생하면 됩니다. 진동은 `UIImpactFeedbackGenerator`를 입질 순간에 호출하세요.

---

## 7. 잠금 화면 위젯 (WidgetKit)

"지금 시간대와 도감 수집률"을 잠금화면에 띄우면 방치형 앱의 재미가 살아납니다.

### 7-1. 위젯 타깃 추가

1. File > New > Target… > **Widget Extension** → 이름 `RiverFishingWidget`, **Include Live Activity**는 선택.
2. 잠금화면용은 `supportedFamilies`에 `.accessoryCircular`, `.accessoryRectangular`, `.accessoryInline`을 넣습니다(iOS 16+).

```swift
struct RiverStatusWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "RiverStatus", provider: RiverTimelineProvider()) { entry in
            RiverWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)   // iOS 17+
        }
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
        .configurationDisplayName("강가의 하루")
        .description("지금 시간대와 도감 수집률")
    }
}
```

### 7-2. 앱 ↔ 위젯 데이터 공유

`UserDefaults.standard`는 위젯과 공유되지 않습니다. **App Group**을 만들어야 합니다.

1. 앱 타깃과 위젯 타깃 모두 Signing & Capabilities > **App Groups** → `group.com.yourname.RiverFishing` 추가.
2. `FishBookStore`의 기본 저장소를 App Group으로 바꿉니다.

```swift
// FishingEngine.swift
static let appGroupDefaults = UserDefaults(suiteName: "group.com.yourname.RiverFishing") ?? .standard

// 예: 엔진 생성부
FishingEngine(store: FishBookStore(key: "riverFishing.fishBook.v1", defaults: .appGroupDefaults))
```

3. 한 마리 잡을 때마다 위젯을 갱신합니다.

```swift
import WidgetKit
// landFish() 안, store.save(book) 다음 줄
WidgetCenter.shared.reloadAllTimelines()
```

4. 위젯 타임라인은 30분 간격 + 시간대가 바뀌는 시각(05/08/17/20시)에 맞춰 `TimelineEntry`를 만들면 됩니다.

### 7-3. 시간대 계산 재사용

위젯 타깃에도 `Models/Fish.swift`와 `TimeOfDayService.swift`(또는 최소한 `TimeBand`만)를 추가하면 같은 로직으로 시간대를 표시할 수 있습니다. `TimeOfDayService`는 `@MainActor`이므로 위젯에서는 `TimeBand(hour:)`와 `RiverMood.mood(atHour:)`만 직접 호출하는 편이 가볍습니다.

### 7-4. 더 나아가기

- **Live Activity(ActivityKit)**: 낚시 중 "입질 대기 12초" 같은 실시간 진행을 잠금화면/Dynamic Island에 표시.
- **로컬 알림**: `UNUserNotificationCenter`로 "지금 노을이라 황금잉어가 나옵니다" 같은 시간대 알림.
- **Watch 앱**: 같은 `FishBook` JSON을 WatchConnectivity로 동기화.

---

## 8. 구조를 확장할 때 손대는 곳

| 하고 싶은 일 | 파일 / 함수 |
| --- | --- |
| 물고기 추가 | `FishCatalog.baseFish`에 `Fish(...)` 추가 → `spawnTable`에 `SpawnEntry` 추가 (ID 일치) |
| 확률 조정 | `FishCatalog.spawnTable` 가중치 |
| 입질 텀/지속시간 | `FishingEngine.fishOnce()`의 `waitTime`, `biteWindow` |
| 길이 분포 | `FishCatalog.length(for:randomUnit:)`의 `pow(unit, 1.45)` 지수 |
| 저장 키/초기화 | `FishBookStore(key:)`, `FishingEngine.resetBook()` |
| 씬 구도/카메라 | `buildCamera()`, `update(at:)`의 카메라 흔들림 |
| 캐릭터 색/체형 | `buildCharacter()`의 색 상수와 도형 크기 |
| 획득 연출 | `celebrateCatch()`, `showRipple(intense:)`, `showExclamation()` |

---

## 9. 문제 해결

| 증상 | 확인 |
| --- | --- |
| 화면이 검게만 나옴 | `RiverSceneView`가 아닌 다른 `ContentView`가 타깃에 들어갔는지, `scene`/`pointOfView`가 설정됐는지 |
| 3D가 너무 어둡거나 밝음 | `RiverMood.ambientIntensity`(180~540), `sunIntensity`(170~1300) 범위 확인. HDR `exposureOffset`(-0.3)도 영향 |
| 물이 거울처럼만 보임 | 시뮬레이터보다 실기기에서 확인. `waterMetalness`/`waterRoughness` 조정 |
| 입질이 안 옴 | `FishingEngine.start()`가 호출됐는지(`ContentView.onAppear`), 자동 모드 여부 |
| 프레임이 떨어짐 | 그림자 맵/샘플 수, `preferredFramesPerSecond`, 안티앨리어싱 단계 낮추기 |
| 시뮬레이터에서 느림 | SceneKit은 시뮬레이터에서 소프트웨어 렌더링인 경우가 있습니다. 실기기로 테스트하세요. |

> 참고: 최신 SDK에서 **SceneKit은 deprecated로 표시**됩니다(기존 프로젝트는 계속 동작). 장기적으로는 RealityKit으로 옮기는 편이 좋고, 이 앱은 씬 구성이 한 파일(`RiverSceneView.swift`)에 모여 있어 이전 비용이 크지 않습니다.

---

## 10. 요구 사항 요약

- iOS 16.0+, Xcode 15+
- 프레임워크: SwiftUI, SceneKit, UIKit, Foundation, simd — **전부 Apple 기본 제공**
- 권한 요청 없음(위치·카메라·알림 미사용)
- 데이터: `UserDefaults`의 JSON 한 덩어리(`riverFishing.fishBook.v1`)
- 인터넷 연결 불필요
