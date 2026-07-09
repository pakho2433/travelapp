import SwiftUI
import SceneKit

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
        view.backgroundColor = UIColor(red: 0.01, green: 0.015, blue: 0.04, alpha: 1)
        view.allowsCameraControl = true
        view.autoenablesDefaultLighting = false
        view.antialiasingMode = .multisampling4X

        context.coordinator.sceneView = view
        context.coordinator.pinRoot.removeFromParentNode()
        context.coordinator.pinRoot = SCNNode()
        context.coordinator.pinRoot.name = "PinRoot"
        context.coordinator.earthRadius = earthRadius

        addCamera(to: scene, view: view)
        addLights(to: scene)
        addStars(to: scene)
        addEarth(to: scene)
        scene.rootNode.addChildNode(context.coordinator.pinRoot)

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tap)
        context.coordinator.refreshPins(with: travelStore.places)
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.refreshPins(with: travelStore.places)
    }

    private func addCamera(to scene: SCNScene, view: SCNView) {
        let camera = SCNNode()
        camera.name = "Camera"
        camera.camera = SCNCamera()
        camera.camera?.fieldOfView = 45
        camera.position = SCNVector3(0, 0, 5.2)
        scene.rootNode.addChildNode(camera)
        view.pointOfView = camera
        view.defaultCameraController.target = SCNVector3(0, 0, 0)
        view.defaultCameraController.inertiaEnabled = true
    }

    private func addLights(to scene: SCNScene) {
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 520
        ambient.light?.color = UIColor(red: 0.45, green: 0.65, blue: 1, alpha: 1)
        scene.rootNode.addChildNode(ambient)

        let sun = SCNNode()
        sun.light = SCNLight()
        sun.light?.type = .directional
        sun.light?.intensity = 1250
        sun.light?.castsShadow = true
        sun.position = SCNVector3(4, 3, 5)
        sun.eulerAngles = SCNVector3(-Float.pi / 4, Float.pi / 5, 0)
        scene.rootNode.addChildNode(sun)
    }

    private func addStars(to scene: SCNScene) {
        let group = SCNNode()
        group.name = "Stars"
        for _ in 0..<220 {
            let star = SCNSphere(radius: CGFloat.random(in: 0.006...0.018))
            let material = SCNMaterial()
            material.diffuse.contents = UIColor.white
            material.emission.contents = UIColor.white
            material.lightingModel = .constant
            star.materials = [material]

            let node = SCNNode(geometry: star)
            node.position = SCNVector3(
                Float.random(in: -11...11),
                Float.random(in: -7...7),
                Float.random(in: -12 ... -5)
            )
            group.addChildNode(node)
        }
        scene.rootNode.addChildNode(group)
    }

    private func addEarth(to scene: SCNScene) {
        let earth = SCNSphere(radius: CGFloat(earthRadius))
        earth.segmentCount = 96
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 0.02, green: 0.43, blue: 0.55, alpha: 1)
        material.emission.contents = UIColor(red: 0.01, green: 0.16, blue: 0.22, alpha: 1)
        material.specular.contents = UIColor(red: 0.55, green: 1, blue: 0.95, alpha: 1)
        material.shininess = 0.35
        earth.materials = [material]

        let earthNode = SCNNode(geometry: earth)
        earthNode.name = "Earth"
        scene.rootNode.addChildNode(earthNode)

        let grid = SCNSphere(radius: CGFloat(earthRadius + 0.006))
        grid.segmentCount = 48
        let gridMaterial = SCNMaterial()
        gridMaterial.diffuse.contents = UIColor.cyan.withAlphaComponent(0.22)
        gridMaterial.emission.contents = UIColor.cyan.withAlphaComponent(0.12)
        gridMaterial.isDoubleSided = true
        gridMaterial.fillMode = .lines
        gridMaterial.lightingModel = .constant
        grid.materials = [gridMaterial]
        scene.rootNode.addChildNode(SCNNode(geometry: grid))

        let glow = SCNSphere(radius: CGFloat(earthRadius * 1.035))
        glow.segmentCount = 96
        let glowMaterial = SCNMaterial()
        glowMaterial.diffuse.contents = UIColor.clear
        glowMaterial.emission.contents = UIColor(red: 0.25, green: 0.95, blue: 1, alpha: 1)
        glowMaterial.transparency = 0.13
        glowMaterial.blendMode = .add
        glowMaterial.isDoubleSided = true
        glowMaterial.lightingModel = .constant
        glow.materials = [glowMaterial]
        scene.rootNode.addChildNode(SCNNode(geometry: glow))
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
            let position = Self.position(latitude: place.latitude, longitude: place.longitude, radius: earthRadius + 0.08)
            let name = "pin-\(place.id.uuidString)"
            placeByPinName[name] = place

            let group = SCNNode()
            group.name = name
            group.position = position

            let ball = SCNSphere(radius: 0.065)
            ball.segmentCount = 32
            let ballMaterial = SCNMaterial()
            ballMaterial.diffuse.contents = UIColor.systemOrange
            ballMaterial.emission.contents = UIColor(red: 1, green: 0.2, blue: 0.05, alpha: 1)
            ballMaterial.emission.intensity = 1.8
            ball.materials = [ballMaterial]

            let ballNode = SCNNode(geometry: ball)
            ballNode.name = name
            group.addChildNode(ballNode)

            let glow = SCNSphere(radius: 0.15)
            let glowMaterial = SCNMaterial()
            glowMaterial.diffuse.contents = UIColor.clear
            glowMaterial.emission.contents = UIColor.systemRed
            glowMaterial.transparency = 0.23
            glowMaterial.blendMode = .add
            glowMaterial.lightingModel = .constant
            glow.materials = [glowMaterial]

            let glowNode = SCNNode(geometry: glow)
            glowNode.name = name
            group.addChildNode(glowNode)

            let up = SCNAction.scale(to: 1.18, duration: 0.85)
            up.timingMode = .easeInEaseOut
            let down = SCNAction.scale(to: 1.0, duration: 0.85)
            down.timingMode = .easeInEaseOut
            glowNode.runAction(.repeatForever(.sequence([up, down])))

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
                    if let name = current.name, let place = placeByPinName[name] {
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
            let up = SCNAction.scale(to: 1.45, duration: 0.12)
            let down = SCNAction.scale(to: 1.0, duration: 0.22)
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
    }
}
