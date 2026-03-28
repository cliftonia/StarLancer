//
//  GalaxyMapScene+HUD.swift
//  spritekit
//

import SpriteKit

extension GalaxyMapScene {

    // MARK: - HUD

    func buildHUD() {
        let hudZ: CGFloat = 100
        let padding: CGFloat = 16

        // Top bar background
        let topBar = SKShapeNode(rectOf: CGSize(width: size.width, height: 60))
        topBar.fillColor = SKColor.black.withAlphaComponent(0.6)
        topBar.strokeColor = Theme.hullGray.withAlphaComponent(0.2)
        topBar.lineWidth = 0.5
        topBar.position = CGPoint(x: 0, y: size.height * 0.5 - 30)
        topBar.zPosition = hudZ - 1
        cameraNode.addChild(topBar)

        // Turn
        let tl = SKLabelNode(fontNamed: Theme.bodyFont)
        tl.text = "TURN \(gameState.turn)"
        tl.fontSize = 14
        tl.fontColor = Theme.creamWhite
        tl.horizontalAlignmentMode = .left
        tl.verticalAlignmentMode = .center
        tl.position = CGPoint(x: -size.width * 0.5 + padding, y: size.height * 0.5 - 28)
        tl.zPosition = hudZ
        turnLabel = tl
        cameraNode.addChild(tl)

        // Fuel
        let fl = SKLabelNode(fontNamed: Theme.captionFont)
        fl.text = "FUEL \(Int(gameState.player.fuel))"
        fl.fontSize = 11
        fl.fontColor = Theme.warmGold
        fl.horizontalAlignmentMode = .right
        fl.verticalAlignmentMode = .center
        fl.position = CGPoint(x: size.width * 0.5 - padding, y: size.height * 0.5 - 20)
        fl.zPosition = hudZ
        fuelLabel = fl
        cameraNode.addChild(fl)

        // Credits
        let cl = SKLabelNode(fontNamed: Theme.captionFont)
        cl.text = "CR \(gameState.player.credits)"
        cl.fontSize = 11
        cl.fontColor = Theme.warmGold
        cl.horizontalAlignmentMode = .right
        cl.verticalAlignmentMode = .center
        cl.position = CGPoint(x: size.width * 0.5 - padding, y: size.height * 0.5 - 36)
        cl.zPosition = hudZ
        creditsLabel = cl
        cameraNode.addChild(cl)

        // Minerals
        let ml = SKLabelNode(fontNamed: Theme.captionFont)
        ml.text = "MIN \(gameState.player.minerals)"
        ml.fontSize = 11
        ml.fontColor = Theme.warmGold.withAlphaComponent(0.7)
        ml.horizontalAlignmentMode = .left
        ml.verticalAlignmentMode = .center
        ml.position = CGPoint(x: -size.width * 0.5 + padding, y: size.height * 0.5 - 44)
        ml.zPosition = hudZ
        ml.name = "mineralsLabel"
        cameraNode.addChild(ml)

        // Planet count
        let playerPlanets = gameState.planets.filter { $0.owner == .player }.count
        let totalPlanets = gameState.planets.count
        let pl = SKLabelNode(fontNamed: Theme.captionFont)
        pl.text = "PLANETS \(playerPlanets)/\(totalPlanets)"
        pl.fontSize = 10
        pl.fontColor = Theme.retroBlue.withAlphaComponent(0.6)
        pl.horizontalAlignmentMode = .center
        pl.verticalAlignmentMode = .center
        pl.position = CGPoint(x: 0, y: size.height * 0.5 - 20)
        pl.zPosition = hudZ
        pl.name = "planetCountLabel"
        cameraNode.addChild(pl)

        // Fleet count
        let fleetLabel = SKLabelNode(fontNamed: Theme.captionFont)
        fleetLabel.text = "FLEET \(gameState.player.totalShips)"
        fleetLabel.fontSize = 10
        fleetLabel.fontColor = Theme.hullGray.withAlphaComponent(0.5)
        fleetLabel.horizontalAlignmentMode = .center
        fleetLabel.verticalAlignmentMode = .center
        fleetLabel.position = CGPoint(x: 0, y: size.height * 0.5 - 36)
        fleetLabel.zPosition = hudZ
        fleetLabel.name = "fleetLabel"
        cameraNode.addChild(fleetLabel)

        // Income per turn
        let ownedPlanets = gameState.planets.filter { $0.owner == .player }
        let totalCR = ownedPlanets.reduce(0) { $0 + $1.creditsPerTurn }
        let totalMIN = ownedPlanets.reduce(0) { $0 + $1.mineralsPerTurn }
        let il = SKLabelNode(fontNamed: Theme.captionFont)
        il.text = "+\(totalCR) CR/T  +\(totalMIN) MIN/T"
        il.fontSize = 9
        il.fontColor = Theme.onGreen.withAlphaComponent(0.5)
        il.horizontalAlignmentMode = .right
        il.verticalAlignmentMode = .center
        il.position = CGPoint(x: size.width * 0.5 - padding, y: size.height * 0.5 - 48)
        il.zPosition = hudZ
        il.name = "incomeLabel"
        cameraNode.addChild(il)

        // Bottom menu button
        let menuBtn = Theme.makeMenuButton(
            text: "MAIN MENU",
            name: "menuButton",
            position: CGPoint(x: 0, y: -size.height * 0.5 + 40),
            accentColor: Theme.retroBlue
        )
        menuBtn.zPosition = hudZ
        menuBtn.setScale(0.85)
        cameraNode.addChild(menuBtn)
    }

    func updateHUD() {
        turnLabel?.text = "TURN \(gameState.turn)"
        fuelLabel?.text = "FUEL \(Int(gameState.player.fuel))"
        creditsLabel?.text = "CR \(gameState.player.credits)"

        if let ml = cameraNode.childNode(withName: "mineralsLabel") as? SKLabelNode {
            ml.text = "MIN \(gameState.player.minerals)"
        }

        let ownedPlanets = gameState.planets.filter { $0.owner == .player }
        if let pl = cameraNode.childNode(withName: "planetCountLabel") as? SKLabelNode {
            pl.text = "PLANETS \(ownedPlanets.count)/\(gameState.planets.count)"
        }
        if let fl = cameraNode.childNode(withName: "fleetLabel") as? SKLabelNode {
            fl.text = "FLEET \(gameState.player.totalShips)"
        }

        // Income summary
        let totalCR = ownedPlanets.reduce(0) { $0 + $1.creditsPerTurn }
        let totalMIN = ownedPlanets.reduce(0) { $0 + $1.mineralsPerTurn }
        if let il = cameraNode.childNode(withName: "incomeLabel") as? SKLabelNode {
            il.text = "+\(totalCR) CR/T  +\(totalMIN) MIN/T"
        }
    }

    // MARK: - Planet Info Panel

    func showPlanetInfo(_ planet: Planet) {
        planetInfoNode?.removeFromParent()

        let panel = SKNode()
        panel.zPosition = 100
        let panelY: CGFloat = -size.height * 0.5 + 140

        // Background
        let bg = SKShapeNode(rectOf: CGSize(width: 280, height: 130), cornerRadius: 4)
        bg.fillColor = SKColor(red: 0.04, green: 0.04, blue: 0.08, alpha: 0.9)
        bg.strokeColor = Theme.hullGray.withAlphaComponent(0.3)
        bg.lineWidth = 1
        bg.position = CGPoint(x: 0, y: panelY)
        panel.addChild(bg)

        // Planet name
        let nameLabel = SKLabelNode(fontNamed: Theme.bodyFont)
        nameLabel.text = planet.name
        nameLabel.fontSize = 16
        nameLabel.fontColor = planet.owner != nil ? factionColor(planet.owner!) : Theme.creamWhite
        nameLabel.position = CGPoint(x: 0, y: panelY + 42)
        panel.addChild(nameLabel)

        // Owner
        let ownerText = planet.owner?.rawValue.uppercased() ?? "UNCLAIMED"
        let ownerLabel = SKLabelNode(fontNamed: Theme.captionFont)
        ownerLabel.text = ownerText
        ownerLabel.fontSize = 10
        ownerLabel.fontColor = Theme.hullGray.withAlphaComponent(0.7)
        ownerLabel.position = CGPoint(x: 0, y: panelY + 24)
        panel.addChild(ownerLabel)

        // Stats
        let stats = "POP \(planet.population)  MIN \(planet.minerals)  CR \(planet.credits)"
        let statsLabel = SKLabelNode(fontNamed: Theme.captionFont)
        statsLabel.text = stats
        statsLabel.fontSize = 10
        statsLabel.fontColor = Theme.warmGold.withAlphaComponent(0.8)
        statsLabel.position = CGPoint(x: 0, y: panelY + 4)
        panel.addChild(statsLabel)

        // Buildings
        var buildings: [String] = []
        if planet.mines > 0 { buildings.append("MINE x\(planet.mines)") }
        if planet.factories > 0 { buildings.append("FAC x\(planet.factories)") }
        if planet.hasSpaceport { buildings.append("PORT") }
        if planet.hasBiosphere { buildings.append("BIO") }
        let buildingText = buildings.isEmpty ? "NO STRUCTURES" : buildings.joined(separator: "  ")
        let buildingLabel = SKLabelNode(fontNamed: Theme.captionFont)
        buildingLabel.text = buildingText
        buildingLabel.fontSize = 9
        buildingLabel.fontColor = Theme.hullGray.withAlphaComponent(0.6)
        buildingLabel.position = CGPoint(x: 0, y: panelY - 14)
        panel.addChild(buildingLabel)

        // Travel button (only if connected and not current planet)
        let isCurrentPlanet = planet.id == gameState.player.currentPlanetID
        let isConnected = gameState.connectedPlanets(from: gameState.player.currentPlanetID ?? UUID()).contains { $0.id == planet.id }

        if !isCurrentPlanet && isConnected {
            let fuelCost = gameState.fuelCost(from: gameState.player.currentPlanetID!, to: planet.id)
            let canAfford = gameState.player.fuel >= fuelCost

            let travelBtn = SKNode()
            travelBtn.name = "travelButton"
            travelBtn.position = CGPoint(x: 0, y: panelY - 40)

            let btnBg = SKShapeNode(rectOf: CGSize(width: 180, height: 32), cornerRadius: 3)
            btnBg.fillColor = canAfford ? Theme.nasaOrange.withAlphaComponent(0.2) : Theme.hullGray.withAlphaComponent(0.1)
            btnBg.strokeColor = canAfford ? Theme.nasaOrange.withAlphaComponent(0.6) : Theme.hullGray.withAlphaComponent(0.3)
            btnBg.lineWidth = 1
            btnBg.glowWidth = canAfford ? 3 : 0
            btnBg.name = "travelButton"
            travelBtn.addChild(btnBg)

            let btnText = SKLabelNode(fontNamed: Theme.bodyFont)
            btnText.text = canAfford ? "TRAVEL (FUEL -\(Int(fuelCost)))" : "NOT ENOUGH FUEL"
            btnText.fontSize = 11
            btnText.fontColor = canAfford ? Theme.nasaOrange : Theme.hullGray.withAlphaComponent(0.5)
            btnText.verticalAlignmentMode = .center
            btnText.name = "travelButton"
            travelBtn.addChild(btnText)

            panel.addChild(travelBtn)
        } else if isCurrentPlanet && planet.owner == .player {
            // Manage planet button
            let manageBtn = SKNode()
            manageBtn.name = "manageButton"
            manageBtn.position = CGPoint(x: 0, y: panelY - 40)

            let manageBg = SKShapeNode(rectOf: CGSize(width: 180, height: 32), cornerRadius: 3)
            manageBg.fillColor = Theme.retroBlue.withAlphaComponent(0.2)
            manageBg.strokeColor = Theme.retroBlue.withAlphaComponent(0.6)
            manageBg.lineWidth = 1
            manageBg.glowWidth = 3
            manageBg.name = "manageButton"
            manageBtn.addChild(manageBg)

            let manageText = SKLabelNode(fontNamed: Theme.bodyFont)
            manageText.text = "MANAGE PLANET"
            manageText.fontSize = 11
            manageText.fontColor = Theme.retroBlue
            manageText.verticalAlignmentMode = .center
            manageText.name = "manageButton"
            manageBtn.addChild(manageText)

            panel.addChild(manageBtn)
        } else if isCurrentPlanet && planet.owner == nil {
            // Claim unclaimed planet
            let claimBtn = SKNode()
            claimBtn.name = "claimButton"
            claimBtn.position = CGPoint(x: 0, y: panelY - 40)

            let claimBg = SKShapeNode(rectOf: CGSize(width: 180, height: 32), cornerRadius: 3)
            claimBg.fillColor = Theme.onGreen.withAlphaComponent(0.2)
            claimBg.strokeColor = Theme.onGreen.withAlphaComponent(0.6)
            claimBg.lineWidth = 1
            claimBg.glowWidth = 3
            claimBg.name = "claimButton"
            claimBtn.addChild(claimBg)

            let claimText = SKLabelNode(fontNamed: Theme.bodyFont)
            claimText.text = "CLAIM PLANET"
            claimText.fontSize = 11
            claimText.fontColor = Theme.onGreen
            claimText.verticalAlignmentMode = .center
            claimText.name = "claimButton"
            claimBtn.addChild(claimText)

            panel.addChild(claimBtn)
        } else if isCurrentPlanet {
            let currentLabel = SKLabelNode(fontNamed: Theme.captionFont)
            currentLabel.text = "// YOU ARE HERE"
            currentLabel.fontSize = 10
            currentLabel.fontColor = Theme.retroBlue.withAlphaComponent(0.6)
            currentLabel.position = CGPoint(x: 0, y: panelY - 38)
            panel.addChild(currentLabel)
        }

        panel.alpha = 0
        cameraNode.addChild(panel)
        panel.run(SKAction.fadeIn(withDuration: 0.2))
        planetInfoNode = panel
    }

    // MARK: - Notifications

    func showNotification(_ text: String) {
        notificationQueue.append(text)
        if !isShowingNotification { displayNextNotification() }
    }

    func displayNextNotification() {
        guard !notificationQueue.isEmpty else {
            isShowingNotification = false
            return
        }
        isShowingNotification = true
        let text = notificationQueue.removeFirst()

        let notif = SKLabelNode(fontNamed: Theme.captionFont)
        notif.text = "// \(text.uppercased())"
        notif.fontSize = 11
        notif.fontColor = Theme.nasaOrange.withAlphaComponent(0.9)
        notif.position = CGPoint(x: 0, y: size.height * 0.5 - 70)
        notif.zPosition = 110
        notif.alpha = 0
        cameraNode.addChild(notif)

        notif.run(SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.3),
            SKAction.wait(forDuration: 2.0),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent(),
            SKAction.run { [weak self] in self?.displayNextNotification() }
        ]))
    }

}
