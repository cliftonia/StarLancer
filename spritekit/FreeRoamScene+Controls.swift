//
//  FreeRoamScene+Controls.swift
//  spritekit
//
//  Ship movement, proximity detection, docking, touch handling, update loop.
//

import SpriteKit
import CoreMotion

extension FreeRoamScene {

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, !isTransitioning else { return }
        let location = touch.location(in: self)
        let cameraLocation = touch.location(in: cameraNode)
        let hudNodes = cameraNode.nodes(at: cameraLocation)

        // HUD button checks
        for node in hudNodes {
            switch node.name {
            case "mapButton":
                openMap()
                return
            case "dockButton":
                dockAtNearbyPlanet()
                return
            default:
                break
            }
        }

        isTouching = true
        touchLocation = location
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        touchLocation = touch.location(in: self)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouching = false
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouching = false
    }

    // MARK: - Update Loop

    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 { lastUpdateTime = currentTime }
        let dt = currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        guard !isTransitioning else { return }

        updateShipMovement(dt: dt)
        updateCamera()
        checkPlanetProximity()
        drainFuel(dt: dt)
        updateHUD()
    }

    // MARK: - Ship Movement

    func updateShipMovement(dt: TimeInterval) {
        guard let ship = playerShip else { return }

        var accelX: CGFloat = 0
        var accelY: CGFloat = 0

        // Gyroscope input
        if let motion = motionManager.deviceMotion {
            accelX += CGFloat(motion.attitude.roll) * 300
            accelY += CGFloat(motion.attitude.pitch - 0.6) * 200
        }

        // Touch input — accelerate toward touch
        if isTouching {
            let worldTouch = convert(touchLocation, to: worldNode)
            let diff = CGPoint(x: worldTouch.x - ship.position.x, y: worldTouch.y - ship.position.y)
            let dist = hypot(diff.x, diff.y)
            if dist > 10 {
                accelX += diff.x / dist * 200
                accelY += diff.y / dist * 200
            }
        }

        // Apply acceleration to velocity with damping
        shipVelocity.dx += accelX * CGFloat(dt)
        shipVelocity.dy += accelY * CGFloat(dt)

        // Damping (ship slows when no input)
        let damping: CGFloat = 0.97
        shipVelocity.dx *= damping
        shipVelocity.dy *= damping

        // Speed cap
        let speed = hypot(shipVelocity.dx, shipVelocity.dy)
        let maxSpeed: CGFloat = 200
        if speed > maxSpeed {
            shipVelocity.dx = shipVelocity.dx / speed * maxSpeed
            shipVelocity.dy = shipVelocity.dy / speed * maxSpeed
        }

        // Update position
        ship.position.x += shipVelocity.dx * CGFloat(dt)
        ship.position.y += shipVelocity.dy * CGFloat(dt)

        // World bounds
        let margin: CGFloat = 30
        ship.position.x = max(margin, min(worldWidth - margin, ship.position.x))
        ship.position.y = max(margin, min(worldHeight - margin, ship.position.y))

        // Rotate ship to face movement direction
        if speed > 10 {
            let targetAngle = atan2(shipVelocity.dy, shipVelocity.dx) - .pi / 2
            let angleDiff = targetAngle - ship.zRotation
            let normalized = atan2(sin(angleDiff), cos(angleDiff))
            ship.zRotation += normalized * 0.1 // Smooth rotation
        }

        // Save position to game state
        gameState.player.shipX = Double(ship.position.x)
        gameState.player.shipY = Double(ship.position.y)
    }

    // MARK: - Camera

    func updateCamera() {
        guard let ship = playerShip else { return }
        // Smooth camera follow
        let lerpSpeed: CGFloat = 0.08
        cameraNode.position.x += (ship.position.x - cameraNode.position.x) * lerpSpeed
        cameraNode.position.y += (ship.position.y - cameraNode.position.y) * lerpSpeed
    }

    // MARK: - Planet Proximity

    func checkPlanetProximity() {
        guard let ship = playerShip else { return }

        var closestID: UUID?
        var closestDist: CGFloat = .infinity

        for planet in gameState.planets {
            let dx = CGFloat(planet.positionX) - ship.position.x
            let dy = CGFloat(planet.positionY) - ship.position.y
            let dist = hypot(dx, dy)

            if dist < dockingRadius && dist < closestDist {
                closestDist = dist
                closestID = planet.id
            }
        }

        if closestID != nearbyPlanetID {
            nearbyPlanetID = closestID
            if let id = closestID, let planet = gameState.planet(withID: id) {
                showDockPrompt(for: planet)
            } else {
                hideDockPrompt()
            }
        }
    }

    // MARK: - Dock Prompt

    func showDockPrompt(for planet: Planet) {
        hideDockPrompt()

        let prompt = SKNode()
        prompt.zPosition = 80
        prompt.name = "dockPromptNode"

        let bg = SKShapeNode(rectOf: CGSize(width: 200, height: 40), cornerRadius: 4)
        bg.fillColor = SKColor.black.withAlphaComponent(0.7)
        bg.strokeColor = Theme.nasaOrange.withAlphaComponent(0.5)
        bg.lineWidth = 1
        bg.glowWidth = 3
        bg.name = "dockButton"
        prompt.addChild(bg)

        let ownerText: String
        if planet.owner == .player {
            ownerText = "DOCK AT \(planet.name)"
        } else if planet.owner != nil {
            ownerText = "ENGAGE \(planet.name)"
        } else {
            ownerText = "CLAIM \(planet.name)"
        }

        let label = SKLabelNode(fontNamed: Theme.bodyFont)
        label.text = ownerText
        label.fontSize = 12
        label.fontColor = Theme.nasaOrange
        label.verticalAlignmentMode = .center
        label.name = "dockButton"
        prompt.addChild(label)

        prompt.position = CGPoint(x: 0, y: -size.height * 0.5 + 100)
        prompt.alpha = 0
        cameraNode.addChild(prompt)
        prompt.run(SKAction.fadeIn(withDuration: 0.2))

        dockPrompt = prompt
        GameFeedback.lightImpact()
    }

    func hideDockPrompt() {
        dockPrompt?.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.15),
            SKAction.removeFromParent()
        ]))
        dockPrompt = nil
    }

    // MARK: - Docking

    func dockAtNearbyPlanet() {
        guard let planetID = nearbyPlanetID,
              let planet = gameState.planet(withID: planetID) else { return }

        isTransitioning = true
        gameState.player.currentPlanetID = planetID
        gameState.processTurn()
        SaveManager.save(gameState)

        GameFeedback.mediumImpact()

        if planet.owner == .player {
            // Collect resources and open planet management
            collectResources(from: planet)
            let detail = PlanetDetailScene(size: size)
            detail.scaleMode = .resizeFill
            detail.gameState = gameState
            detail.planetID = planetID
            view?.presentScene(detail, transition: SKTransition.fade(withDuration: 0.5))

        } else if planet.owner != nil {
            // Enemy planet — combat
            let context = CombatContext.forPlanet(planet)
            let combat = GameplayScene(size: size)
            combat.scaleMode = .resizeFill
            combat.combatContext = context
            combat.gameState = gameState

            combat.onCombatComplete = { [weak self] result in
                guard let self else { return }
                self.handleCombatResult(result, for: planet, context: context)
            }

            view?.presentScene(combat, transition: SKTransition.fade(withDuration: 0.6))

        } else {
            // Unclaimed — claim it
            if var p = gameState.planet(withID: planetID) {
                p.owner = .player
                gameState.updatePlanet(p)
                SaveManager.save(gameState)
            }

            // Refresh scene at new position
            let roam = FreeRoamScene(size: size)
            roam.scaleMode = .resizeFill
            roam.gameState = gameState
            view?.presentScene(roam, transition: SKTransition.fade(withDuration: 0.3))
        }
    }

    func collectResources(from planet: Planet) {
        guard var p = gameState.planet(withID: planet.id), p.owner == .player else { return }

        gameState.player.credits += p.credits
        gameState.player.minerals += p.minerals
        p.credits = 0
        p.minerals = 0
        gameState.updatePlanet(p)

        if p.factories > 0 {
            let fuelRestored = min(100 - gameState.player.fuel, Double(p.factories) * 10)
            gameState.player.fuel += fuelRestored
        }
    }

    func handleCombatResult(_ result: CombatResult, for planet: Planet, context: CombatContext) {
        if result == .victory {
            let hasTransport = gameState.player.shipCount(for: .troopTransport) > 0
            if hasTransport {
                if var p = gameState.planet(withID: planet.id) {
                    p.owner = .player
                    gameState.updatePlanet(p)
                }
                gameState.player.removeShip(.troopTransport)
            }
            gameState.player.credits += context.creditsReward
            gameState.player.minerals += context.mineralsReward
        }

        SaveManager.save(gameState)

        // Return to free roam
        let roam = FreeRoamScene(size: size)
        roam.scaleMode = .resizeFill
        roam.gameState = gameState
        view?.presentScene(roam, transition: SKTransition.fade(withDuration: 0.5))
    }

    // MARK: - Fuel Drain

    func drainFuel(dt: TimeInterval) {
        let speed = hypot(shipVelocity.dx, shipVelocity.dy)
        guard speed > 15 else { return } // Only drain while actively moving

        fuelDrainTimer += dt
        if fuelDrainTimer > 1.0 {
            fuelDrainTimer = 0
            gameState.player.fuel = max(0, gameState.player.fuel - 0.5)
        }
    }

    // MARK: - Open Map

    func openMap() {
        isTransitioning = true
        let map = GalaxyMapScene(size: size)
        map.scaleMode = .resizeFill
        map.gameState = gameState
        view?.presentScene(map, transition: SKTransition.fade(withDuration: 0.4))
    }
}
