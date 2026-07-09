import SwiftUI
import SceneKit
import UIKit

struct GlobeSceneView: UIViewRepresentable {
    @ObservedObject var travelStore: TravelStore
    var onPlaceTapped: (TravelPlace) -> Void = { _ in }

    private let earthRadius: Float = 1.65

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        let scene = SCNScene()

        view.scene = scene
        view.backgroundColor = UIColor(red: 0.005, green: 0.012, blue: 0.035, alpha: 1.0)
        view.allowsCameraControl = true
        view.autoenablesDefaultLighting = false
        view.antialiasingMode = .multisampling4X
        view.preferredFramesPerSecond = 60

        context.coordinator.sceneView = view
        context.coordinator.earthRadius = earthRadius
        context.coordinator.pinRoot.removeFromParentNode()
        context.coordinator.pinRoot = SCNNode()
        context.coordinator.pinRoot.name = "PinRoot"

        setupCamera(in: scene, view: view)
        setupLights(in: scene)
        setupSpaceBackground(in: scene)
        setupEarth(in: scene)

        scene.rootNode.addChildNode(context.coordinator.pinRoot)

        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        view.addGestureRecognizer(tapGesture)

        context.coordinator.refreshPins(with: travelStore.places)
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.refreshPins(with: travelStore.places)
    }

    private func setupCamera(in scene: SCNScene, view: SCNView) {
        let cameraNode = SCNNode()
        cameraNode.name = "Camera"
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 42
        cameraNode.camera?.zNear = 0.05
        cameraNode.camera?.zFar = 100
        cameraNode.position = SCNVector3(0, 0, 5.3)
        scene.rootNode.addChildNode(cameraNode)

        view.pointOfView = cameraNode
        view.defaultCameraController.target = SCNVector3(0, 0, 0)
        view.defaultCameraController.inertiaEnabled = true
        view.defaultCameraController.maximumVerticalAngle = 89
        view.defaultCameraController.minimumVerticalAngle = -89
    }

    private func setupLights(in scene: SCNScene) {
        let ambientNode = SCNNode()
        ambientNode.name = "AmbientLight"
        ambientNode.light = SCNLight()
        ambientNode.light?.type = .ambient
        ambientNode.light?.intensity = 520
        ambientNode.light?.color = UIColor(red: 0.46, green: 0.58, blue: 0.82, alpha: 1.0)
        scene.rootNode.addChildNode(ambientNode)

        let sunNode = SCNNode()
        sunNode.name = "SunLight"
        sunNode.light = SCNLight()
        sunNode.light?.type = .directional
        sunNode.light?.intensity = 1350
        sunNode.light?.castsShadow = true
        sunNode.light?.shadowMode = .deferred
        sunNode.light?.shadowRadius = 5
        sunNode.position = SCNVector3(4.5, 3.2, 5.5)
        sunNode.eulerAngles = SCNVector3(-Float.pi / 4.2, Float.pi / 5.0, 0)
        scene.rootNode.addChildNode(sunNode)

        let rimNode = SCNNode()
        rimNode.name = "BlueRimLight"
        rimNode.light = SCNLight()
        rimNode.light?.type = .omni
        rimNode.light?.intensity = 180
        rimNode.light?.color = UIColor(red: 0.25, green: 0.85, blue: 1.0, alpha: 1.0)
        rimNode.position = SCNVector3(-4, 1.8, -3.5)
        scene.rootNode.addChildNode(rimNode)
    }

    private func setupSpaceBackground(in scene: SCNScene) {
        let starRoot = SCNNode()
        starRoot.name = "StarBackground"

        for _ in 0..<360 {
            let starSize = CGFloat.random(in: 0.004...0.018)
            let star = SCNSphere(radius: starSize)
            let material = SCNMaterial()
            material.diffuse.contents = UIColor.white
            material.emission.contents = UIColor.white
            material.lightingModel = .constant
            star.materials = [material]

            let node = SCNNode(geometry: star)
            node.position = SCNVector3(
                Float.random(in: -13...13),
                Float.random(in: -9...9),
                Float.random(in: -14 ... -5)
            )
            starRoot.addChildNode(node)
        }

        scene.rootNode.addChildNode(starRoot)
    }

    private func setupEarth(in scene: SCNScene) {
        let earthGeometry = SCNSphere(radius: CGFloat(earthRadius))
        earthGeometry.segmentCount = 160

        let earthMaterial = SCNMaterial()
        earthMaterial.diffuse.contents = makeEarthTexture()
        earthMaterial.emission.contents = UIColor(red: 0.0, green: 0.07, blue: 0.11, alpha: 1.0)
        earthMaterial.emission.intensity = 0.10
        earthMaterial.specular.contents = UIColor(red: 0.45, green: 0.78, blue: 0.90, alpha: 1.0)
        earthMaterial.shininess = 0.28
        earthMaterial.locksAmbientWithDiffuse = true
        earthMaterial.isDoubleSided = false
        earthGeometry.materials = [earthMaterial]

        let earthNode = SCNNode(geometry: earthGeometry)
        earthNode.name = "Earth"
        scene.rootNode.addChildNode(earthNode)

        let cloudGeometry = SCNSphere(radius: CGFloat(earthRadius * 1.012))
        cloudGeometry.segmentCount = 128
        let cloudMaterial = SCNMaterial()
        cloudMaterial.diffuse.contents = makeCloudTexture()
        cloudMaterial.transparency = 0.34
        cloudMaterial.blendMode = .alpha
        cloudMaterial.lightingModel = .constant
        cloudMaterial.isDoubleSided = true
        cloudGeometry.materials = [cloudMaterial]

        let cloudNode = SCNNode(geometry: cloudGeometry)
        cloudNode.name = "CloudLayer"
        cloudNode.runAction(.repeatForever(.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 140)))
        scene.rootNode.addChildNode(cloudNode)

        let atmosphereGeometry = SCNSphere(radius: CGFloat(earthRadius * 1.035))
        atmosphereGeometry.segmentCount = 128
        let atmosphereMaterial = SCNMaterial()
        atmosphereMaterial.diffuse.contents = UIColor.clear
        atmosphereMaterial.emission.contents = UIColor(red: 0.25, green: 0.8, blue: 1.0, alpha: 1.0)
        atmosphereMaterial.transparency = 0.18
        atmosphereMaterial.blendMode = .add
        atmosphereMaterial.lightingModel = .constant
        atmosphereMaterial.isDoubleSided = true
        atmosphereGeometry.materials = [atmosphereMaterial]

        let atmosphereNode = SCNNode(geometry: atmosphereGeometry)
        atmosphereNode.name = "Atmosphere"
        scene.rootNode.addChildNode(atmosphereNode)
    }

    private func makeEarthTexture() -> UIImage {
        let size = CGSize(width: 4096, height: 2048)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            let cg = context.cgContext
            let rect = CGRect(origin: .zero, size: size)

            let oceanGradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor(red: 0.01, green: 0.08, blue: 0.20, alpha: 1).cgColor,
                    UIColor(red: 0.03, green: 0.25, blue: 0.48, alpha: 1).cgColor,
                    UIColor(red: 0.00, green: 0.13, blue: 0.32, alpha: 1).cgColor
                ] as CFArray,
                locations: [0.0, 0.48, 1.0]
            )

            if let oceanGradient {
                cg.drawLinearGradient(
                    oceanGradient,
                    start: CGPoint(x: 0, y: 0),
                    end: CGPoint(x: size.width, y: size.height),
                    options: []
                )
            }

            func map(_ coordinate: GeoPoint) -> CGPoint {
                CGPoint(
                    x: ((coordinate.lon + 180) / 360) * size.width,
                    y: ((90 - coordinate.lat) / 180) * size.height
                )
            }

            func drawPolygon(_ points: [GeoPoint], fill: UIColor, stroke: UIColor? = nil) {
                guard points.count > 2 else { return }
                cg.beginPath()
                let first = map(points[0])
                cg.move(to: first)
                for point in points.dropFirst() {
                    cg.addLine(to: map(point))
                }
                cg.closePath()
                cg.setFillColor(fill.cgColor)
                cg.fillPath()

                if let stroke {
                    cg.beginPath()
                    cg.move(to: first)
                    for point in points.dropFirst() {
                        cg.addLine(to: map(point))
                    }
                    cg.closePath()
                    cg.setStrokeColor(stroke.cgColor)
                    cg.setLineWidth(3.5)
                    cg.strokePath()
                }
            }

            let landFill = UIColor(red: 0.18, green: 0.55, blue: 0.28, alpha: 1.0)
            let landHighlight = UIColor(red: 0.48, green: 0.74, blue: 0.34, alpha: 1.0)
            let coast = UIColor(red: 0.80, green: 0.95, blue: 0.68, alpha: 0.55)
            let desert = UIColor(red: 0.73, green: 0.62, blue: 0.35, alpha: 0.52)
            let ice = UIColor(red: 0.92, green: 0.98, blue: 1.0, alpha: 0.92)

            let landMasses: [[GeoPoint]] = [
                // North America
                [
                    .init(-168, 72), .init(-145, 71), .init(-124, 63), .init(-104, 60), .init(-82, 52),
                    .init(-58, 53), .init(-52, 43), .init(-66, 31), .init(-82, 25), .init(-96, 18),
                    .init(-108, 23), .init(-119, 33), .init(-126, 47), .init(-140, 58), .init(-168, 72)
                ],
                // Central America
                [
                    .init(-100, 22), .init(-86, 18), .init(-77, 9), .init(-81, 7), .init(-91, 13), .init(-103, 18)
                ],
                // South America
                [
                    .init(-81, 12), .init(-66, 9), .init(-49, 1), .init(-36, -13), .init(-45, -25),
                    .init(-53, -42), .init(-68, -55), .init(-75, -38), .init(-80, -16), .init(-81, 12)
                ],
                // Greenland
                [
                    .init(-54, 82), .init(-22, 78), .init(-18, 65), .init(-42, 60), .init(-61, 68), .init(-54, 82)
                ],
                // Europe
                [
                    .init(-11, 71), .init(22, 70), .init(42, 58), .init(32, 45), .init(16, 38),
                    .init(4, 37), .init(-10, 44), .init(-11, 71)
                ],
                // Africa
                [
                    .init(-18, 36), .init(20, 35), .init(51, 12), .init(43, -33), .init(24, -35),
                    .init(9, -25), .init(-7, -8), .init(-17, 12), .init(-18, 36)
                ],
                // Middle East / West Asia
                [
                    .init(32, 42), .init(58, 39), .init(70, 25), .init(55, 12), .init(42, 15), .init(32, 30)
                ],
                // Asia
                [
                    .init(38, 70), .init(78, 73), .init(122, 67), .init(165, 58), .init(156, 42),
                    .init(136, 37), .init(122, 20), .init(107, 8), .init(96, 14), .init(82, 8),
                    .init(72, 23), .init(61, 35), .init(46, 42), .init(38, 70)
                ],
                // India / Southeast Asia
                [
                    .init(68, 24), .init(86, 25), .init(94, 17), .init(101, 7), .init(112, 1),
                    .init(105, -8), .init(96, 5), .init(88, 22), .init(78, 8), .init(68, 24)
                ],
                // Japan
                [
                    .init(130, 45), .init(144, 42), .init(142, 31), .init(132, 32), .init(130, 45)
                ],
                // Philippines
                [
                    .init(119, 19), .init(126, 15), .init(124, 5), .init(117, 7), .init(119, 19)
                ],
                // Indonesia
                [
                    .init(95, 5), .init(126, 2), .init(142, -5), .init(132, -9), .init(105, -6), .init(95, 5)
                ],
                // Australia
                [
                    .init(112, -11), .init(154, -12), .init(153, -38), .init(132, -43), .init(114, -35), .init(112, -11)
                ],
                // New Zealand
                [
                    .init(166, -35), .init(179, -39), .init(176, -47), .init(166, -44), .init(166, -35)
                ],
                // Antarctica
                [
                    .init(-180, -72), .init(-120, -75), .init(-60, -72), .init(0, -76), .init(60, -72),
                    .init(120, -75), .init(180, -72), .init(180, -90), .init(-180, -90), .init(-180, -72)
                ]
            ]

            for polygon in landMasses {
                drawPolygon(polygon, fill: landFill, stroke: coast)
            }

            let highlights: [[GeoPoint]] = [
                [.init(-125, 50), .init(-98, 47), .init(-75, 40), .init(-96, 30), .init(-122, 38)],
                [.init(-72, -5), .init(-54, -12), .init(-50, -28), .init(-67, -36), .init(-75, -20)],
                [.init(14, 58), .init(30, 55), .init(20, 46), .init(3, 48)],
                [.init(72, 56), .init(112, 52), .init(130, 43), .init(95, 34), .init(70, 42)],
                [.init(119, -20), .init(145, -22), .init(137, -34), .init(120, -32)]
            ]

            for polygon in highlights {
                drawPolygon(polygon, fill: landHighlight.withAlphaComponent(0.58), stroke: nil)
            }

            let desertAreas: [[GeoPoint]] = [
                [.init(-15, 30), .init(30, 28), .init(35, 15), .init(5, 10), .init(-12, 17)],
                [.init(38, 30), .init(65, 28), .init(58, 18), .init(42, 18)],
                [.init(118, -20), .init(138, -22), .init(132, -31), .init(116, -30)]
            ]

            for polygon in desertAreas {
                drawPolygon(polygon, fill: desert, stroke: nil)
            }

            drawPolygon([.init(-180, 90), .init(180, 90), .init(180, 76), .init(90, 80), .init(0, 76), .init(-90, 80), .init(-180, 76)], fill: ice, stroke: nil)

            cg.setStrokeColor(UIColor.white.withAlphaComponent(0.075).cgColor)
            cg.setLineWidth(1.2)

            for latitude in stride(from: -60, through: 60, by: 30) {
                let y = ((90 - CGFloat(latitude)) / 180) * size.height
                cg.move(to: CGPoint(x: 0, y: y))
                cg.addLine(to: CGPoint(x: size.width, y: y))
                cg.strokePath()
            }

            for longitude in stride(from: -150, through: 180, by: 30) {
                let x = ((CGFloat(longitude) + 180) / 360) * size.width
                cg.move(to: CGPoint(x: x, y: 0))
                cg.addLine(to: CGPoint(x: x, y: size.height))
                cg.strokePath()
            }

            cg.setStrokeColor(UIColor.white.withAlphaComponent(0.12).cgColor)
            cg.setLineWidth(2.0)
            cg.stroke(rect.insetBy(dx: 1, dy: 1))
        }
    }

    private func makeCloudTexture() -> UIImage {
        let size = CGSize(width: 2048, height: 1024)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            let cg = context.cgContext
            cg.clear(CGRect(origin: .zero, size: size))

            for _ in 0..<95 {
                let x = CGFloat.random(in: 0...size.width)
                let y = CGFloat.random(in: size.height * 0.12...size.height * 0.88)
                let width = CGFloat.random(in: 120...360)
                let height = CGFloat.random(in: 18...62)
                let alpha = CGFloat.random(in: 0.12...0.34)

                cg.saveGState()
                cg.translateBy(x: x, y: y)
                cg.rotate(by: CGFloat.random(in: -0.25...0.25))
                cg.setFillColor(UIColor.white.withAlphaComponent(alpha).cgColor)
                cg.fillEllipse(in: CGRect(x: -width / 2, y: -height / 2, width: width, height: height))
                cg.restoreGState()
            }
        }
    }

    final class Coordinator: NSObject {
        var parent: GlobeSceneView
        weak var sceneView: SCNView?
        var pinRoot = SCNNode()
        var earthRadius: Float = 1.65
        private var placeByPinName: [String: TravelPlace] = [:]

        init(_ parent: GlobeSceneView) {
            self.parent = parent
        }

        func refreshPins(with places: [TravelPlace]) {
            pinRoot.childNodes.forEach { $0.removeFromParentNode() }
            placeByPinName.removeAll()

            for place in places {
                addPin(for: place)
            }
        }

        private func addPin(for place: TravelPlace) {
            guard place.latitude >= -90,
                  place.latitude <= 90,
                  place.longitude >= -180,
                  place.longitude <= 180 else {
                return
            }

            let normal = Self.position(latitude: place.latitude, longitude: place.longitude, radius: 1).normalized()
            let position = SCNVector3(
                normal.x * (earthRadius + 0.09),
                normal.y * (earthRadius + 0.09),
                normal.z * (earthRadius + 0.09)
            )

            let pinName = "pin-\(place.id.uuidString)"
            placeByPinName[pinName] = place

            let group = SCNNode()
            group.name = pinName
            group.position = position

            let ballGeometry = SCNSphere(radius: 0.068)
            ballGeometry.segmentCount = 32
            let ballMaterial = SCNMaterial()
            ballMaterial.diffuse.contents = UIColor.systemOrange
            ballMaterial.emission.contents = UIColor(red: 1.0, green: 0.18, blue: 0.04, alpha: 1.0)
            ballMaterial.emission.intensity = 1.9
            ballMaterial.specular.contents = UIColor.white
            ballGeometry.materials = [ballMaterial]

            let ballNode = SCNNode(geometry: ballGeometry)
            ballNode.name = pinName
            group.addChildNode(ballNode)

            let stemGeometry = SCNCylinder(radius: 0.012, height: 0.18)
            stemGeometry.radialSegmentCount = 16
            let stemMaterial = SCNMaterial()
            stemMaterial.diffuse.contents = UIColor.systemRed
            stemMaterial.emission.contents = UIColor(red: 1.0, green: 0.05, blue: 0.05, alpha: 1.0)
            stemMaterial.emission.intensity = 1.1
            stemGeometry.materials = [stemMaterial]

            let stemNode = SCNNode(geometry: stemGeometry)
            stemNode.name = pinName
            stemNode.position = SCNVector3(-normal.x * 0.07, -normal.y * 0.07, -normal.z * 0.07)
            stemNode.orientation = Self.orientationFromYAxis(to: normal)
            group.addChildNode(stemNode)

            let glowGeometry = SCNSphere(radius: 0.16)
            glowGeometry.segmentCount = 24
            let glowMaterial = SCNMaterial()
            glowMaterial.diffuse.contents = UIColor.clear
            glowMaterial.emission.contents = UIColor(red: 1.0, green: 0.08, blue: 0.02, alpha: 1.0)
            glowMaterial.transparency = 0.24
            glowMaterial.blendMode = .add
            glowMaterial.lightingModel = .constant
            glowGeometry.materials = [glowMaterial]

            let glowNode = SCNNode(geometry: glowGeometry)
            glowNode.name = pinName
            group.addChildNode(glowNode)

            let scaleUp = SCNAction.scale(to: 1.22, duration: 0.85)
            scaleUp.timingMode = .easeInEaseOut
            let scaleDown = SCNAction.scale(to: 1.0, duration: 0.85)
            scaleDown.timingMode = .easeInEaseOut
            glowNode.runAction(.repeatForever(.sequence([scaleUp, scaleDown])))

            pinRoot.addChildNode(group)
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let sceneView else { return }
            let location = gesture.location(in: sceneView)
            let hits = sceneView.hitTest(location, options: [
                SCNHitTestOption.boundingBoxOnly: false,
                SCNHitTestOption.searchMode: SCNHitTestSearchMode.all.rawValue
            ])

            for hit in hits {
                var node: SCNNode? = hit.node
                while let current = node {
                    if let name = current.name,
                       let place = placeByPinName[name] {
                        parent.onPlaceTapped(place)
                        animatePin(named: name)
                        return
                    }
                    node = current.parent
                }
            }
        }

        private func animatePin(named name: String) {
            guard let node = pinRoot.childNode(withName: name, recursively: true) else { return }
            let up = SCNAction.scale(to: 1.5, duration: 0.12)
            up.timingMode = .easeOut
            let down = SCNAction.scale(to: 1.0, duration: 0.22)
            down.timingMode = .easeInEaseOut
            node.runAction(.sequence([up, down]))
        }

        private static func position(latitude: Double, longitude: Double, radius: Float) -> SCNVector3 {
            let lat = Float(latitude) * .pi / 180
            let lon = Float(longitude) * .pi / 180

            let x = radius * cos(lat) * sin(lon)
            let y = radius * sin(lat)
            let z = radius * cos(lat) * cos(lon)

            return SCNVector3(x, y, z)
        }

        private static func orientationFromYAxis(to direction: SCNVector3) -> SCNQuaternion {
            let from = SCNVector3(0, 1, 0)
            let to = direction.normalized()
            let axis = from.cross(to)
            let dot = max(-1, min(1, from.dot(to)))
            let angle = acos(dot)

            if axis.length() < 0.0001 {
                return SCNQuaternion(0, 0, 0, 1)
            }

            let normalizedAxis = axis.normalized()
            let half = angle / 2
            let sinHalf = sin(half)

            return SCNQuaternion(
                normalizedAxis.x * sinHalf,
                normalizedAxis.y * sinHalf,
                normalizedAxis.z * sinHalf,
                cos(half)
            )
        }
    }
}

private struct GeoPoint {
    let lon: CGFloat
    let lat: CGFloat

    init(_ lon: CGFloat, _ lat: CGFloat) {
        self.lon = lon
        self.lat = lat
    }
}

private extension SCNVector3 {
    func length() -> Float {
        sqrt(x * x + y * y + z * z)
    }

    func normalized() -> SCNVector3 {
        let length = length()
        guard length > 0 else { return SCNVector3(0, 0, 0) }
        return SCNVector3(x / length, y / length, z / length)
    }

    func dot(_ other: SCNVector3) -> Float {
        x * other.x + y * other.y + z * other.z
    }

    func cross(_ other: SCNVector3) -> SCNVector3 {
        SCNVector3(
            y * other.z - z * other.y,
            z * other.x - x * other.z,
            x * other.y - y * other.x
        )
    }
}
