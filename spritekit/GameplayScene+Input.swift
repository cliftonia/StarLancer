//
//  GameplayScene+Input.swift
//  spritekit
//

import SpriteKit

extension GameplayScene {

        // Return to menu button
        let returnBtn = SKNode()
        returnBtn.name = "returnButton"
        returnBtn.position = CGPoint(x: size.width * 0.5, y: size.height * 0.38)

        let btnBg = SKShapeNode(rectOf: CGSize(width: 200, height: 42), cornerRadius: 3)
        btnBg.fillColor = SKColor(red: 0.06, green: 0.06, blue: 0.1, alpha: 0.8)
        btnBg.strokeColor = creamWhite.withAlphaComponent(0.4)
        btnBg.lineWidth = 1
        btnBg.glowWidth = 2
        btnBg.name = "returnButton"
        returnBtn.addChild(btnBg)

        let accent = SKShapeNode(rectOf: CGSize(width: 3, height: 42))
        accent.fillColor = nasaOrange
        accent.strokeColor = .clear
        accent.glowWidth = 3
        accent.position = CGPoint(x: -98.5, y: 0)
        accent.name = "returnButton"
        returnBtn.addChild(accent)

        let btnLabel = SKLabelNode(fontNamed: "Courier-Bold")
        btnLabel.text = "RETURN TO BASE"
        btnLabel.fontSize = 14
        btnLabel.fontColor = creamWhite
        btnLabel.verticalAlignmentMode = .center
        btnLabel.name = "returnButton"
        returnBtn.addChild(btnLabel)

        gameOverNode.addChild(returnBtn)

        addChild(gameOverNode)
        gameOverNode.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.fadeIn(withDuration: 0.8)
        ]))
    }

    // MARK: - Collisions

    func didBegin(_ contact: SKPhysicsContact) {
        let a = contact.bodyA
        let b = contact.bodyB

        let masks = (a.categoryBitMask, b.categoryBitMask)

        switch masks {
        // Bullet hits asteroid
        case (Category.bullet, Category.asteroid), (Category.asteroid, Category.bullet):
            let bullet = masks.0 == Category.bullet ? a.node : b.node
            let asteroid = masks.0 == Category.asteroid ? a.node : b.node
            let pos = asteroid?.position ?? contact.contactPoint
            bullet?.removeFromParent()
            asteroid?.removeFromParent()
            spawnExplosion(at: pos, color: warmGold, count: 8)
            score += 10
            if Bool.random() { spawnLoot(at: pos) }

        // Bullet hits enemy
        case (Category.bullet, Category.enemy), (Category.enemy, Category.bullet):
            let bullet = masks.0 == Category.bullet ? a.node : b.node
            let enemy = masks.0 == Category.enemy ? a.node : b.node
            let pos = enemy?.position ?? contact.contactPoint
            bullet?.removeFromParent()
            enemy?.removeFromParent()
            spawnExplosion(at: pos, color: SKColor(red: 1, green: 0.3, blue: 0.1, alpha: 1), count: 15)
            score += 50
            spawnLoot(at: pos)
            onEnemyDestroyed()

        // Player hits asteroid
        case (Category.player, Category.asteroid), (Category.asteroid, Category.player):
            let asteroid = masks.0 == Category.asteroid ? a.node : b.node
            let pos = asteroid?.position ?? contact.contactPoint
            asteroid?.removeFromParent()
            spawnExplosion(at: pos, color: hullGray, count: 6)
            takeDamage(20)

        // Player hits enemy
        case (Category.player, Category.enemy), (Category.enemy, Category.player):
            let enemy = masks.0 == Category.enemy ? a.node : b.node
            let pos = enemy?.position ?? contact.contactPoint
            enemy?.removeFromParent()
            spawnExplosion(at: pos, color: nasaOrange, count: 12)
            takeDamage(30)

        // Enemy bullet hits player
        case (Category.player, Category.enemyFire), (Category.enemyFire, Category.player):
            let bullet = masks.0 == Category.enemyFire ? a.node : b.node
            bullet?.removeFromParent()
            takeDamage(15)

        // Player picks up loot
        case (Category.player, Category.loot), (Category.loot, Category.player):
            let loot = masks.0 == Category.loot ? a.node : b.node
            if let name = loot?.name {
                if name.contains("CR") { credits += Int.random(in: 5...25) }
                if name.contains("HP") { health = min(100, health + 20) }
                if name.contains("SH") { shieldHP = min(100, shieldHP + 25) }
                if name.contains("FU") { fuel = min(100, fuel + 15) }
            }
            loot?.removeFromParent()

        default:
            break
        }

        updateHUD()
    }

    // MARK: - Touch

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        // Check for buttons on game over / victory
        if isGameOver {
            let tapped = nodes(at: location)
            for node in tapped {
                switch node.name {
                case "returnButton":
                    if isWaveBased {
                        onCombatComplete?(.defeat)
                    } else {
                        let menu = GameScene(size: size)
                        menu.scaleMode = .resizeFill
                        view?.presentScene(menu, transition: SKTransition.fade(withDuration: 0.6))
                    }
                    return
                case "victoryButton":
                    onCombatComplete?(.victory)
                    return
                default:
                    break
                }
            }
            return
        }

        // Pause/Resume/Quit buttons
        let tapped = nodes(at: location)
        for node in tapped {
            switch node.name {
            case "pauseButton":
                togglePause()
                return
            case "resumeButton":
                togglePause()
                return
            case "quitButton":
                scene?.isPaused = false
                if isWaveBased {
                    onCombatComplete?(.retreat)
                } else {
                    let menu = GameScene(size: size)
                    menu.scaleMode = .resizeFill
                    view?.presentScene(menu, transition: SKTransition.fade(withDuration: 0.6))
                }
                return
            case "retreatButton":
                onCombatComplete?(.retreat)
                return
            default:
                break
            }
        }

        guard !isPaused2 else { return }

        isTouching = true
        touchLocation = location
        fireBullet()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, !isGameOver else { return }
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

        guard !isGameOver else { return }

        // Move ship with gyro + touch
        updatePlayerMovement(dt: dt)

        // Auto-fire while touching (fleet fighters increase rate)
        if isTouching {
            let fireRate = 0.2 * fireRateMultiplier
            if currentTime.truncatingRemainder(dividingBy: fireRate) < dt {
                fireBullet()
            }
        }

        // Missile carriers fire homing missiles
        if missileCarrierCount > 0 {
            missileTimer += dt
            let missileInterval = max(1.0, 3.0 / Double(missileCarrierCount))
            if missileTimer > missileInterval {
                missileTimer = 0
                spawnHomingMissile()
            }
        }

        // Fuel drain (only in endless/non-wave mode)
        if !isWaveBased {
            fuelTimer += dt
            if fuelTimer > 0.5 {
                fuelTimer = 0
                fuel = max(0, fuel - 0.3)
                if fuel <= 0 { gameOver() }
            }
        }

        // Spawn asteroids (environmental hazard in both modes)
        asteroidTimer += dt
        let asteroidInterval = isWaveBased ? 2.5 : max(0.4, 1.5 - Double(score) / 500.0)
        if asteroidTimer > asteroidInterval {
            asteroidTimer = 0
            spawnAsteroid()
        }

        // Spawn enemies (only in endless mode — wave mode uses startNextWave)
        if !isWaveBased {
            enemyTimer += dt
            let enemyInterval = max(2.0, 6.0 - Double(score) / 200.0)
            if enemyTimer > enemyInterval {
                enemyTimer = 0
                spawnEnemy()
            }
        }

        // Cleanup off-screen nodes
        enumerateChildNodes(withName: "asteroid") { node, _ in
            if node.position.y < -50 { node.removeFromParent() }
        }
        enumerateChildNodes(withName: "bullet") { node, _ in
            if node.position.y > self.size.height + 20 { node.removeFromParent() }
        }
        enumerateChildNodes(withName: "enemyBullet") { node, _ in
            if node.position.y < -20 { node.removeFromParent() }
        }
        enumerateChildNodes(withName: "enemy") { node, _ in
            if node.position.y < -50 { node.removeFromParent() }
        }
        for name in ["loot_CR", "loot_HP", "loot_SH", "loot_FU"] {
            enumerateChildNodes(withName: name) { node, _ in
                if node.position.y < -20 { node.removeFromParent() }
            }
        }

        updateHUD()
    }

    func updatePlayerMovement(dt: TimeInterval) {
        guard let ship = playerShip else { return }

        var dx: CGFloat = 0
        var dy: CGFloat = 0

        // Gyroscope tilt
        if let motion = motionManager.deviceMotion {
            let tiltX = CGFloat(motion.attitude.roll) * 400
            let tiltY = CGFloat(motion.attitude.pitch - 0.6) * 300
            dx += tiltX
            dy += tiltY
        }

        // Touch influence — ship drifts toward touch
        if isTouching {
            let target = touchLocation
            let diff = CGPoint(x: target.x - ship.position.x, y: target.y - ship.position.y)
            dx += diff.x * 2.5
            dy += diff.y * 2.5
        }

        shipSpeed = sqrt(dx * dx + dy * dy) * 0.01

        let newX = ship.position.x + dx * CGFloat(dt)
        let newY = ship.position.y + dy * CGFloat(dt)

        ship.position.x = max(20, min(size.width - 20, newX))
        ship.position.y = max(40, min(size.height - 80, newY))

        // Tilt ship visually
        let tiltAngle = -dx * 0.0005
        ship.zRotation = max(-.pi * 0.15, min(.pi * 0.15, tiltAngle))
    }
}
}
