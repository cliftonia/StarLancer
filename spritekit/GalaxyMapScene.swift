//
//  GalaxyMapScene.swift
//  spritekit
//
//  Created by Clifton Baggerman on 28/03/2026.
//

import SpriteKit

class GalaxyMapScene: SKScene {

    var gameState: GameState!

    var cameraNode: SKCameraNode!
    var mapNode: SKNode!
    var planetNodes: [UUID: SKNode] = [:]
    var shipIcon: SKNode!
    var selectionRing: SKShapeNode?
    var selectedPlanetID: UUID?

    // HUD
    var fuelLabel: SKLabelNode?
    var creditsLabel: SKLabelNode?
    var turnLabel: SKLabelNode?
    var planetInfoNode: SKNode?

    // Interaction
    var lastPanPoint: CGPoint?
    var isTravelAnimating = false

    // Notifications
    var notificationQueue: [String] = []
    var isShowingNotification = false

    // MARK: - Scene Setup

    override func didMove(to view: SKView) {
        backgroundColor = Theme.deepSpace

        cameraNode = SKCameraNode()
        camera = cameraNode
        addChild(cameraNode)

        mapNode = SKNode()
        mapNode.zPosition = 0
        addChild(mapNode)

        BackgroundBuilder.addStarfield(to: self, drift: .none, layers: [
            (200, 0.3...0.8, 0.1...0.25, 0),
            (60, 0.8...1.5, 0.2...0.45, 0)
        ])

        buildRouteLines()
        buildPlanets()
        buildShipIcon()
        buildHUD()

        if let currentID = gameState.player.currentPlanetID,
           let planet = gameState.planet(withID: currentID) {
            cameraNode.position = planet.position
        }

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        view.addGestureRecognizer(pan)

        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        view.addGestureRecognizer(pinch)
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
            line.strokeColor = Theme.hullGray.withAlphaComponent(0.15)
            line.lineWidth = 1
            line.glowWidth = 1
            line.zPosition = 1
            mapNode.addChild(line)

            let dx = b.positionX - a.positionX
            let dy = b.positionY - a.positionY
            let dist = sqrt(dx * dx + dy * dy)
            let dotCount = Int(dist / 20)
            for i in stride(from: 1, to: dotCount, by: 2) {
                let t = CGFloat(i) / CGFloat(dotCount)
                let dot = SKShapeNode(circleOfRadius: 0.8)
                dot.fillColor = Theme.hullGray.withAlphaComponent(0.25)
                dot.strokeColor = .clear
                dot.position = CGPoint(
                    x: a.positionX + dx * Double(t),
                    y: a.positionY + dy * Double(t)
                )
                dot.zPosition = 1
                mapNode.addChild(dot)
            }
        }
    }

    // MARK: - Planets

    func buildPlanets() {
        for planet in gameState.planets {
            let node = SKNode()
            node.position = planet.position
            node.name = "planet_\(planet.id.uuidString)"
            node.zPosition = 5

            let radius: CGFloat = planet.isHQ ? 16 : 10 + CGFloat(planet.population) / 40
            let body = SKShapeNode(circleOfRadius: radius)
            body.name = node.name

            if let owner = planet.owner {
                body.fillColor = factionColor(owner).withAlphaComponent(0.7)
                body.strokeColor = factionColor(owner)
                body.glowWidth = planet.isHQ ? 8 : 4
            } else {
                body.fillColor = Theme.hullGray.withAlphaComponent(0.4)
                body.strokeColor = Theme.hullGray.withAlphaComponent(0.6)
                body.glowWidth = 2
            }
            body.lineWidth = 1.5
            node.addChild(body)

            let label = SKLabelNode(fontNamed: Theme.captionFont)
            label.text = planet.name
            label.fontSize = 9
            label.fontColor = Theme.creamWhite.withAlphaComponent(0.7)
            label.position = CGPoint(x: 0, y: -radius - 14)
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            node.addChild(label)

            if planet.isHQ {
                let hqLabel = SKLabelNode(fontNamed: Theme.bodyFont)
                hqLabel.text = "HQ"
                hqLabel.fontSize = 7
                hqLabel.fontColor = Theme.warmGold
                hqLabel.position = CGPoint(x: 0, y: radius + 10)
                hqLabel.verticalAlignmentMode = .center
                node.addChild(hqLabel)
            }

            if planet.owner != nil {
                let pulse = SKAction.sequence([
                    SKAction.fadeAlpha(to: 0.7, duration: 1.5),
                    SKAction.fadeAlpha(to: 1.0, duration: 1.5)
                ])
                body.run(SKAction.repeatForever(pulse))
            }

            planetNodes[planet.id] = node
            mapNode.addChild(node)
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

    // MARK: - Ship Icon

    func buildShipIcon() {
        let ship = SKNode()
        ship.zPosition = 15

        let hullPath = CGMutablePath()
        hullPath.move(to: CGPoint(x: 0, y: 10))
        hullPath.addLine(to: CGPoint(x: -6, y: -6))
        hullPath.addLine(to: CGPoint(x: 0, y: -3))
        hullPath.addLine(to: CGPoint(x: 6, y: -6))
        hullPath.closeSubpath()

        let hull = SKShapeNode(path: hullPath)
        hull.fillColor = Theme.creamWhite
        hull.strokeColor = Theme.nasaOrange
        hull.lineWidth = 1
        hull.glowWidth = 4
        ship.addChild(hull)

        if let currentID = gameState.player.currentPlanetID,
           let planet = gameState.planet(withID: currentID) {
            ship.position = CGPoint(x: planet.positionX, y: planet.positionY + 24)
        }

        let bob = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 3, duration: 1.0),
            SKAction.moveBy(x: 0, y: -3, duration: 1.0)
        ])
        ship.run(SKAction.repeatForever(bob))

        shipIcon = ship
        mapNode.addChild(ship)
    }
}
