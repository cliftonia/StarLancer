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
