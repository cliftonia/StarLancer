//
//  FleetManagerScene.swift
//  spritekit
//
//  Created by Clifton Baggerman on 28/03/2026.
//

import SpriteKit

class FleetManagerScene: SKScene {

    var gameState: GameState!
    var planetID: UUID!

    // MARK: - Scene Setup

    override func didMove(to view: SKView) {
        BackgroundBuilder.addSpaceBackground(to: self, drift: .none, nebula: false)
        buildHeader()
        buildCurrentFleet()
        buildShipShop()
        buildBackButton()
    }

    // MARK: - Header

    private func buildHeader() {
        let centerX = size.width * 0.5

        let title = SKLabelNode(fontNamed: Theme.titleFont)
        title.text = "FLEET COMMAND"
        title.fontSize = 28
        title.fontColor = Theme.creamWhite
        title.position = CGPoint(x: centerX, y: size.height - 65)
        title.zPosition = 20
        addChild(title)

        let subtitle = SKLabelNode(fontNamed: Theme.captionFont)
        subtitle.text = "// SPACEPORT — \(gameState.planet(withID: planetID)?.name ?? "UNKNOWN")"
        subtitle.fontSize = 10
        subtitle.fontColor = Theme.retroBlue.withAlphaComponent(0.6)
        subtitle.position = CGPoint(x: centerX, y: size.height - 85)
        subtitle.zPosition = 20
        addChild(subtitle)

        // Resources
        let resources = SKLabelNode(fontNamed: Theme.captionFont)
        resources.text = "CR \(gameState.player.credits)   MIN \(gameState.player.minerals)"
        resources.fontSize = 12
        resources.fontColor = Theme.warmGold
        resources.position = CGPoint(x: centerX, y: size.height - 108)
        resources.zPosition = 20
        addChild(resources)

        // Separator
        let sep = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: CGPoint(x: centerX - 130, y: size.height - 120))
        path.addLine(to: CGPoint(x: centerX + 130, y: size.height - 120))
        sep.path = path
        sep.strokeColor = Theme.nasaOrange.withAlphaComponent(0.3)
        sep.lineWidth = 1
        sep.glowWidth = 2
        sep.zPosition = 20
        addChild(sep)
    }

    // MARK: - Current Fleet

    private func buildCurrentFleet() {
        let centerX = size.width * 0.5
        let startY = size.height - 155

        let sectionLabel = SKLabelNode(fontNamed: Theme.bodyFont)
        sectionLabel.text = "CURRENT FLEET (\(gameState.player.totalShips) SHIPS)"
        sectionLabel.fontSize = 12
        sectionLabel.fontColor = Theme.creamWhite
        sectionLabel.position = CGPoint(x: centerX, y: startY)
        sectionLabel.zPosition = 20
        addChild(sectionLabel)

        let types = ShipType.allCases
        var y = startY - 22
        for type in types {
            let count = gameState.player.shipCount(for: type)
            guard count > 0 else { continue }

            let row = SKLabelNode(fontNamed: Theme.captionFont)
            row.text = "\(type.displayName): \(count)"
            row.fontSize = 11
            row.fontColor = Theme.warmGold.withAlphaComponent(0.8)
            row.position = CGPoint(x: centerX, y: y)
            row.zPosition = 20
            addChild(row)
            y -= 18
        }

        if gameState.player.totalShips == 0 {
            let empty = SKLabelNode(fontNamed: Theme.captionFont)
            empty.text = "NO SHIPS"
            empty.fontSize = 11
            empty.fontColor = Theme.hullGray.withAlphaComponent(0.4)
            empty.position = CGPoint(x: centerX, y: y)
            empty.zPosition = 20
            addChild(empty)
        }
    }

    // MARK: - Ship Shop

    private func buildShipShop() {
        let centerX = size.width * 0.5
        let startY = size.height - 320

        let sectionLabel = SKLabelNode(fontNamed: Theme.bodyFont)
        sectionLabel.text = "BUILD SHIPS"
        sectionLabel.fontSize = 12
        sectionLabel.fontColor = Theme.creamWhite
        sectionLabel.position = CGPoint(x: centerX, y: startY)
        sectionLabel.zPosition = 20
        addChild(sectionLabel)

        let shipDescriptions: [ShipType: String] = [
            .fighter: "+FIRE RATE",
            .destroyer: "+HULL HP",
            .bomber: "+STRUCTURE DMG",
            .missileCarrier: "HOMING MISSILES",
            .troopTransport: "NEEDED TO CAPTURE"
        ]

        for (i, type) in ShipType.allCases.enumerated() {
            let y = startY - 30 - CGFloat(i) * 54
            let canAfford = gameState.player.credits >= type.creditsCost && gameState.player.minerals >= type.mineralsCost

            let btn = SKNode()
            btn.name = "buy_\(type.rawValue)"
            btn.position = CGPoint(x: centerX, y: y)
            btn.zPosition = 30

            let bg = SKShapeNode(rectOf: CGSize(width: 270, height: 44), cornerRadius: 3)
            bg.fillColor = canAfford
                ? Theme.nasaOrange.withAlphaComponent(0.1)
                : SKColor(red: 0.06, green: 0.06, blue: 0.1, alpha: 0.5)
            bg.strokeColor = canAfford
                ? Theme.nasaOrange.withAlphaComponent(0.4)
                : Theme.hullGray.withAlphaComponent(0.2)
            bg.lineWidth = 1
            bg.glowWidth = canAfford ? 2 : 0
            bg.name = btn.name
            btn.addChild(bg)

            // Ship name
            let nameLabel = SKLabelNode(fontNamed: Theme.bodyFont)
            nameLabel.text = type.displayName
            nameLabel.fontSize = 11
            nameLabel.fontColor = canAfford ? Theme.creamWhite : Theme.hullGray.withAlphaComponent(0.4)
            nameLabel.horizontalAlignmentMode = .left
            nameLabel.verticalAlignmentMode = .center
            nameLabel.position = CGPoint(x: -122, y: 6)
            nameLabel.name = btn.name
            btn.addChild(nameLabel)

            // Effect description
            let descLabel = SKLabelNode(fontNamed: Theme.captionFont)
            descLabel.text = shipDescriptions[type] ?? ""
            descLabel.fontSize = 8
            descLabel.fontColor = canAfford ? Theme.retroBlue.withAlphaComponent(0.6) : Theme.hullGray.withAlphaComponent(0.3)
            descLabel.horizontalAlignmentMode = .left
            descLabel.verticalAlignmentMode = .center
            descLabel.position = CGPoint(x: -122, y: -8)
            descLabel.name = btn.name
            btn.addChild(descLabel)

            // Cost
            let costLabel = SKLabelNode(fontNamed: Theme.captionFont)
            costLabel.text = "\(type.creditsCost) CR  \(type.mineralsCost) MIN"
            costLabel.fontSize = 9
            costLabel.fontColor = canAfford ? Theme.warmGold.withAlphaComponent(0.7) : Theme.hullGray.withAlphaComponent(0.3)
            costLabel.horizontalAlignmentMode = .right
            costLabel.verticalAlignmentMode = .center
            costLabel.position = CGPoint(x: 122, y: 0)
            costLabel.name = btn.name
            btn.addChild(costLabel)

            addChild(btn)
        }
    }

    // MARK: - Back Button

    private func buildBackButton() {
        let btn = Theme.makeMenuButton(
            text: "< BACK TO PLANET",
            name: "backButton",
            position: CGPoint(x: size.width * 0.5, y: 55),
            accentColor: Theme.retroBlue
        )
        btn.zPosition = 30
        addChild(btn)
    }

    // MARK: - Touch

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tappedNodes = nodes(at: location)

        for node in tappedNodes {
            guard let name = node.name else { continue }

            if name == "backButton" {
                navigateBack()
                return
            }

            if name.hasPrefix("buy_") {
                let typeString = String(name.dropFirst(4))
                guard let shipType = ShipType(rawValue: typeString) else { continue }
                attemptBuy(shipType)
                return
            }
        }
    }

    // MARK: - Buy Ship

    private func attemptBuy(_ type: ShipType) {
        guard gameState.player.credits >= type.creditsCost,
              gameState.player.minerals >= type.mineralsCost else { return }

        gameState.player.credits -= type.creditsCost
        gameState.player.minerals -= type.mineralsCost
        gameState.player.addShip(type)

        // Refresh scene
        removeAllChildren()
        didMove(to: view!)
    }

    // MARK: - Navigation

    private func navigateBack() {
        let detail = PlanetDetailScene(size: size)
        detail.scaleMode = .resizeFill
        detail.gameState = gameState
        detail.planetID = planetID
        view?.presentScene(detail, transition: SKTransition.fade(withDuration: 0.3))
    }
}
