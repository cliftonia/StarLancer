//
//  PlanetDetailScene.swift
//  spritekit
//
//  Created by Clifton Baggerman on 28/03/2026.
//

import SpriteKit

class PlanetDetailScene: SKScene {

    var gameState: GameState!
    var planetID: UUID!

    private var planet: Planet { gameState.planet(withID: planetID)! }
    private var buildButtonNodes: [BuildingType: SKNode] = [:]

    // MARK: - Scene Setup

    override func didMove(to view: SKView) {
        BackgroundBuilder.addSpaceBackground(to: self, drift: .none, nebula: false)
        buildHeader()
        buildPlanetVisual()
        buildResourcePanel()
        buildBuildingsList()
        buildActionButtons()
        buildFleetButton()
        buildBackButton()
    }

    // MARK: - Header

    private func buildHeader() {
        let centerX = size.width * 0.5

        let title = SKLabelNode(fontNamed: Theme.titleFont)
        title.text = planet.name
        title.fontSize = 32
        title.fontColor = Theme.creamWhite
        title.position = CGPoint(x: centerX, y: size.height - 70)
        title.zPosition = 20
        addChild(title)

        let ownerText = planet.owner == .player ? "PLAYER COLONY" : (planet.owner?.rawValue.uppercased() ?? "UNCLAIMED")
        let subtitle = SKLabelNode(fontNamed: Theme.captionFont)
        subtitle.text = "// \(ownerText)"
        subtitle.fontSize = 11
        subtitle.fontColor = Theme.retroBlue.withAlphaComponent(0.6)
        subtitle.position = CGPoint(x: centerX, y: size.height - 92)
        subtitle.zPosition = 20
        addChild(subtitle)

        // Decorative line
        let sep = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: CGPoint(x: centerX - 130, y: size.height - 105))
        path.addLine(to: CGPoint(x: centerX + 130, y: size.height - 105))
        sep.path = path
        sep.strokeColor = Theme.nasaOrange.withAlphaComponent(0.3)
        sep.lineWidth = 1
        sep.glowWidth = 2
        sep.zPosition = 20
        addChild(sep)
    }

    // MARK: - Planet Visual

    private func buildPlanetVisual() {
        let centerX = size.width * 0.5
        let planetY = size.height - 170

        let body = SKShapeNode(circleOfRadius: 35)
        body.fillColor = Theme.retroBlue.withAlphaComponent(0.5)
        body.strokeColor = Theme.retroBlue
        body.lineWidth = 2
        body.glowWidth = 12
        body.position = CGPoint(x: centerX, y: planetY)
        body.zPosition = 5
        addChild(body)

        // Atmospheric ring
        let ring = SKShapeNode(circleOfRadius: 42)
        ring.fillColor = .clear
        ring.strokeColor = Theme.shieldBlue.withAlphaComponent(0.2)
        ring.lineWidth = 1
        ring.glowWidth = 6
        ring.position = CGPoint(x: centerX, y: planetY)
        ring.zPosition = 4
        addChild(ring)

        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 2),
            SKAction.fadeAlpha(to: 0.7, duration: 2)
        ])
        ring.run(SKAction.repeatForever(pulse))

        // HQ badge
        if planet.isHQ {
            let badge = SKLabelNode(fontNamed: Theme.bodyFont)
            badge.text = "HQ"
            badge.fontSize = 10
            badge.fontColor = Theme.warmGold
            badge.position = CGPoint(x: centerX, y: planetY + 50)
            badge.zPosition = 20
            addChild(badge)
        }
    }

    // MARK: - Resource Panel

    private func buildResourcePanel() {
        let centerX = size.width * 0.5
        let panelY = size.height - 250

        let resources: [(label: String, value: String, color: SKColor)] = [
            ("POP", "\(planet.population)", Theme.creamWhite),
            ("MIN", "\(gameState.player.minerals)", Theme.warmGold),
            ("CR", "\(gameState.player.credits)", Theme.warmGold),
            ("FUEL", "\(Int(gameState.player.fuel))", Theme.nasaOrange)
        ]

        let spacing: CGFloat = 65
        let startX = centerX - spacing * 1.5

        for (i, res) in resources.enumerated() {
            let x = startX + CGFloat(i) * spacing

            let valueLabel = SKLabelNode(fontNamed: Theme.bodyFont)
            valueLabel.text = res.value
            valueLabel.fontSize = 18
            valueLabel.fontColor = res.color
            valueLabel.position = CGPoint(x: x, y: panelY)
            valueLabel.zPosition = 20
            addChild(valueLabel)

            let nameLabel = SKLabelNode(fontNamed: Theme.captionFont)
            nameLabel.text = res.label
            nameLabel.fontSize = 9
            nameLabel.fontColor = Theme.hullGray.withAlphaComponent(0.6)
            nameLabel.position = CGPoint(x: x, y: panelY - 18)
            nameLabel.zPosition = 20
            addChild(nameLabel)
        }

        // Per-turn income line
        let incomeText = "+\(planet.mineralsPerTurn) MIN/T   +\(planet.creditsPerTurn) CR/T   +\(planet.populationPerTurn) POP/T"
        let incomeLabel = SKLabelNode(fontNamed: Theme.captionFont)
        incomeLabel.text = incomeText
        incomeLabel.fontSize = 9
        incomeLabel.fontColor = Theme.onGreen.withAlphaComponent(0.6)
        incomeLabel.position = CGPoint(x: centerX, y: panelY - 40)
        incomeLabel.zPosition = 20
        addChild(incomeLabel)
    }

    // MARK: - Existing Buildings

    private func buildBuildingsList() {
        let centerX = size.width * 0.5
        let startY = size.height - 320

        let sectionLabel = SKLabelNode(fontNamed: Theme.bodyFont)
        sectionLabel.text = "STRUCTURES"
        sectionLabel.fontSize = 13
        sectionLabel.fontColor = Theme.creamWhite
        sectionLabel.position = CGPoint(x: centerX, y: startY)
        sectionLabel.zPosition = 20
        addChild(sectionLabel)

        let existingBuildings: [(name: String, count: String)] = [
            ("MINE", "\(planet.mines)"),
            ("FACTORY", "\(planet.factories)"),
            ("SPACEPORT", planet.hasSpaceport ? "ACTIVE" : "--"),
            ("BIOSPHERE", planet.hasBiosphere ? "ACTIVE" : "--")
        ]

        for (i, building) in existingBuildings.enumerated() {
            let y = startY - 25 - CGFloat(i) * 22

            let nameLabel = SKLabelNode(fontNamed: Theme.captionFont)
            nameLabel.text = building.name
            nameLabel.fontSize = 11
            nameLabel.fontColor = Theme.hullGray.withAlphaComponent(0.7)
            nameLabel.horizontalAlignmentMode = .left
            nameLabel.position = CGPoint(x: centerX - 100, y: y)
            nameLabel.zPosition = 20
            addChild(nameLabel)

            let valueLabel = SKLabelNode(fontNamed: Theme.bodyFont)
            valueLabel.text = building.count
            valueLabel.fontSize = 11
            valueLabel.fontColor = building.count == "--" ? Theme.hullGray.withAlphaComponent(0.3) : Theme.warmGold
            valueLabel.horizontalAlignmentMode = .right
            valueLabel.position = CGPoint(x: centerX + 100, y: y)
            valueLabel.zPosition = 20
            addChild(valueLabel)
        }
    }

    // MARK: - Build Action Buttons

    private func buildActionButtons() {
        guard planet.owner == .player else { return }

        let centerX = size.width * 0.5
        let startY = size.height - 460

        let sectionLabel = SKLabelNode(fontNamed: Theme.bodyFont)
        sectionLabel.text = "BUILD"
        sectionLabel.fontSize = 13
        sectionLabel.fontColor = Theme.creamWhite
        sectionLabel.position = CGPoint(x: centerX, y: startY)
        sectionLabel.zPosition = 20
        addChild(sectionLabel)

        let buildOptions: [BuildingType] = [.mine, .factory, .spaceport, .biosphere]

        for (i, building) in buildOptions.enumerated() {
            let y = startY - 30 - CGFloat(i) * 50
            let canBuild = gameState.player.credits >= building.creditsCost
                && gameState.player.minerals >= building.mineralsCost

            // Skip if already built (for single-instance buildings)
            if building == .spaceport && planet.hasSpaceport { continue }
            if building == .biosphere && planet.hasBiosphere { continue }

            let btn = SKNode()
            btn.name = "build_\(building.rawValue)"
            btn.position = CGPoint(x: centerX, y: y)
            btn.zPosition = 30

            let bg = SKShapeNode(rectOf: CGSize(width: 260, height: 40), cornerRadius: 3)
            bg.fillColor = canBuild
                ? Theme.nasaOrange.withAlphaComponent(0.1)
                : SKColor(red: 0.06, green: 0.06, blue: 0.1, alpha: 0.5)
            bg.strokeColor = canBuild
                ? Theme.nasaOrange.withAlphaComponent(0.5)
                : Theme.hullGray.withAlphaComponent(0.2)
            bg.lineWidth = 1
            bg.glowWidth = canBuild ? 2 : 0
            bg.name = btn.name
            btn.addChild(bg)

            let nameLabel = SKLabelNode(fontNamed: Theme.bodyFont)
            nameLabel.text = building.displayName
            nameLabel.fontSize = 12
            nameLabel.fontColor = canBuild ? Theme.nasaOrange : Theme.hullGray.withAlphaComponent(0.4)
            nameLabel.horizontalAlignmentMode = .left
            nameLabel.verticalAlignmentMode = .center
            nameLabel.position = CGPoint(x: -118, y: 3)
            nameLabel.name = btn.name
            btn.addChild(nameLabel)

            var costParts: [String] = []
            if building.creditsCost > 0 { costParts.append("\(building.creditsCost) CR") }
            if building.mineralsCost > 0 { costParts.append("\(building.mineralsCost) MIN") }
            let costText = costParts.joined(separator: "  ")

            let costLabel = SKLabelNode(fontNamed: Theme.captionFont)
            costLabel.text = costText
            costLabel.fontSize = 9
            costLabel.fontColor = canBuild ? Theme.warmGold.withAlphaComponent(0.7) : Theme.hullGray.withAlphaComponent(0.3)
            costLabel.horizontalAlignmentMode = .left
            costLabel.verticalAlignmentMode = .center
            costLabel.position = CGPoint(x: -118, y: -10)
            costLabel.name = btn.name
            btn.addChild(costLabel)

            if canBuild {
                let arrow = SKLabelNode(fontNamed: Theme.bodyFont)
                arrow.text = "BUILD >"
                arrow.fontSize = 10
                arrow.fontColor = Theme.nasaOrange
                arrow.horizontalAlignmentMode = .right
                arrow.verticalAlignmentMode = .center
                arrow.position = CGPoint(x: 118, y: 0)
                arrow.name = btn.name
                btn.addChild(arrow)
            }

            buildButtonNodes[building] = btn
            addChild(btn)
        }
    }

    // MARK: - Fleet Button

    private func buildFleetButton() {
        guard planet.owner == .player, planet.hasSpaceport else { return }

        let btn = Theme.makeMenuButton(
            text: "FLEET COMMAND",
            name: "fleetButton",
            position: CGPoint(x: size.width * 0.5, y: 120),
            accentColor: Theme.warmGold
        )
        btn.zPosition = 30
        addChild(btn)
    }

    // MARK: - Back Button

    private func buildBackButton() {
        let btn = Theme.makeMenuButton(
            text: "< BACK TO MAP",
            name: "backButton",
            position: CGPoint(x: size.width * 0.5, y: 60),
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

            if name == "fleetButton" {
                openFleetManager()
                return
            }

            if name.hasPrefix("build_") {
                let typeString = String(name.dropFirst(6))
                guard let buildingType = BuildingType(rawValue: typeString) else { continue }
                attemptBuild(buildingType)
                return
            }
        }
    }

    // MARK: - Build

    private func attemptBuild(_ type: BuildingType) {
        guard var p = gameState.planet(withID: planetID) else { return }

        // Check player wallet (not planet resources)
        guard gameState.player.credits >= type.creditsCost,
              gameState.player.minerals >= type.mineralsCost else { return }

        // Deduct from player wallet
        gameState.player.credits -= type.creditsCost
        gameState.player.minerals -= type.mineralsCost

        // Apply building to planet
        switch type {
        case .mine:      p.mines += 1
        case .factory:   p.factories += 1
        case .spaceport: p.hasSpaceport = true
        case .biosphere: p.hasBiosphere = true
        }
        gameState.updatePlanet(p)

        // Refresh the scene
        removeAllChildren()
        didMove(to: view!)
    }

    // MARK: - Fleet

    private func openFleetManager() {
        let fleet = FleetManagerScene(size: size)
        fleet.scaleMode = .resizeFill
        fleet.gameState = gameState
        fleet.planetID = planetID
        view?.presentScene(fleet, transition: SKTransition.fade(withDuration: 0.3))
    }

    // MARK: - Navigation

    private func navigateBack() {
        let roam = FreeRoamScene(size: size)
        roam.scaleMode = .resizeFill
        roam.gameState = gameState
        view?.presentScene(roam, transition: SKTransition.fade(withDuration: 0.4))
    }
}
