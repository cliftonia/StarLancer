//
//  FreeRoamScene.swift
//  spritekit
//
//  Primary gameplay scene — fly your ship between planets in free-roam space.
//

import SpriteKit
import CoreMotion

class FreeRoamScene: SKScene {

    var gameState: GameState!

    // World
    let worldWidth: CGFloat = 800
    let worldHeight: CGFloat = 1200

    // Camera
    var cameraNode: SKCameraNode!
    var worldNode: SKNode!

    // Ship
    var playerShip: SKNode!
    var shipVelocity: CGVector = .zero
    let motionManager = CMMotionManager()
    var isTouching = false
    var touchLocation: CGPoint = .zero

    // Planets
    var planetNodes: [UUID: SKNode] = [:]

    // Docking
    let dockingRadius: CGFloat = 50
    var nearbyPlanetID: UUID?
    var dockPrompt: SKNode?

    // Timing
    var lastUpdateTime: TimeInterval = 0
    var fuelDrainTimer: TimeInterval = 0

    // State
    var isTransitioning = false

    // MARK: - Scene Setup

    override func didMove(to view: SKView) {
        backgroundColor = Theme.deepSpace

        // Camera
        cameraNode = SKCameraNode()
        camera = cameraNode
        addChild(cameraNode)

        // World container
        worldNode = SKNode()
        worldNode.zPosition = 0
        addChild(worldNode)

        // Background (applied to scene, moves with camera for parallax)
        BackgroundBuilder.addStarfield(to: self, drift: .none, layers: [
            (200, 0.3...0.8, 0.1...0.2, 0),
            (80, 0.8...1.5, 0.2...0.4, 0)
        ])

        buildRouteLines()
        buildPlanets()
        buildPlayerShip()
        buildHUD()

        // Position camera at ship
        cameraNode.position = CGPoint(x: gameState.player.shipX, y: gameState.player.shipY)

        // Start gyroscope
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates()
    }

    override func willMove(from view: SKView) {
        motionManager.stopDeviceMotionUpdates()
    }

    // MARK: - Route Lines

    func buildRouteLines() {
        for route in gameState.routes {
            guard let a = gameState.planet(withID: route.planetA),
                  let b = gameState.planet(withID: route.planetB) else { continue }

            let line = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: a.position)
            path.addLine(to: b.position)
            line.path = path
            line.strokeColor = Theme.hullGray.withAlphaComponent(0.08)
            line.lineWidth = 1
            line.zPosition = 1
            worldNode.addChild(line)
        }
    }

    // MARK: - Planets

    func buildPlanets() {
        for planet in gameState.planets {
            let node = SKNode()
            node.position = planet.position
            node.name = "planet_\(planet.id.uuidString)"
            node.zPosition = 3

            // Planet body — larger than galaxy map version
            let radius: CGFloat = planet.isHQ ? 28 : 18 + CGFloat(planet.population) / 50
            let body = SKShapeNode(circleOfRadius: radius)

            if let owner = planet.owner {
                body.fillColor = factionColor(owner).withAlphaComponent(0.5)
                body.strokeColor = factionColor(owner)
                body.glowWidth = planet.isHQ ? 12 : 6
            } else {
                body.fillColor = Theme.hullGray.withAlphaComponent(0.3)
                body.strokeColor = Theme.hullGray.withAlphaComponent(0.5)
                body.glowWidth = 3
            }
            body.lineWidth = 1.5
            node.addChild(body)

            // Atmosphere ring
            let atmo = SKShapeNode(circleOfRadius: radius + 6)
            atmo.fillColor = .clear
            atmo.strokeColor = (planet.owner != nil ? factionColor(planet.owner!) : Theme.hullGray).withAlphaComponent(0.15)
            atmo.lineWidth = 1
            atmo.glowWidth = 8
            node.addChild(atmo)

            // Planet name
            let label = SKLabelNode(fontNamed: Theme.captionFont)
            label.text = planet.name
            label.fontSize = 10
            label.fontColor = Theme.creamWhite.withAlphaComponent(0.8)
            label.position = CGPoint(x: 0, y: -radius - 16)
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            node.addChild(label)

            // HQ marker
            if planet.isHQ {
                let hqBadge = SKLabelNode(fontNamed: Theme.bodyFont)
                hqBadge.text = "HQ"
                hqBadge.fontSize = 8
                hqBadge.fontColor = Theme.warmGold
                hqBadge.position = CGPoint(x: 0, y: radius + 12)
                hqBadge.verticalAlignmentMode = .center
                node.addChild(hqBadge)
            }

            // Subtle pulse
            if planet.owner != nil {
                let pulse = SKAction.sequence([
                    SKAction.fadeAlpha(to: 0.7, duration: 2),
                    SKAction.fadeAlpha(to: 1.0, duration: 2)
                ])
                body.run(SKAction.repeatForever(pulse))
            }

            planetNodes[planet.id] = node
            worldNode.addChild(node)
        }
    }

    func factionColor(_ faction: Faction) -> SKColor {
        switch faction {
        case .player:  return Theme.retroBlue
        case .kethari: return Theme.offRed
        case .vossari: return Theme.onGreen
        case .draknor: return Theme.warmGold
        }
    }

    // MARK: - Player Ship

    func buildPlayerShip() {
        let ship = SKNode()
        ship.position = CGPoint(x: gameState.player.shipX, y: gameState.player.shipY)
        ship.zPosition = 10
        ship.name = "playerShip"

        // Hull
        let hullPath = CGMutablePath()
        hullPath.move(to: CGPoint(x: 0, y: 16))
        hullPath.addLine(to: CGPoint(x: -12, y: -12))
        hullPath.addLine(to: CGPoint(x: -5, y: -8))
        hullPath.addLine(to: CGPoint(x: 0, y: -10))
        hullPath.addLine(to: CGPoint(x: 5, y: -8))
        hullPath.addLine(to: CGPoint(x: 12, y: -12))
        hullPath.closeSubpath()

        let hull = SKShapeNode(path: hullPath)
        hull.fillColor = Theme.hullGray
        hull.strokeColor = Theme.creamWhite.withAlphaComponent(0.5)
        hull.lineWidth = 1
        ship.addChild(hull)

        // Cockpit
        let cockpit = SKShapeNode(circleOfRadius: 3)
        cockpit.fillColor = Theme.retroBlue.withAlphaComponent(0.7)
        cockpit.strokeColor = Theme.shieldBlue.withAlphaComponent(0.4)
        cockpit.glowWidth = 2
        cockpit.position = CGPoint(x: 0, y: 5)
        ship.addChild(cockpit)

        // Wing stripes
        for side in [-1.0, 1.0] {
            let stripe = SKShapeNode(rectOf: CGSize(width: 6, height: 1.5))
            stripe.fillColor = Theme.nasaOrange
            stripe.strokeColor = .clear
            stripe.position = CGPoint(x: side * 6, y: -3)
            ship.addChild(stripe)
        }

        // Engine glow
        let engine = SKEmitterNode()
        engine.particleBirthRate = 60
        engine.particleLifetime = 0.3
        engine.particleLifetimeRange = 0.15
        engine.particleSpeed = 80
        engine.particleSpeedRange = 20
        engine.emissionAngle = .pi * 1.5
        engine.emissionAngleRange = 0.2
        engine.particleScale = 0.03
        engine.particleScaleSpeed = -0.04
        engine.particleAlpha = 0.7
        engine.particleAlphaSpeed = -1.5
        engine.particleColor = Theme.engineGlow
        engine.particleColorBlendFactor = 1.0
        engine.particleBlendMode = .add
        engine.position = CGPoint(x: 0, y: -10)
        engine.zPosition = -1
        ship.addChild(engine)

        playerShip = ship
        worldNode.addChild(ship)
    }
}
