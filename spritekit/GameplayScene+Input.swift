//
//  GameplayScene+Input.swift
//  spritekit
//

import SpriteKit

extension GameplayScene {

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
            GameFeedback.lightImpact()

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

        // Check all interactive buttons
        let tapped = nodes(at: location)
        for node in tapped {
            switch node.name {
            case "engageButton":
                dismissBriefing()
                return
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

        // Don't process gameplay input while paused
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

        guard !isGameOver, !isPaused2 else { return }

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

}
