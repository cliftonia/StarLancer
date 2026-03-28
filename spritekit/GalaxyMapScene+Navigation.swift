//
//  GalaxyMapScene+Navigation.swift
//  spritekit
//

import SpriteKit

extension GalaxyMapScene {

    // MARK: - Travel

    func travelTo(_ planet: Planet) {
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
            let before = ownershipBefore[p.id]
            if p.owner != before && p.owner != .player && p.owner != nil {
                let factionName = FactionData.info(for: p.owner!)?.displayName ?? p.owner!.rawValue.uppercased()
                showNotification("\(factionName) captured \(p.name)")
            }
        }

        // Random travel events (20% chance)
        if Double.random(in: 0...1) < 0.2 {
            triggerTravelEvent()
        }

        // Save after turn
        SaveManager.save(gameState)

        // Check win/lose conditions after travel animation completes
        if gameState.playerHasLost {
            run(SKAction.sequence([
                SKAction.wait(forDuration: 1.5),
                SKAction.run { [weak self] in self?.showEndScreen(victory: false) }
            ]))
            return
        }
        if gameState.playerHasWon {
            run(SKAction.sequence([
                SKAction.wait(forDuration: 1.5),
                SKAction.run { [weak self] in self?.showEndScreen(victory: true) }
            ]))
            return
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

        // Update ship world position for free-roam
        gameState.player.shipX = planet.positionX
        gameState.player.shipY = planet.positionY

        shipIcon.run(moveShip)
        cameraNode.run(moveCamera) { [weak self] in
            guard let self else { return }

            // Return to free-roam at destination
            let roam = FreeRoamScene(size: self.size)
            roam.scaleMode = .resizeFill
            roam.gameState = self.gameState
            self.view?.presentScene(roam, transition: SKTransition.fade(withDuration: 0.4))
        }

        // Dismiss info panel during travel
        planetInfoNode?.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.15),
            SKAction.removeFromParent()
        ]))
        planetInfoNode = nil
    }

    // MARK: - Selection Ring

    func updateSelectionRing(_ planetID: UUID) {
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

    // MARK: - Gestures

    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard !isTravelAnimating else { return }

        let translation = gesture.translation(in: view)

        switch gesture.state {
        case .changed:
            let scale = cameraNode.xScale
            cameraNode.position.x -= translation.x * scale
            cameraNode.position.y += translation.y * scale
            gesture.setTranslation(.zero, in: view)
        default:
            break
        }
    }

    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard !isTravelAnimating else { return }

        switch gesture.state {
        case .changed:
            let newScale = cameraNode.xScale / gesture.scale
            let clamped = max(0.5, min(2.5, newScale))
            cameraNode.setScale(clamped)
            gesture.scale = 1.0
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
        for node in hudNodes where node.name == "backToShipButton" {
            let roam = FreeRoamScene(size: size)
            roam.scaleMode = .resizeFill
            roam.gameState = gameState
            view?.presentScene(roam, transition: SKTransition.fade(withDuration: 0.4))
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

        // Check claim planet button
        for node in hudNodes where node.name == "claimButton" {
            if let selectedID = selectedPlanetID {
                claimPlanet(selectedID)
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

    // MARK: - Travel Events

    func triggerTravelEvent() {
        let events: [(message: String, effect: () -> Void)] = [
            ("ASTEROID FIELD — hull damage, -10 fuel", { [self] in
                gameState.player.fuel = max(0, gameState.player.fuel - 10)
            }),
            ("DISTRESS SIGNAL — rescued crew, +30 CR", { [self] in
                gameState.player.credits += 30
            }),
            ("ABANDONED FUEL CACHE — +15 fuel", { [self] in
                gameState.player.fuel = min(100, gameState.player.fuel + 15)
            }),
            ("DERELICT SHIP — salvaged +20 minerals", { [self] in
                gameState.player.minerals += 20
            }),
            ("SOLAR FLARE — shields disrupted, systems nominal", {
                // Flavor event — no gameplay effect
            }),
            ("DEEP SPACE SIGNAL — coordinates updated", {
                // Flavor event
            })
        ]

        let event = events.randomElement()!
        event.effect()
        showNotification(event.message)
        updateHUD()
    }

    // MARK: - Resource Collection & Refuel

    func collectFromPlanet(_ planet: Planet) {
        guard var p = gameState.planet(withID: planet.id), p.owner == .player else { return }

        // Transfer planet's accumulated resources to player
        let crCollected = p.credits
        let minCollected = p.minerals

        if crCollected > 0 || minCollected > 0 {
            gameState.player.credits += crCollected
            gameState.player.minerals += minCollected
            p.credits = 0
            p.minerals = 0
            gameState.updatePlanet(p)

            var parts: [String] = []
            if crCollected > 0 { parts.append("+\(crCollected) CR") }
            if minCollected > 0 { parts.append("+\(minCollected) MIN") }
            showNotification("COLLECTED: \(parts.joined(separator: "  "))")
        }

        // Refuel at planets with factories (fuel depots)
        if p.factories > 0 {
            let fuelRestored = min(100 - gameState.player.fuel, Double(p.factories) * 10)
            if fuelRestored > 0 {
                gameState.player.fuel += fuelRestored
                showNotification("REFUELED: +\(Int(fuelRestored)) FUEL")
            }
        }

        updateHUD()
    }

    // MARK: - Claim Unclaimed Planet

    func claimPlanet(_ planetID: UUID) {
        guard var planet = gameState.planet(withID: planetID),
              planet.owner == nil else { return }

        planet.owner = .player
        gameState.updatePlanet(planet)
        SaveManager.save(gameState)

        // Refresh the map to show updated ownership
        let galaxyMap = GalaxyMapScene(size: size)
        galaxyMap.scaleMode = .resizeFill
        galaxyMap.gameState = gameState
        view?.presentScene(galaxyMap, transition: SKTransition.fade(withDuration: 0.3))
    }

    // MARK: - End Screen

    func showEndScreen(victory: Bool) {
        let endScene = VictoryScene(size: size)
        endScene.scaleMode = .resizeFill
        endScene.isVictory = victory
        endScene.gameState = gameState
        view?.presentScene(endScene, transition: SKTransition.fade(withDuration: 0.8))
    }

    // MARK: - Combat

    func enterCombat(for planet: Planet) {
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

    func openPlanetDetail(_ planetID: UUID) {
        let detail = PlanetDetailScene(size: size)
        detail.scaleMode = .resizeFill
        detail.gameState = gameState
        detail.planetID = planetID
        view?.presentScene(detail, transition: SKTransition.fade(withDuration: 0.4))
    }

    // MARK: - Update

    override func update(_ currentTime: TimeInterval) {
        // Future: animations, AI processing indicators
    }
}
