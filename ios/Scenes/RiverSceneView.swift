//
//  RiverSceneView.swift
//  RiverFishing
//
//  SceneKit으로 조립한 강가 씬. 외부 3D 에셋 없이 기본 도형만으로
//  강물·강둑·나무·낚시하는 캐릭터·찌·낚싯줄을 만들고,
//  시간대(RiverMood)에 따라 하늘/조명/물빛/랜턴이 바뀐다.
//

import SwiftUI
import SceneKit
import UIKit
import simd

// MARK: - SwiftUI 래퍼

struct RiverSceneView: UIViewRepresentable {

    let mood: RiverMood
    let phase: FishingPhase
    let catchToken: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(mood: mood)
    }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = context.coordinator.controller.scene
        view.pointOfView = context.coordinator.controller.cameraNode
        view.delegate = context.coordinator
        view.isPlaying = true
        view.rendersContinuously = true
        view.preferredFramesPerSecond = 60
        view.antialiasingMode = .multisampling4X
        view.backgroundColor = .black
        view.autoenablesDefaultLighting = false
        view.allowsCameraControl = false
        view.isUserInteractionEnabled = false   // 제스처는 SwiftUI HUD가 받는다
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        context.coordinator.sync(mood: mood, phase: phase, catchToken: catchToken)
    }

    static func dismantleUIView(_ uiView: SCNView, coordinator: Coordinator) {
        uiView.isPlaying = false
        uiView.delegate = nil
        uiView.scene = nil
    }

    // MARK: Coordinator

    final class Coordinator: NSObject, SCNSceneRendererDelegate {
        let controller: RiverSceneController

        private var lastMood: RiverMood?
        private var lastPhase: FishingPhase?
        private var lastCatchToken: Int = -1

        init(mood: RiverMood) {
            controller = RiverSceneController(mood: mood)
            super.init()
        }

        func sync(mood: RiverMood, phase: FishingPhase, catchToken: Int) {
            if lastMood != mood {
                lastMood = mood
                controller.apply(mood: mood)
            }
            if lastPhase != phase || lastCatchToken != catchToken {
                lastPhase = phase
                lastCatchToken = catchToken
                controller.apply(phase: phase, catchToken: catchToken)
            }
        }

        func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
            controller.update(at: time)
        }
    }
}

// MARK: - 씬 구성/애니메이션

final class RiverSceneController {

    let scene = SCNScene()
    let cameraNode = SCNNode()

    private(set) var mood: RiverMood
    private var phase: FishingPhase = .idle
    private var built = false
    private var lastCatchToken = -1

    // 조명 / 하늘
    private let ambientNode = SCNNode()
    private let sunLightNode = SCNNode()
    private let sunNode = SCNNode()
    private let moonNode = SCNNode()
    private let lanternLightNode = SCNNode()
    private let fireLightNode = SCNNode()
    private var sunMaterial: SCNMaterial?
    private var moonMaterial: SCNMaterial?

    // 물
    private var waterMaterial: SCNMaterial?
    private var waterNormalBase = SCNMatrix4Identity
    private var fireParticles: SCNParticleSystem?

    // 캐릭터
    private let characterRoot = SCNNode()
    private let torsoNode = SCNNode()
    private let headNode = SCNNode()
    private let armPivot = SCNNode()
    private let rodPivot = SCNNode()
    private let rodMeshNode = SCNNode()
    private let rodTipNode = SCNNode()

    // 채비 / 소품
    private let bobberRoot = SCNNode()
    private let lineNode = SCNNode()
    private let rippleNode = SCNNode()
    private let fishNode = SCNNode()
    private let exclaimNode = SCNNode()
    private let lanternBodyNode = SCNNode()
    private let campfireNode = SCNNode()

    private let bobberRestPosition = SCNVector3(0.5, 0.03, -3.2)
    private let exclaimScale: CGFloat = 0.34
    private var bobberDrift = true
    private var lanternBaseIntensity: CGFloat = 0
    private var fireBaseIntensity: CGFloat = 0

    // MARK: 초기화

    init(mood: RiverMood) {
        self.mood = mood
        build()
        built = true
    }

    private func build() {
        scene.background.contents = UIColor.black
        scene.rootNode.addChildNode(cameraNode)
        buildCamera()
        buildSky()
        buildCelestials()
        buildLights()
        buildGround()
        buildWater()
        buildScenery()
        buildCharacter()
        buildProps()
        buildTackle()
        apply(mood: mood)
    }

    // MARK: 카메라

    private func buildCamera() {
        let camera = SCNCamera()
        camera.fieldOfView = 58
        camera.zNear = 0.05
        camera.zFar = 300
        camera.wantsHDR = true
        camera.wantsExposureAdaptation = false
        camera.exposureOffset = -0.3
        camera.bloomIntensity = 0.45
        camera.bloomThreshold = 0.82
        camera.bloomBlurRadius = 14
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0.9, 2.55, 8.2)
        cameraNode.look(
            at: SCNVector3(0.15, 0.65, -2.2),
            up: SCNVector3(0, 1, 0),
            localFront: SCNVector3(0, 0, -1)
        )
    }

    // MARK: 하늘 / 별

    private func buildSky() {
        scene.background.contents = skyImage(
            top: mood.skyTop,
            bottom: mood.skyHorizon,
            starOpacity: mood.starOpacity
        )
        scene.lightingEnvironment.contents = gradientImage(top: mood.skyTop, bottom: mood.skyHorizon)
        scene.lightingEnvironment.intensity = 0.6
        scene.fogColor = mood.fogColor
        scene.fogStartDistance = mood.fogStart
        scene.fogEndDistance = mood.fogEnd
        scene.fogDensityExponent = 1.6
    }

    // MARK: 해 / 달

    private func buildCelestials() {
        let sunGeometry = SCNSphere(radius: 2.2)
        sunGeometry.segmentCount = 24
        let sunMaterial = SCNMaterial()
        sunMaterial.lightingModel = .constant
        sunMaterial.diffuse.contents = mood.sunDisc
        sunMaterial.emission.contents = mood.sunDisc
        sunMaterial.emission.intensity = 2.4
        sunMaterial.writesToDepthBuffer = false
        sunGeometry.firstMaterial = sunMaterial
        self.sunMaterial = sunMaterial
        sunNode.geometry = sunGeometry
        sunNode.addChildNode(glowNode(radius: 7.0, color: mood.sunDisc, opacity: 0.20))
        sunNode.opacity = mood.sunOpacity
        scene.rootNode.addChildNode(sunNode)

        let moonGeometry = SCNSphere(radius: 1.6)
        moonGeometry.segmentCount = 22
        let moonMaterial = SCNMaterial()
        moonMaterial.lightingModel = .constant
        moonMaterial.diffuse.contents = UIColor(red: 0.88, green: 0.92, blue: 1.0, alpha: 1)
        moonMaterial.emission.contents = UIColor(red: 0.80, green: 0.86, blue: 1.0, alpha: 1)
        moonMaterial.emission.intensity = 1.8
        moonMaterial.writesToDepthBuffer = false
        moonGeometry.firstMaterial = moonMaterial
        self.moonMaterial = moonMaterial
        moonNode.geometry = moonGeometry
        moonNode.addChildNode(glowNode(radius: 4.4, color: UIColor(red: 0.70, green: 0.80, blue: 1.0, alpha: 1), opacity: 0.26))
        moonNode.opacity = mood.moonOpacity
        scene.rootNode.addChildNode(moonNode)
    }

    private func glowNode(radius: CGFloat, color: UIColor, opacity: CGFloat) -> SCNNode {
        let geometry = SCNSphere(radius: radius)
        geometry.segmentCount = 18
        let material = SCNMaterial()
        material.lightingModel = .constant
        material.diffuse.contents = color
        material.emission.contents = color
        material.emission.intensity = 0.7
        material.transparency = opacity
        material.blendMode = .add
        material.writesToDepthBuffer = false
        material.isDoubleSided = true
        geometry.firstMaterial = material
        return SCNNode(geometry: geometry)
    }

    // MARK: 조명

    private func buildLights() {
        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.color = mood.ambientColor
        ambient.intensity = mood.ambientIntensity
        ambientNode.light = ambient
        scene.rootNode.addChildNode(ambientNode)

        let sun = SCNLight()
        sun.type = .directional
        sun.color = mood.sunColor
        sun.intensity = mood.sunIntensity
        sun.castsShadow = true
        sun.shadowMode = .deferred
        sun.shadowSampleCount = 8
        sun.shadowRadius = 4
        sun.shadowColor = UIColor(white: 0, alpha: 0.5)
        sun.orthographicScale = 12
        sun.zNear = 1
        sun.zFar = 120
        sunLightNode.light = sun
        scene.rootNode.addChildNode(sunLightNode)
    }

    // MARK: 강둑 / 물

    private func buildGround() {
        let bankGeometry = SCNBox(width: 70, height: 1.4, length: 24, chamferRadius: 0.7)
        let bankMaterial = SCNMaterial()
        bankMaterial.lightingModel = .physicallyBased
        bankMaterial.diffuse.contents = gravelImage()
        bankMaterial.diffuse.wrapS = .repeat
        bankMaterial.diffuse.wrapT = .repeat
        bankMaterial.diffuse.contentsTransform = SCNMatrix4MakeScale(12, 6, 1)
        bankMaterial.roughness.contents = 0.92
        bankMaterial.metalness.contents = 0.0
        bankGeometry.firstMaterial = bankMaterial
        let bankNode = SCNNode(geometry: bankGeometry)
        bankNode.position = SCNVector3(0, -0.64, 12.0)
        scene.rootNode.addChildNode(bankNode)
    }

    private func buildWater() {
        let geometry = SCNPlane(width: 96, height: 90)
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = mood.waterColor
        material.normal.contents = rippleNormalImage()
        material.normal.wrapS = .repeat
        material.normal.wrapT = .repeat
        material.normal.mipFilter = .linear
        material.normal.intensity = 0.85
        waterNormalBase = SCNMatrix4MakeScale(9, 9, 1)
        material.normal.contentsTransform = waterNormalBase
        material.roughness.contents = mood.waterRoughness
        material.metalness.contents = mood.waterMetalness
        material.fresnelExponent = 1.8
        material.isDoubleSided = false
        geometry.firstMaterial = material
        waterMaterial = material

        let waterNode = SCNNode(geometry: geometry)
        waterNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
        waterNode.position = SCNVector3(0, 0, -36)
        scene.rootNode.addChildNode(waterNode)
    }

    // MARK: 바위 / 나무 / 갈대

    private func buildScenery() {
        // 물가 바위 — 캐릭터 앞을 비켜 좌우로
        let rockSpots: [(Float, Float, CGFloat)] = [
            (-1.5, -0.5, 0.34), (-2.3, 0.3, 0.26), (1.7, -0.7, 0.38), (2.4, 0.2, 0.28),
            (-3.1, -0.9, 0.46), (3.2, -1.1, 0.32), (-0.85, -1.3, 0.20), (1.15, -1.4, 0.22)
        ]
        for (x, z, radius) in rockSpots {
            addRock(position: SCNVector3(x, 0.06, z), radius: radius)
        }

        // 강 건너편 둑
        let farBankGeometry = SCNBox(width: 96, height: 2.0, length: 24, chamferRadius: 1.0)
        let farBankMaterial = SCNMaterial()
        farBankMaterial.lightingModel = .physicallyBased
        farBankMaterial.diffuse.contents = UIColor(red: 0.19, green: 0.24, blue: 0.21, alpha: 1)
        farBankMaterial.roughness.contents = 0.95
        farBankMaterial.metalness.contents = 0.0
        farBankGeometry.firstMaterial = farBankMaterial
        let farBankNode = SCNNode(geometry: farBankGeometry)
        farBankNode.position = SCNVector3(0, -0.6, -46)
        scene.rootNode.addChildNode(farBankNode)

        // 건너편 숲 (앞줄 / 뒷줄)
        for index in 0..<15 {
            let x = Float(index) * 3.2 - 22.0
            let tree = makeTree(scale: CGFloat.random(in: 0.9...1.4))
            tree.position = SCNVector3(x, 0.4, -38.0 - Float(index % 3) * 2.2)
            scene.rootNode.addChildNode(tree)
        }
        for index in 0..<11 {
            let x = Float(index) * 4.0 - 20.0
            let tree = makeTree(scale: CGFloat.random(in: 0.55...0.85))
            tree.position = SCNVector3(x, 0.4, -48.0 - Float(index % 2) * 2.0)
            scene.rootNode.addChildNode(tree)
        }

        // 물가 갈대 — 화면 가운데를 비켜서
        for _ in 0..<26 {
            let side: Float = Bool.random() ? 1 : -1
            let x = side * Float.random(in: 1.6...5.5)
            addReed(
                position: SCNVector3(x, 0.06, Float.random(in: -1.1...0.4)),
                height: CGFloat.random(in: 0.55...1.15)
            )
        }

        // 발치 풀포기
        for _ in 0..<18 {
            let side: Float = Bool.random() ? 1 : -1
            let x = side * Float.random(in: 0.9...4.0)
            addGrassTuft(position: SCNVector3(x, 0.06, Float.random(in: 0.2...3.0)))
        }
    }

    private func addGrassTuft(position: SCNVector3) {
        let material = matte(UIColor(red: 0.30, green: 0.42, blue: 0.26, alpha: 1), roughness: 0.95)
        for index in 0..<4 {
            let geometry = SCNCone(
                topRadius: 0,
                bottomRadius: 0.05,
                height: CGFloat.random(in: 0.22...0.38)
            )
            geometry.radialSegmentCount = 4
            geometry.firstMaterial = material
            let blade = SCNNode(geometry: geometry)
            let angle = Float(index) * Float.pi / 2
            blade.position = SCNVector3(
                position.x + cos(angle) * 0.06,
                position.y + 0.12,
                position.z + sin(angle) * 0.06
            )
            blade.eulerAngles = SCNVector3(
                Float.random(in: -0.2...0.2),
                angle,
                Float.random(in: -0.25...0.25)
            )
            scene.rootNode.addChildNode(blade)
        }
    }

    private func addRock(position: SCNVector3, radius: CGFloat) {
        let geometry = SCNSphere(radius: radius)
        geometry.segmentCount = 7
        let shade = CGFloat.random(in: 0.30...0.44)
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = UIColor(white: shade, alpha: 1)
        material.roughness.contents = 0.88
        material.metalness.contents = 0.02
        geometry.firstMaterial = material
        let node = SCNNode(geometry: geometry)
        node.position = position
        node.scale = SCNVector3(1.0, CGFloat.random(in: 0.55...0.8), CGFloat.random(in: 0.8...1.15))
        node.eulerAngles = SCNVector3(Float.random(in: 0...0.6), Float.random(in: 0...Float.pi), Float.random(in: 0...0.4))
        scene.rootNode.addChildNode(node)
    }

    private func makeTree(scale: CGFloat) -> SCNNode {
        let root = SCNNode()

        let trunkGeometry = SCNCylinder(radius: 0.10 * scale, height: 1.4 * scale)
        trunkGeometry.radialSegmentCount = 7
        trunkGeometry.firstMaterial = matte(UIColor(red: 0.26, green: 0.20, blue: 0.15, alpha: 1))
        let trunk = SCNNode(geometry: trunkGeometry)
        trunk.position = SCNVector3(0, 0.7 * scale, 0)
        root.addChildNode(trunk)

        let leafColors: [UIColor] = [
            UIColor(red: 0.20, green: 0.32, blue: 0.22, alpha: 1),
            UIColor(red: 0.24, green: 0.38, blue: 0.25, alpha: 1),
            UIColor(red: 0.17, green: 0.28, blue: 0.20, alpha: 1)
        ]
        for index in 0..<3 {
            let radius = (0.62 - CGFloat(index) * 0.14) * scale
            let foliageGeometry = SCNCone(topRadius: 0, bottomRadius: radius, height: 0.95 * scale)
            foliageGeometry.radialSegmentCount = 8
            foliageGeometry.firstMaterial = matte(leafColors[index % leafColors.count])
            let foliage = SCNNode(geometry: foliageGeometry)
            foliage.position = SCNVector3(0, (1.3 + CGFloat(index) * 0.42) * scale, 0)
            root.addChildNode(foliage)
        }
        return root
    }

    private func addReed(position: SCNVector3, height: CGFloat) {
        let geometry = SCNCylinder(radius: 0.012, height: height)
        geometry.radialSegmentCount = 5
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = UIColor(red: 0.40, green: 0.44, blue: 0.26, alpha: 1)
        material.roughness.contents = 0.9
        geometry.firstMaterial = material
        let node = SCNNode(geometry: geometry)
        node.position = SCNVector3(position.x, position.y + Float(height) / 2, position.z)
        node.eulerAngles = SCNVector3(Float.random(in: -0.18...0.18), 0, Float.random(in: -0.22...0.22))
        scene.rootNode.addChildNode(node)
    }

    // MARK: 캐릭터

    private func buildCharacter() {
        characterRoot.position = SCNVector3(0.05, 0.06, 1.2)
        scene.rootNode.addChildNode(characterRoot)

        let skin = UIColor(red: 0.94, green: 0.79, blue: 0.67, alpha: 1)
        let jacket = UIColor(red: 0.25, green: 0.35, blue: 0.44, alpha: 1)
        let jacketDark = UIColor(red: 0.18, green: 0.26, blue: 0.34, alpha: 1)
        let pants = UIColor(red: 0.21, green: 0.23, blue: 0.28, alpha: 1)
        let boots = UIColor(red: 0.15, green: 0.14, blue: 0.13, alpha: 1)
        let hatColor = UIColor(red: 0.36, green: 0.30, blue: 0.21, alpha: 1)

        // 다리 / 장화
        for side in [Float(-1), Float(1)] {
            let legGeometry = SCNCapsule(capRadius: 0.075, height: 0.62)
            legGeometry.firstMaterial = matte(pants)
            let leg = SCNNode(geometry: legGeometry)
            leg.position = SCNVector3(0.11 * side, 0.36, 0)
            characterRoot.addChildNode(leg)

            let bootGeometry = SCNBox(width: 0.15, height: 0.12, length: 0.26, chamferRadius: 0.04)
            bootGeometry.firstMaterial = matte(boots, roughness: 0.6)
            let boot = SCNNode(geometry: bootGeometry)
            boot.position = SCNVector3(0.11 * side, 0.07, -0.05)
            characterRoot.addChildNode(boot)
        }

        // 골반
        let hipGeometry = SCNBox(width: 0.34, height: 0.18, length: 0.22, chamferRadius: 0.05)
        hipGeometry.firstMaterial = matte(pants)
        let hip = SCNNode(geometry: hipGeometry)
        hip.position = SCNVector3(0, 0.70, 0)
        characterRoot.addChildNode(hip)

        // 몸통
        let torsoGeometry = SCNCapsule(capRadius: 0.19, height: 0.78)
        torsoGeometry.firstMaterial = matte(jacket)
        torsoNode.geometry = torsoGeometry
        torsoNode.position = SCNVector3(0, 1.10, 0)
        torsoNode.scale = SCNVector3(1.18, 1.0, 0.86)
        characterRoot.addChildNode(torsoNode)

        // 목 / 머리
        let neckGeometry = SCNCylinder(radius: 0.06, height: 0.10)
        neckGeometry.firstMaterial = matte(skin)
        let neck = SCNNode(geometry: neckGeometry)
        neck.position = SCNVector3(0, 1.46, 0)
        characterRoot.addChildNode(neck)

        let headGeometry = SCNSphere(radius: 0.155)
        headGeometry.segmentCount = 22
        headGeometry.firstMaterial = matte(skin)
        headNode.geometry = headGeometry
        headNode.position = SCNVector3(0, 1.58, -0.01)
        characterRoot.addChildNode(headNode)

        // 모자
        let brimGeometry = SCNCylinder(radius: 0.26, height: 0.02)
        brimGeometry.radialSegmentCount = 20
        brimGeometry.firstMaterial = matte(hatColor, roughness: 0.75)
        let brim = SCNNode(geometry: brimGeometry)
        brim.position = SCNVector3(0, 1.68, -0.02)
        brim.eulerAngles = SCNVector3(0.06, 0, 0)
        characterRoot.addChildNode(brim)

        let crownGeometry = SCNCone(topRadius: 0.075, bottomRadius: 0.16, height: 0.16)
        crownGeometry.radialSegmentCount = 20
        crownGeometry.firstMaterial = matte(hatColor, roughness: 0.75)
        let crown = SCNNode(geometry: crownGeometry)
        crown.position = SCNVector3(0, 1.77, -0.01)
        characterRoot.addChildNode(crown)

        // 오른팔 — 어깨 피벗을 돌려 캐스팅한다
        armPivot.position = SCNVector3(0.24, 1.36, 0)
        armPivot.eulerAngles = SCNVector3(0.35, 0, 0)
        characterRoot.addChildNode(armPivot)

        let upperArmGeometry = SCNCapsule(capRadius: 0.062, height: 0.30)
        upperArmGeometry.firstMaterial = matte(jacketDark)
        let upperArm = SCNNode(geometry: upperArmGeometry)
        upperArm.position = SCNVector3(0, -0.16, 0)
        armPivot.addChildNode(upperArm)

        let elbow = SCNNode()
        elbow.position = SCNVector3(0, -0.32, 0)
        armPivot.addChildNode(elbow)

        let forearmGeometry = SCNCapsule(capRadius: 0.055, height: 0.30)
        forearmGeometry.firstMaterial = matte(jacketDark)
        let forearm = SCNNode(geometry: forearmGeometry)
        forearm.position = SCNVector3(0, -0.06, -0.14)
        forearm.eulerAngles = SCNVector3(-1.15, 0, 0)
        elbow.addChildNode(forearm)

        let hand = SCNNode()
        hand.position = SCNVector3(0, 0, -0.28)
        elbow.addChildNode(hand)

        let handGeometry = SCNSphere(radius: 0.058)
        handGeometry.firstMaterial = matte(skin)
        let handMesh = SCNNode(geometry: handGeometry)
        hand.addChildNode(handMesh)

        // 낚싯대 (손에 쥔 채 앞쪽 위로 뻗는다)
        rodPivot.position = SCNVector3(0, 0.02, -0.02)
        rodPivot.eulerAngles = SCNVector3(-1.57, 0, 0)
        hand.addChildNode(rodPivot)

        let rodGeometry = SCNCone(topRadius: 0.006, bottomRadius: 0.020, height: 1.85)
        rodGeometry.radialSegmentCount = 10
        rodGeometry.firstMaterial = matte(UIColor(red: 0.16, green: 0.12, blue: 0.10, alpha: 1), roughness: 0.5)
        rodMeshNode.geometry = rodGeometry
        rodMeshNode.position = SCNVector3(0, 0.72, 0)
        rodPivot.addChildNode(rodMeshNode)

        rodTipNode.position = SCNVector3(0, 0.93, 0)
        rodMeshNode.addChildNode(rodTipNode)

        // 왼팔
        let leftShoulder = SCNNode()
        leftShoulder.position = SCNVector3(-0.25, 1.34, 0)
        characterRoot.addChildNode(leftShoulder)

        let leftArmGeometry = SCNCapsule(capRadius: 0.058, height: 0.54)
        leftArmGeometry.firstMaterial = matte(jacketDark)
        let leftArm = SCNNode(geometry: leftArmGeometry)
        leftArm.position = SCNVector3(0, -0.24, 0.02)
        leftArm.eulerAngles = SCNVector3(-0.22, 0, 0.14)
        leftShoulder.addChildNode(leftArm)

        // 발치 양동이
        let bucketGeometry = SCNCylinder(radius: 0.13, height: 0.24)
        bucketGeometry.radialSegmentCount = 16
        bucketGeometry.firstMaterial = matte(UIColor(red: 0.55, green: 0.57, blue: 0.58, alpha: 1), roughness: 0.4, metalness: 0.3)
        let bucket = SCNNode(geometry: bucketGeometry)
        bucket.position = SCNVector3(0.52, 0.12, 0.26)
        characterRoot.addChildNode(bucket)
    }

    // MARK: 랜턴 / 모닥불

    private func buildProps() {
        // 랜턴 걸이
        let woodMaterial = matte(UIColor(red: 0.24, green: 0.19, blue: 0.15, alpha: 1), roughness: 0.8)

        let poleGeometry = SCNCylinder(radius: 0.025, height: 1.35)
        poleGeometry.firstMaterial = woodMaterial
        let pole = SCNNode(geometry: poleGeometry)
        pole.position = SCNVector3(-1.05, 0.72, 1.9)
        scene.rootNode.addChildNode(pole)

        let armGeometry = SCNCylinder(radius: 0.018, height: 0.5)
        armGeometry.firstMaterial = woodMaterial
        let arm = SCNNode(geometry: armGeometry)
        arm.position = SCNVector3(-0.82, 1.36, 1.9)
        arm.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
        scene.rootNode.addChildNode(arm)

        let lanternGeometry = SCNSphere(radius: 0.13)
        lanternGeometry.segmentCount = 16
        let lanternMaterial = SCNMaterial()
        lanternMaterial.lightingModel = .constant
        lanternMaterial.diffuse.contents = UIColor(red: 1.0, green: 0.76, blue: 0.44, alpha: 1)
        lanternMaterial.emission.contents = UIColor(red: 1.0, green: 0.72, blue: 0.40, alpha: 1)
        lanternMaterial.emission.intensity = 1.6
        lanternGeometry.firstMaterial = lanternMaterial
        lanternBodyNode.geometry = lanternGeometry
        lanternBodyNode.position = SCNVector3(-0.6, 1.16, 1.9)
        lanternBodyNode.addChildNode(glowNode(radius: 0.5, color: UIColor(red: 1.0, green: 0.72, blue: 0.42, alpha: 1), opacity: 0.18))
        scene.rootNode.addChildNode(lanternBodyNode)

        let lanternLight = SCNLight()
        lanternLight.type = .omni
        lanternLight.color = UIColor(red: 1.0, green: 0.76, blue: 0.48, alpha: 1)
        lanternLight.intensity = mood.lanternIntensity
        lanternLight.attenuationStartDistance = 0.4
        lanternLight.attenuationEndDistance = 10
        lanternLight.castsShadow = false
        lanternLightNode.light = lanternLight
        lanternLightNode.position = SCNVector3(-0.6, 1.16, 1.9)
        scene.rootNode.addChildNode(lanternLightNode)

        // 모닥불
        let fireCenter = SCNVector3(1.5, 0.06, 1.9)
        for index in 0..<3 {
            let logGeometry = SCNCylinder(radius: 0.045, height: 0.5)
            logGeometry.radialSegmentCount = 8
            logGeometry.firstMaterial = matte(UIColor(red: 0.25, green: 0.17, blue: 0.12, alpha: 1))
            let log = SCNNode(geometry: logGeometry)
            log.position = SCNVector3(fireCenter.x, fireCenter.y + 0.07, fireCenter.z)
            log.eulerAngles = SCNVector3(Float.pi / 2, Float(index) * Float.pi / 3, 0)
            scene.rootNode.addChildNode(log)
        }

        let fire = SCNParticleSystem()
        fire.birthRate = 55
        fire.particleLifeSpan = 0.55
        fire.particleLifeSpanVariation = 0.25
        fire.particleSize = 0.07
        fire.particleSizeVariation = 0.05
        fire.particleImage = glowImage(color: UIColor(red: 1.0, green: 0.66, blue: 0.30, alpha: 1))
        fire.particleColor = UIColor(red: 1.0, green: 0.72, blue: 0.34, alpha: 1)
        fire.particleColorVariation = SCNVector4(0.08, 0.18, 0.10, 0)
        fire.particleVelocity = 0.5
        fire.particleVelocityVariation = 0.25
        fire.particleAngle = 0
        fire.particleAngleVariation = 180
        fire.acceleration = SCNVector3(0, 1.1, 0)
        fire.isAffectedByGravity = false
        fire.blendMode = .additive
        fire.emitterShape = SCNSphere(radius: 0.08)
        fire.birthLocation = .volume
        fire.isLocal = false

        fireParticles = fire
        campfireNode.position = SCNVector3(fireCenter.x, fireCenter.y + 0.18, fireCenter.z)
        campfireNode.addParticleSystem(fire)
        scene.rootNode.addChildNode(campfireNode)

        let fireLight = SCNLight()
        fireLight.type = .omni
        fireLight.color = UIColor(red: 1.0, green: 0.60, blue: 0.26, alpha: 1)
        fireLight.intensity = mood.fireIntensity
        fireLight.attenuationStartDistance = 0.3
        fireLight.attenuationEndDistance = 8
        fireLight.castsShadow = false
        fireLightNode.light = fireLight
        fireLightNode.position = SCNVector3(fireCenter.x, fireCenter.y + 0.5, fireCenter.z)
        scene.rootNode.addChildNode(fireLightNode)
    }

    // MARK: 채비 (찌 / 줄 / 물고기 / 느낌표)

    private func buildTackle() {
        let lineGeometry = SCNCylinder(radius: 0.009, height: 1)
        lineGeometry.radialSegmentCount = 6
        let lineMaterial = SCNMaterial()
        lineMaterial.lightingModel = .constant
        lineMaterial.diffuse.contents = UIColor(white: 0.94, alpha: 1)
        lineMaterial.transparency = 0.8
        lineMaterial.writesToDepthBuffer = false
        lineGeometry.firstMaterial = lineMaterial
        lineNode.geometry = lineGeometry
        scene.rootNode.addChildNode(lineNode)

        bobberRoot.position = bobberRestPosition
        scene.rootNode.addChildNode(bobberRoot)

        let lowerGeometry = SCNCylinder(radius: 0.06, height: 0.12)
        lowerGeometry.radialSegmentCount = 14
        lowerGeometry.firstMaterial = matte(UIColor(white: 0.96, alpha: 1), roughness: 0.4)
        let lower = SCNNode(geometry: lowerGeometry)
        lower.position = SCNVector3(0, -0.03, 0)
        bobberRoot.addChildNode(lower)

        let upperGeometry = SCNCylinder(radius: 0.06, height: 0.12)
        upperGeometry.radialSegmentCount = 14
        let upperMaterial = matte(UIColor(red: 0.86, green: 0.16, blue: 0.13, alpha: 1), roughness: 0.4)
        upperMaterial.emission.contents = UIColor(red: 0.55, green: 0.06, blue: 0.04, alpha: 1)
        upperMaterial.emission.intensity = 0.6
        upperGeometry.firstMaterial = upperMaterial
        let upper = SCNNode(geometry: upperGeometry)
        upper.position = SCNVector3(0, 0.09, 0)
        bobberRoot.addChildNode(upper)

        let antennaGeometry = SCNCylinder(radius: 0.010, height: 0.20)
        antennaGeometry.radialSegmentCount = 8
        let antennaMaterial = SCNMaterial()
        antennaMaterial.lightingModel = .constant
        antennaMaterial.diffuse.contents = UIColor(red: 1.0, green: 0.86, blue: 0.36, alpha: 1)
        antennaMaterial.emission.contents = UIColor(red: 1.0, green: 0.80, blue: 0.30, alpha: 1)
        antennaMaterial.emission.intensity = 1.5
        antennaGeometry.firstMaterial = antennaMaterial
        let antenna = SCNNode(geometry: antennaGeometry)
        antenna.position = SCNVector3(0, 0.25, 0)
        bobberRoot.addChildNode(antenna)

        // 물결 링
        let rippleGeometry = SCNTorus(ringRadius: 0.16, pipeRadius: 0.007)
        rippleGeometry.ringSegmentCount = 32
        rippleGeometry.pipeSegmentCount = 6
        let rippleMaterial = SCNMaterial()
        rippleMaterial.lightingModel = .constant
        rippleMaterial.diffuse.contents = UIColor(white: 1.0, alpha: 1)
        rippleMaterial.emission.contents = UIColor(white: 0.9, alpha: 1)
        rippleMaterial.emission.intensity = 0.5
        rippleMaterial.transparency = 0.65
        rippleMaterial.writesToDepthBuffer = false
        rippleGeometry.firstMaterial = rippleMaterial
        rippleNode.geometry = rippleGeometry
        rippleNode.position = SCNVector3(bobberRestPosition.x, 0.012, bobberRestPosition.z)
        rippleNode.isHidden = true
        scene.rootNode.addChildNode(rippleNode)

        buildFishNode()
        buildExclaimNode()
    }

    private func buildFishNode() {
        let bodyGeometry = SCNSphere(radius: 0.14)
        bodyGeometry.segmentCount = 14
        let bodyMaterial = matte(UIColor(red: 0.78, green: 0.84, blue: 0.88, alpha: 1), roughness: 0.3, metalness: 0.5)
        bodyMaterial.emission.contents = UIColor(red: 0.26, green: 0.33, blue: 0.42, alpha: 1)
        bodyMaterial.emission.intensity = 0.35
        bodyGeometry.firstMaterial = bodyMaterial
        let body = SCNNode(geometry: bodyGeometry)
        body.scale = SCNVector3(0.55, 0.85, 2.2)
        fishNode.addChildNode(body)

        let tailGeometry = SCNCone(topRadius: 0.075, bottomRadius: 0.004, height: 0.18)
        tailGeometry.radialSegmentCount = 6
        tailGeometry.firstMaterial = bodyMaterial
        let tail = SCNNode(geometry: tailGeometry)
        tail.position = SCNVector3(0, 0, 0.33)
        tail.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)
        tail.scale = SCNVector3(1, 1, 0.35)
        fishNode.addChildNode(tail)

        fishNode.isHidden = true
        scene.rootNode.addChildNode(fishNode)
    }

    private func buildExclaimNode() {
        let text = SCNText(string: "!", extrusionDepth: 0.02)
        text.font = UIFont.systemFont(ofSize: 1.4, weight: .heavy)
        text.flatness = 0.2
        let material = SCNMaterial()
        material.lightingModel = .constant
        material.diffuse.contents = UIColor(red: 1.0, green: 0.86, blue: 0.30, alpha: 1)
        material.emission.contents = UIColor(red: 1.0, green: 0.78, blue: 0.20, alpha: 1)
        material.emission.intensity = 1.4
        material.isDoubleSided = true
        text.firstMaterial = material
        exclaimNode.geometry = text
        exclaimNode.position = SCNVector3(bobberRestPosition.x, 0.78, bobberRestPosition.z)
        exclaimNode.scale = SCNVector3(0.001, 0.001, 0.001)
        exclaimNode.isHidden = true

        let billboard = SCNBillboardConstraint()
        billboard.freeAxes = .Y
        exclaimNode.constraints = [billboard]

        scene.rootNode.addChildNode(exclaimNode)
    }

    // MARK: - 분위기 적용

    func apply(mood newMood: RiverMood) {
        mood = newMood
        let sky = skyImage(
            top: newMood.skyTop,
            bottom: newMood.skyHorizon,
            starOpacity: newMood.starOpacity
        )

        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.8

        scene.background.contents = sky
        scene.lightingEnvironment.contents = gradientImage(top: newMood.skyTop, bottom: newMood.skyHorizon)
        scene.lightingEnvironment.intensity = 0.6
        scene.fogColor = newMood.fogColor
        scene.fogStartDistance = newMood.fogStart
        scene.fogEndDistance = newMood.fogEnd
        scene.fogDensityExponent = 1.6

        ambientNode.light?.color = newMood.ambientColor
        ambientNode.light?.intensity = newMood.ambientIntensity
        sunLightNode.light?.color = newMood.sunColor
        sunLightNode.light?.intensity = newMood.sunIntensity

        sunMaterial?.diffuse.contents = newMood.sunDisc
        sunMaterial?.emission.contents = newMood.sunDisc
        sunNode.opacity = newMood.sunOpacity
        moonNode.opacity = newMood.moonOpacity

        waterMaterial?.diffuse.contents = newMood.waterColor
        waterMaterial?.roughness.contents = newMood.waterRoughness
        waterMaterial?.metalness.contents = newMood.waterMetalness

        lanternBaseIntensity = newMood.lanternIntensity
        lanternLightNode.light?.intensity = newMood.lanternIntensity
        lanternBodyNode.opacity = newMood.lanternIntensity > 120 ? 1.0 : 0.25

        fireBaseIntensity = newMood.fireIntensity
        fireLightNode.light?.intensity = newMood.fireIntensity
        campfireNode.opacity = newMood.fireIntensity > 80 ? 1.0 : 0.0
        fireParticles?.birthRate = newMood.fireIntensity > 80 ? 55 : 0

        positionCelestials()

        SCNTransaction.commit()
    }

    private func positionCelestials() {
        let sunDirection = direction(altitude: mood.sunAltitude, azimuth: mood.sunAzimuth)
        // 달은 해와 반대편에 두되, 좁은 화면 안에 들어오도록 각도를 제한한다.
        let moonAzimuth = min(max(mood.sunAzimuth * 0.25 + 6, -12), 12)
        let moonDirection = direction(altitude: mood.moonAltitude, azimuth: moonAzimuth)
        let distance: Float = 44

        sunNode.position = SCNVector3(
            sunDirection.x * distance,
            sunDirection.y * distance,
            sunDirection.z * distance
        )
        moonNode.position = SCNVector3(
            moonDirection.x * distance,
            moonDirection.y * distance,
            moonDirection.z * distance
        )

        // 해가 지평선 아래면 달빛이 주 광원이 된다.
        let keyDirection = mood.sunAltitude > -3 ? sunDirection : moonDirection
        sunLightNode.position = SCNVector3(keyDirection.x * 30, keyDirection.y * 30, keyDirection.z * 30)
        sunLightNode.look(
            at: SCNVector3Zero,
            up: SCNVector3(0, 1, 0),
            localFront: SCNVector3(0, 0, -1)
        )
    }

    private func direction(altitude: Double, azimuth: Double) -> SIMD3<Float> {
        let altitudeRad = Float(altitude) * .pi / 180
        let azimuthRad = Float(azimuth) * .pi / 180
        let x = cos(altitudeRad) * sin(azimuthRad)
        let y = sin(altitudeRad)
        let z = -cos(altitudeRad) * cos(azimuthRad)
        return SIMD3<Float>(x, y, z)
    }

    // MARK: - 상태 적용 (캐스팅/입질/획득)

    func apply(phase newPhase: FishingPhase, catchToken: Int) {
        guard phase != newPhase || catchToken != lastCatchToken else { return }
        phase = newPhase
        lastCatchToken = catchToken

        switch newPhase {
        case .casting:
            beginCast()
        case .waiting, .missed, .idle:
            resetBobber()
        case .biting:
            beginBite()
        case .caught:
            celebrateCatch()
        }
    }

    private func beginCast() {
        bobberDrift = false
        hideExclamation()
        bobberRoot.removeAllActions()

        let start = SCNVector3(bobberRestPosition.x, bobberRestPosition.y + 1.5, bobberRestPosition.z + 2.4)
        let end = bobberRestPosition
        bobberRoot.position = start
        bobberRoot.opacity = 1
        bobberRoot.isHidden = true

        let flight = SCNAction.customAction(duration: 0.85) { node, elapsed in
            let t = Float(elapsed / 0.85)
            let x = start.x + (end.x - start.x) * t
            let z = start.z + (end.z - start.z) * t
            let y = start.y + (end.y - start.y) * t + sin(Float.pi * t) * 1.3
            node.position = SCNVector3(x, y, z)
        }
        let land = SCNAction.run { node in
            node.isHidden = false
            node.position = end
        }
        bobberRoot.runAction(.sequence([flight, land]), forKey: "cast")

        armPivot.removeAllActions()
        let windUp = SCNAction.rotateTo(x: 0.02, y: 0, z: 0, duration: 0.35, usesShortestUnitArc: true)
        let whip = SCNAction.rotateTo(x: 1.15, y: 0, z: 0, duration: 0.3, usesShortestUnitArc: true)
        let settle = SCNAction.rotateTo(x: 0.42, y: 0, z: 0, duration: 0.45, usesShortestUnitArc: true)
        armPivot.runAction(.sequence([windUp, whip, settle]))
    }

    private func resetBobber() {
        bobberRoot.removeAllActions()
        bobberRoot.isHidden = false
        bobberRoot.opacity = 1
        bobberRoot.eulerAngles = SCNVector3Zero
        bobberRoot.position = bobberRestPosition
        bobberDrift = true
        hideExclamation()
        armPivot.removeAllActions()
        armPivot.eulerAngles = SCNVector3(0.35, 0, 0)
    }

    private func beginBite() {
        bobberDrift = false
        bobberRoot.removeAllActions()
        bobberRoot.position = bobberRestPosition

        let dip = SCNAction.sequence([
            SCNAction.moveBy(x: 0, y: -0.13, z: 0, duration: 0.12),
            SCNAction.moveBy(x: 0, y: 0.09, z: 0, duration: 0.12),
            SCNAction.moveBy(x: 0, y: -0.11, z: 0, duration: 0.10),
            SCNAction.moveBy(x: 0, y: 0.15, z: 0, duration: 0.14)
        ])
        bobberRoot.runAction(dip, forKey: "bite")

        showRipple(intense: true)
        showExclamation()

        armPivot.removeAllActions()
        armPivot.runAction(.rotateTo(x: 0.72, y: 0, z: 0, duration: 0.2, usesShortestUnitArc: true))
    }

    private func celebrateCatch() {
        bobberDrift = false
        hideExclamation()
        bobberRoot.removeAllActions()
        bobberRoot.position = bobberRestPosition
        showRipple(intense: false)

        let base = bobberRestPosition
        fishNode.removeAllActions()
        fishNode.isHidden = false
        fishNode.opacity = 1
        fishNode.scale = SCNVector3(1, 1, 1)
        fishNode.eulerAngles = SCNVector3Zero
        fishNode.position = SCNVector3(base.x, 0.02, base.z)

        let jump = SCNAction.customAction(duration: 1.05) { node, elapsed in
            let t = Float(elapsed / 1.05)
            let x = base.x + sin(Float.pi * t) * 0.55
            let y = 0.02 + sin(Float.pi * t) * 1.7
            let z = base.z + t * 2.3
            node.position = SCNVector3(x, y, z)
            node.eulerAngles = SCNVector3(0, 0, -t * 7)
        }
        let finish = SCNAction.sequence([
            SCNAction.fadeOut(duration: 0.2),
            SCNAction.run { node in
                node.isHidden = true
                node.opacity = 1
            }
        ])
        fishNode.runAction(.sequence([jump, finish]))

        armPivot.removeAllActions()
        let pull = SCNAction.rotateTo(x: 1.30, y: 0, z: 0, duration: 0.18, usesShortestUnitArc: true)
        let back = SCNAction.rotateTo(x: 0.42, y: 0, z: 0, duration: 0.5, usesShortestUnitArc: true)
        armPivot.runAction(.sequence([pull, back]))
    }

    private func showRipple(intense: Bool) {
        rippleNode.removeAllActions()
        rippleNode.isHidden = false
        rippleNode.opacity = intense ? 0.95 : 0.6
        rippleNode.scale = SCNVector3(1, 1, 1)

        let grow = SCNAction.scale(to: intense ? 6.5 : 4.0, duration: intense ? 0.75 : 0.9)
        let fade = SCNAction.fadeOut(duration: intense ? 0.55 : 0.75)
        let done = SCNAction.run { node in
            node.isHidden = true
            node.opacity = 1
            node.scale = SCNVector3(1, 1, 1)
        }
        rippleNode.runAction(.sequence([SCNAction.group([grow, fade]), done]))
    }

    private func showExclamation() {
        exclaimNode.removeAllActions()
        exclaimNode.isHidden = false
        exclaimNode.scale = SCNVector3(0.001, 0.001, 0.001)
        let pop = SCNAction.scale(to: exclaimScale, duration: 0.16)
        let hold = SCNAction.wait(duration: 0.85)
        let shrink = SCNAction.scale(to: 0.001, duration: 0.14)
        let hide = SCNAction.run { node in node.isHidden = true }
        exclaimNode.runAction(.sequence([pop, hold, shrink, hide]))
    }

    private func hideExclamation() {
        exclaimNode.removeAllActions()
        exclaimNode.isHidden = true
        exclaimNode.scale = SCNVector3(0.001, 0.001, 0.001)
    }

    // MARK: - 매 프레임 갱신

    func update(at time: TimeInterval) {
        guard built else { return }
        let t = Float(time)

        if let waterMaterial {
            let offsetX = Float(time.truncatingRemainder(dividingBy: 600)) * 0.010
            let offsetY = Float(time.truncatingRemainder(dividingBy: 600)) * 0.0045
            waterMaterial.normal.contentsTransform = SCNMatrix4Mult(
                SCNMatrix4MakeTranslation(offsetX, offsetY, 0),
                waterNormalBase
            )
        }

        if bobberDrift {
            let bob = sin(t * 1.7) * 0.012 + sin(t * 3.3) * 0.004
            bobberRoot.position = SCNVector3(
                bobberRestPosition.x + sin(t * 0.7) * 0.02,
                bobberRestPosition.y + bob,
                bobberRestPosition.z
            )
            bobberRoot.eulerAngles = SCNVector3(sin(t * 1.1) * 0.05, 0, sin(t * 0.9) * 0.06)
        }

        updateLine()

        torsoNode.scale = SCNVector3(1.18, 1.0 + 0.012 * sin(t * 1.5), 0.86)
        headNode.eulerAngles = SCNVector3(0.03 * sin(t * 0.8), 0.06 * sin(t * 0.35), 0)
        rodMeshNode.eulerAngles = SCNVector3(0, 0.03 * sin(t * 0.9), 0.02 * sin(t * 0.6))

        if let light = lanternLightNode.light {
            let flicker = 0.92 + 0.06 * sin(t * 6.5) + 0.03 * sin(t * 11.0)
            light.intensity = lanternBaseIntensity * CGFloat(flicker)
        }
        if let light = fireLightNode.light {
            let flicker = 0.85 + 0.12 * sin(t * 9.0) + 0.06 * sin(t * 15.0)
            light.intensity = fireBaseIntensity * CGFloat(flicker)
        }

        // 아주 느린 카메라 흔들림 (살아 있는 느낌)
        let sway = Float(sin(time * 0.12))
        cameraNode.position = SCNVector3(0.9 + sway * 0.07, 2.55 + sway * 0.025, 8.2)
        cameraNode.look(
            at: SCNVector3(0.15, 0.65, -2.2),
            up: SCNVector3(0, 1, 0),
            localFront: SCNVector3(0, 0, -1)
        )
    }

    private func updateLine() {
        let tip = rodTipNode.worldPosition
        let float = bobberRoot.position

        let from = SIMD3<Float>(tip.x, tip.y, tip.z)
        let to = SIMD3<Float>(float.x, float.y + 0.19, float.z)
        let delta = to - from
        let length = simd_length(delta)
        guard length > 0.001 else { return }

        let middle = (from + to) * 0.5
        lineNode.position = SCNVector3(middle.x, middle.y, middle.z)
        lineNode.scale = SCNVector3(1, length, 1)
        lineNode.simdOrientation = simd_quatf(from: SIMD3<Float>(0, 1, 0), to: delta / length)
    }

    // MARK: - 재질

    private func matte(_ color: UIColor, roughness: CGFloat = 0.85, metalness: CGFloat = 0.0) -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = color
        material.roughness.contents = roughness
        material.metalness.contents = metalness
        return material
    }

    // MARK: - 절차적 텍스처

    private func gradientImage(top: UIColor, bottom: UIColor) -> UIImage {
        let size = CGSize(width: 64, height: 512)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let cgContext = context.cgContext
            let colors = [top.cgColor, bottom.cgColor] as CFArray
            guard let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors,
                locations: [0, 1]
            ) else { return }
            cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: 0, y: size.height),
                options: []
            )
        }
    }

    /// 배경 하늘. 별은 밤의 `starOpacity`에 따라 늘 같은 자리에 다시 그린다(깜박임 방지용 고정 시드).
    private func skyImage(top: UIColor, bottom: UIColor, starOpacity: CGFloat) -> UIImage {
        let size = CGSize(width: 256, height: 512)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let cgContext = context.cgContext
            let colors = [top.cgColor, bottom.cgColor] as CFArray
            if let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors,
                locations: [0, 1]
            ) {
                cgContext.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: 0, y: 0),
                    end: CGPoint(x: 0, y: size.height),
                    options: []
                )
            }

            guard starOpacity > 0.02 else { return }

            var seed: UInt64 = 0x9E37_79B9_7F4A_7C15
            func nextUnit() -> CGFloat {
                seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
                return CGFloat((seed >> 33) % 10_000) / 10_000
            }

            for _ in 0..<240 {
                let x = nextUnit() * size.width
                let y = nextUnit() * size.height * 0.7
                let radius = 0.6 + nextUnit() * 1.2
                let alpha = (0.3 + nextUnit() * 0.7) * starOpacity
                cgContext.setFillColor(UIColor(white: 1.0, alpha: alpha).cgColor)
                cgContext.fillEllipse(in: CGRect(x: x, y: y, width: radius * 2, height: radius * 2))
            }
        }
    }

    private func gravelImage() -> UIImage {
        let size = CGSize(width: 256, height: 256)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let cgContext = context.cgContext
            cgContext.setFillColor(UIColor(red: 0.52, green: 0.47, blue: 0.39, alpha: 1).cgColor)
            cgContext.fill(CGRect(origin: .zero, size: size))
            for _ in 0..<1600 {
                let x = CGFloat.random(in: 0..<size.width)
                let y = CGFloat.random(in: 0..<size.height)
                let radius = CGFloat.random(in: 0.6...2.4)
                let shade = CGFloat.random(in: 0.30...0.80)
                cgContext.setFillColor(UIColor(white: shade, alpha: 0.32).cgColor)
                cgContext.fillEllipse(in: CGRect(x: x, y: y, width: radius, height: radius))
            }
        }
    }

    /// 물결 노멀맵. 사인파를 겹쳐 타일이 이어지도록 만들었다.
    private func rippleNormalImage(edge: Int = 256) -> UIImage {
        var pixels = [UInt8](repeating: 0, count: edge * edge * 4)
        let twoPi = 2.0 * Double.pi

        func height(_ x: Int, _ y: Int) -> Double {
            let fx = Double(x) / Double(edge)
            let fy = Double(y) / Double(edge)
            let h1 = sin(twoPi * (3.0 * fx + 2.0 * fy))
            let h2 = sin(twoPi * (1.0 * fx - 2.0 * fy))
            let h3 = sin(twoPi * (5.0 * fx + 3.0 * fy))
            let h4 = cos(twoPi * (2.0 * fx + 7.0 * fy))
            return h1 * 0.5 + h2 * 0.32 + h3 * 0.14 + h4 * 0.10
        }

        for y in 0..<edge {
            for x in 0..<edge {
                let left = height((x - 1 + edge) % edge, y)
                let right = height((x + 1) % edge, y)
                let down = height(x, (y - 1 + edge) % edge)
                let up = height(x, (y + 1) % edge)

                var nx = -(right - left) * 1.6
                var ny = -(up - down) * 1.6
                var nz = 1.0
                let length = max(sqrt(nx * nx + ny * ny + nz * nz), 0.0001)
                nx /= length
                ny /= length
                nz /= length

                let index = (y * edge + x) * 4
                pixels[index] = UInt8(clamping: Int((nx * 0.5 + 0.5) * 255))
                pixels[index + 1] = UInt8(clamping: Int((ny * 0.5 + 0.5) * 255))
                pixels[index + 2] = UInt8(clamping: Int((nz * 0.5 + 0.5) * 255))
                pixels[index + 3] = 255
            }
        }

        let data = Data(pixels)
        guard let provider = CGDataProvider(data: data as CFData),
              let cgImage = CGImage(
                width: edge,
                height: edge,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: edge * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                provider: provider,
                decode: nil,
                shouldInterpolate: true,
                intent: .defaultIntent
              ) else {
            return UIImage()
        }
        return UIImage(cgImage: cgImage)
    }

    private func glowImage(color: UIColor) -> UIImage {
        let size: CGFloat = 64
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { context in
            let cgContext = context.cgContext
            let colors = [color.withAlphaComponent(1.0).cgColor, color.withAlphaComponent(0.0).cgColor] as CFArray
            guard let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors,
                locations: [0, 1]
            ) else { return }
            let center = CGPoint(x: size / 2, y: size / 2)
            cgContext.drawRadialGradient(
                gradient,
                startCenter: center,
                startRadius: 0,
                endCenter: center,
                endRadius: size / 2,
                options: []
            )
        }
    }
}
