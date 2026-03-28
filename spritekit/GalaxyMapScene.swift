//
//  GalaxyMapScene.swift
//  spritekit
//
//  Created by Clifton Baggerman on 28/03/2026.
//

import SpriteKit

class GalaxyMapScene: SKScene {

    var gameState: GameState!

    private var cameraNode: SKCameraNode!
    private var mapNode: SKNode!
    private var planetNodes: [UUID: SKNode] = [:]
    private var shipIcon: SKNode!
    private var selectionRing: SKShapeNode?
    private var selectedPlanetID: UUID?

    // HUD
    private var fuelLabel: SKLabelNode?
    private var creditsLabel: SKLabelNode?
    private var turnLabel: SKLabelNode?
    private var planetInfoNode: SKNode?

    // Interaction
    private var lastPanPoint: CGPoint?
    private var isTravelAnimating = false

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

        // Center camera on player's current planet
        if let currentID = gameState.player.currentPlanetID,
           let planet = gameState.planet(withID: currentID) {
            cameraNode.position = planet.position
        }

        // Add pan gesture
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        view.addGestureRecognizer(pan)
    }

    // MARK: - Route Lines

    private func buildRouteLines() {
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

            // Dashed effect — dots along the route
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

    private func buildPlanets() {
        for planet in gameState.planets {
            let node = SKNode()
            node.position = planet.position
            node.name = "planet_\(planet.id.uuidString)"
            node.zPosition = 5

            // Planet circle
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

            // Planet name
            let label = SKLabelNode(fontNamed: Theme.captionFont)
            label.text = planet.name
            label.fontSize = 9
            label.fontColor = Theme.creamWhite.withAlphaComponent(0.7)
            label.position = CGPoint(x: 0, y: -radius - 14)
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            node.addChild(label)

            // HQ marker
            if planet.isHQ {
                let hqLabel = SKLabelNode(fontNamed: Theme.bodyFont)
                hqLabel.text = "HQ"
                hqLabel.fontSize = 7
                hqLabel.fontColor = Theme.warmGold
                hqLabel.position = CGPoint(x: 0, y: radius + 10)
                hqLabel.verticalAlignmentMode = .center
                node.addChild(hqLabel)
            }

            // Subtle pulse for owned planets
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

    private func factionColor(_ faction: Faction) -> SKColor {
        switch faction {
        case .player:  return Theme.retroBlue
        case .kethari: return Theme.offRed
        case .vossari: return Theme.onGreen
        case .draknor: return Theme.warmGold
        }
    }

    // MARK: - Ship Icon

    private func buildShipIcon() {
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

        // Bob animation
        let bob = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 3, duration: 1.0),
            SKAction.moveBy(x: 0, y: -3, duration: 1.0)
        ])
        ship.run(SKAction.repeatForever(bob))

        shipIcon = ship
        mapNode.addChild(ship)
    }

    // MARK: - HUD

    private func buildHUD() {
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

    private func updateHUD() {
        turnLabel?.text = "TURN \(gameState.turn)"
        fuelLabel?.text = "FUEL \(Int(gameState.player.fuel))"
        creditsLabel?.text = "CR \(gameState.player.credits)"
    }

    // MARK: - Planet Info Panel

    private func showPlanetInfo(_ planet: Planet) {
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

    // MARK: - Travel

    private func travelTo(_ planet: Planet) {
        guard !isTravelAnimating else { return }
        guard let currentID = gameState.player.currentPlanetID else { return }

        let fuelCost = gameState.fuelCost(from: currentID, to: planet.id)
        guard gameState.player.fuel >= fuelCost else { return }

        isTravelAnimating = true
        gameState.player.fuel -= fuelCost
        gameState.player.currentPlanetID = planet.id

        // Track planet ownership before turn
        let ownershipBefore = Dictionary(uniqueKeysWithValues: gameState.planets.map { ($0.id, $0.owner) })

        // Process turn when traveling
        gameState.processTurn()

        // Detect AI captures
        for p in gameState.planets {
            let before = ownershipBefore[p.id] ?? nil
            if p.owner != before && p.owner != .player && p.owner != nil {
                let factionName = FactionData.info(for: p.owner!)?.displayName ?? p.owner!.rawValue.uppercased()
                showNotification("\(factionName) captured \(p.name)")
            }
        }

        // Animate ship travel
        let destination = CGPoint(x: planet.positionX, y: planet.positionY + 24)
        let cameraDestination = planet.position

        shipIcon.removeAllActions()

        let travelDuration = 0.8
        let moveShip = SKAction.move(to: destination, duration: travelDuration)
        moveShip.timingMode = .easeInEaseOut

        let moveCamera = SKAction.move(to: cameraDestination, duration: travelDuration)
        moveCamera.timingMode = .easeInEaseOut

        shipIcon.run(moveShip)
        cameraNode.run(moveCamera) { [weak self] in
            guard let self else { return }
            self.isTravelAnimating = false

            // Restart bob
            let bob = SKAction.sequence([
                SKAction.moveBy(x: 0, y: 3, duration: 1.0),
                SKAction.moveBy(x: 0, y: -3, duration: 1.0)
            ])
            self.shipIcon.run(SKAction.repeatForever(bob))

            self.updateHUD()
            self.updateSelectionRing(planet.id)

            // If planet is not owned by player, trigger combat
            if planet.owner != .player && planet.owner != nil {
                self.enterCombat(for: planet)
            } else if planet.owner == nil {
                // Unclaimed — light resistance combat
                self.enterCombat(for: planet)
            } else {
                self.showPlanetInfo(planet)
            }
        }

        // Dismiss info panel during travel
        planetInfoNode?.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.15),
            SKAction.removeFromParent()
        ]))
        planetInfoNode = nil
    }

    // MARK: - Selection Ring

    private func updateSelectionRing(_ planetID: UUID) {
        selectionRing?.removeFromParent()

        guard let node = planetNodes[planetID] else { return }

        let ring = SKShapeNode(circleOfRadius: 22)
        ring.strokeColor = Theme.creamWhite.withAlphaComponent(0.4)
        ring.fillColor = .clear
        ring.lineWidth = 1
        ring.glowWidth = 3
        ring.zPosition = 4

        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.2, duration: 1.0),
            SKAction.fadeAlpha(to: 0.5, duration: 1.0)
        ])
        ring.run(SKAction.repeatForever(pulse))

        node.addChild(ring)
        selectionRing = ring
        selectedPlanetID = planetID
    }

    // MARK: - Pan Gesture

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard !isTravelAnimating else { return }

        let translation = gesture.translation(in: view)

        switch gesture.state {
        case .changed:
            cameraNode.position.x -= translation.x
            cameraNode.position.y += translation.y
            gesture.setTranslation(.zero, in: view)
        default:
            break
        }
    }

    // MARK: - Touch

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, !isTravelAnimating else { return }
        let locationInScene = touch.location(in: self)
        let locationInCamera = touch.location(in: cameraNode)
        let tappedNodes = nodes(at: locationInScene)

        // Check HUD buttons first (in camera space)
        let hudNodes = cameraNode.nodes(at: locationInCamera)
        for node in hudNodes where node.name == "menuButton" {
            let menu = GameScene(size: size)
            menu.scaleMode = .resizeFill
            view?.presentScene(menu, transition: SKTransition.fade(withDuration: 0.6))
            return
        }

        // Check travel button
        for node in hudNodes where node.name == "travelButton" {
            if let selectedID = selectedPlanetID,
               let planet = gameState.planet(withID: selectedID) {
                travelTo(planet)
            }
            return
        }

        // Check manage planet button
        for node in hudNodes where node.name == "manageButton" {
            if let selectedID = selectedPlanetID {
                openPlanetDetail(selectedID)
            }
            return
        }

        // Check planet taps
        for node in tappedNodes {
            guard let name = node.name, name.hasPrefix("planet_") else { continue }
            let uuidString = String(name.dropFirst(7))
            guard let id = UUID(uuidString: uuidString),
                  let planet = gameState.planet(withID: id) else { continue }

            updateSelectionRing(id)
            showPlanetInfo(planet)
            return
        }

        // Tap on empty space — dismiss info
        planetInfoNode?.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.15),
            SKAction.removeFromParent()
        ]))
        planetInfoNode = nil
        selectionRing?.removeFromParent()
        selectedPlanetID = nil
    }

    // MARK: - Combat

    private func enterCombat(for planet: Planet) {
        let context = CombatContext.forPlanet(planet)

        let combat = GameplayScene(size: size)
        combat.scaleMode = .resizeFill
        combat.combatContext = context
        combat.gameState = gameState

        combat.onCombatComplete = { [weak self] result in
            guard let self else { return }

            switch result {
            case .victory:
                // Capture planet only if player has troop transports
                let hasTransport = self.gameState.player.shipCount(for: .troopTransport) > 0
                if hasTransport {
                    if var p = self.gameState.planet(withID: planet.id) {
                        p.owner = .player
                        self.gameState.updatePlanet(p)
                    }
                    // Consume one troop transport
                    self.gameState.player.removeShip(.troopTransport)
                }
                // Award rewards regardless
                self.gameState.player.credits += context.creditsReward
                self.gameState.player.minerals += context.mineralsReward

            case .retreat:
                // Return to previous planet (stay at current — already moved)
                break

            case .defeat:
                // Lost the fight — stay at the planet but don't capture
                break
            }

            // Return to galaxy map
            let galaxyMap = GalaxyMapScene(size: self.size)
            galaxyMap.scaleMode = .resizeFill
            galaxyMap.gameState = self.gameState
            self.view?.presentScene(galaxyMap, transition: SKTransition.fade(withDuration: 0.6))
        }

        view?.presentScene(combat, transition: SKTransition.fade(withDuration: 0.6))
    }

    // MARK: - Planet Detail

    private func openPlanetDetail(_ planetID: UUID) {
        let detail = PlanetDetailScene(size: size)
        detail.scaleMode = .resizeFill
        detail.gameState = gameState
        detail.planetID = planetID
        view?.presentScene(detail, transition: SKTransition.fade(withDuration: 0.4))
    }

    // MARK: - Notifications

    private var notificationQueue: [String] = []
    private var isShowingNotification = false

    private func showNotification(_ text: String) {
        notificationQueue.append(text)
        if !isShowingNotification { displayNextNotification() }
    }

    private func displayNextNotification() {
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

    // MARK: - Update

    override func update(_ currentTime: TimeInterval) {
        // Future: animations, AI processing indicators
    }
}
