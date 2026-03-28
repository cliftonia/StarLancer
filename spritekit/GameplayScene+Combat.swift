//
//  GameplayScene+Combat.swift
//  spritekit
//

import SpriteKit
import CoreMotion

extension GameplayScene {

    // MARK: - Fleet Modifiers

    func applyFleetModifiers() {
        guard let state = gameState else { return }

        let fighters = state.player.shipCount(for: .fighter)
        let destroyers = state.player.shipCount(for: .destroyer)
        let bombers = state.player.shipCount(for: .bomber)
        let missiles = state.player.shipCount(for: .missileCarrier)
        let transports = state.player.shipCount(for: .troopTransport)

        // Fighters: each adds 15% fire rate
        fireRateMultiplier = 1.0 / (1.0 + Double(fighters) * 0.15)

        // Destroyers: each adds 20 HP
        bonusHP = destroyers * 20
        health += bonusHP

        // Bombers: weapon upgrade (1 = dual, 2+ = spread)
        weaponLevel = min(2, bombers)

        // Missile carriers: spawn homing missiles periodically
        missileCarrierCount = missiles

        // Troop transports: required for planet capture
        hasTroopTransport = transports > 0
    }

    func spawnHomingMissile() {
        guard let ship = playerShip, !isGameOver else { return }

        // Find nearest enemy
        var nearestEnemy: SKNode?
        var nearestDist = CGFloat.infinity

        enumerateChildNodes(withName: "enemy") { node, _ in
            let dist = hypot(node.position.x - ship.position.x, node.position.y - ship.position.y)
            if dist < nearestDist {
                nearestDist = dist
                nearestEnemy = node
            }
        }

        guard let target = nearestEnemy else { return }

        let missile = SKShapeNode(circleOfRadius: 4)
        missile.fillColor = Theme.warmGold
        missile.strokeColor = .clear
        missile.glowWidth = 6
        missile.position = CGPoint(x: ship.position.x, y: ship.position.y + 20)
        missile.zPosition = 9
        missile.name = "bullet"

        missile.physicsBody = SKPhysicsBody(circleOfRadius: 4)
        missile.physicsBody?.categoryBitMask = Category.bullet
        missile.physicsBody?.contactTestBitMask = Category.asteroid | Category.enemy
        missile.physicsBody?.collisionBitMask = 0
        missile.physicsBody?.isDynamic = true
        missile.physicsBody?.linearDamping = 0

        // Aim toward target
        let dx = target.position.x - ship.position.x
        let dy = target.position.y - ship.position.y
        let dist = hypot(dx, dy)
        let speed: CGFloat = 400
        missile.physicsBody?.velocity = CGVector(dx: dx / dist * speed, dy: dy / dist * speed)

        addChild(missile)

        // Trail effect
        missile.run(SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Wave Management

    func startNextWave() {
        guard !isGameOver else { return }
        currentWave += 1

        if currentWave > totalWaves {
            combatVictory()
            return
        }

        waveInProgress = true
        let difficultyMul = combatContext?.difficultyMultiplier ?? 1.0
        let enemyCount = 2 + currentWave + Int(difficultyMul)
        enemiesRemainingInWave = enemyCount

        // Announce wave
        waveLabel?.text = "WAVE \(currentWave)/\(totalWaves)"
        updateWaveProgressBar()

        let announcement = SKLabelNode(fontNamed: "Helvetica-Bold")
        announcement.text = "WAVE \(currentWave)"
        announcement.fontSize = 40
        announcement.fontColor = nasaOrange
        announcement.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        announcement.zPosition = 45
        announcement.alpha = 0
        addChild(announcement)

        announcement.run(SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.3),
            SKAction.wait(forDuration: 0.8),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))

        // Final wave spawns a boss + fewer regular enemies
        let isFinalWave = currentWave == totalWaves
        if isFinalWave {
            announcement.text = "FINAL WAVE"
            announcement.fontColor = Theme.offRed

            // Boss appears after a delay
            run(SKAction.sequence([
                SKAction.wait(forDuration: 1.5),
                SKAction.run { [weak self] in self?.spawnBoss() }
            ]))
            enemiesRemainingInWave = enemyCount + 1 // +1 for boss
        }

        // Spawn regular enemies for this wave with delay
        for i in 0..<enemyCount {
            run(SKAction.sequence([
                SKAction.wait(forDuration: Double(i) * 0.8 + 0.5),
                SKAction.run { [weak self] in self?.spawnEnemy() }
            ]))
        }
    }

    func onEnemyDestroyed() {
        guard isWaveBased, waveInProgress else { return }
        enemiesRemainingInWave -= 1

        if enemiesRemainingInWave <= 0 {
            waveInProgress = false
            GameFeedback.success()
            showWaveClearBanner()

            // Delay before next wave
            run(SKAction.sequence([
                SKAction.wait(forDuration: 3.0),
                SKAction.run { [weak self] in self?.startNextWave() }
            ]))
        }
    }

    func showWaveClearBanner() {
        let banner = SKNode()
        banner.zPosition = 35
        banner.alpha = 0

        let text = SKLabelNode(fontNamed: "Helvetica-Bold")
        text.text = "WAVE CLEAR"
        text.fontSize = 28
        text.fontColor = Theme.onGreen
        text.position = CGPoint(x: size.width * 0.5, y: size.height * 0.55)
        banner.addChild(text)

        let bonus = SKLabelNode(fontNamed: Theme.captionFont)
        bonus.text = "HULL \(health)%  SHIELD \(shieldHP)"
        bonus.fontSize = 12
        bonus.fontColor = Theme.creamWhite.withAlphaComponent(0.7)
        bonus.position = CGPoint(x: size.width * 0.5, y: size.height * 0.55 - 25)
        banner.addChild(bonus)

        if currentWave < totalWaves {
            let next = SKLabelNode(fontNamed: Theme.captionFont)
            next.text = "NEXT WAVE INCOMING..."
            next.fontSize = 10
            next.fontColor = nasaOrange.withAlphaComponent(0.6)
            next.position = CGPoint(x: size.width * 0.5, y: size.height * 0.55 - 45)
            banner.addChild(next)
        }

        addChild(banner)
        banner.run(SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.3),
            SKAction.wait(forDuration: 2.0),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ]))
    }

    func combatVictory() {
        isGameOver = true
        motionManager.stopDeviceMotionUpdates()

        let overlay = SKShapeNode(rectOf: size)
        overlay.fillColor = SKColor.black.withAlphaComponent(0.5)
        overlay.strokeColor = .clear
        overlay.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        overlay.zPosition = 70
        overlay.alpha = 0
        addChild(overlay)
        overlay.run(SKAction.fadeAlpha(to: 0.5, duration: 0.5))

        let victoryNode = SKNode()
        victoryNode.zPosition = 80
        victoryNode.alpha = 0

        let title = SKLabelNode(fontNamed: "Helvetica-Bold")
        title.text = "VICTORY"
        title.fontSize = 40
        title.fontColor = Theme.onGreen
        title.position = CGPoint(x: size.width * 0.5, y: size.height * 0.6)
        victoryNode.addChild(title)

        if let ctx = combatContext {
            let reward = SKLabelNode(fontNamed: "Courier")
            reward.text = "+\(ctx.creditsReward) CR  +\(ctx.mineralsReward) MIN"
            reward.fontSize = 14
            reward.fontColor = warmGold
            reward.position = CGPoint(x: size.width * 0.5, y: size.height * 0.6 - 35)
            victoryNode.addChild(reward)

            let planetText = SKLabelNode(fontNamed: "Courier")
            planetText.text = "\(ctx.targetPlanetName) CAPTURED"
            planetText.fontSize = 12
            planetText.fontColor = creamWhite
            planetText.position = CGPoint(x: size.width * 0.5, y: size.height * 0.6 - 55)
            victoryNode.addChild(planetText)
        }

        let continueBtn = SKNode()
        continueBtn.name = "victoryButton"
        continueBtn.position = CGPoint(x: size.width * 0.5, y: size.height * 0.38)

        let btnBg = SKShapeNode(rectOf: CGSize(width: 200, height: 42), cornerRadius: 3)
        btnBg.fillColor = SKColor(red: 0.06, green: 0.06, blue: 0.1, alpha: 0.8)
        btnBg.strokeColor = Theme.onGreen.withAlphaComponent(0.5)
        btnBg.lineWidth = 1
        btnBg.glowWidth = 3
        btnBg.name = "victoryButton"
        continueBtn.addChild(btnBg)

        let btnLabel = SKLabelNode(fontNamed: "Courier-Bold")
        btnLabel.text = "RETURN TO MAP"
        btnLabel.fontSize = 14
        btnLabel.fontColor = creamWhite
        btnLabel.verticalAlignmentMode = .center
        btnLabel.name = "victoryButton"
        continueBtn.addChild(btnLabel)

        victoryNode.addChild(continueBtn)
        addChild(victoryNode)
        victoryNode.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.3),
            SKAction.fadeIn(withDuration: 0.6)
        ]))
    }
    // MARK: - Damage

    func takeDamage(_ amount: Int) {
        if shieldHP > 0 {
            let absorbed = min(shieldHP, amount)
            shieldHP -= absorbed
            let remaining = amount - absorbed
            health -= remaining

            shieldNode?.run(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.8, duration: 0.05),
                SKAction.fadeAlpha(to: CGFloat(shieldHP) / 100.0, duration: 0.2)
            ]))
        } else {
            health -= amount
        }

        // Visual + haptic feedback
        GameFeedback.damageFlash(self)
        GameFeedback.shake(self, intensity: CGFloat(amount) * 0.4)
        GameFeedback.mediumImpact()

        // Flash ship red
        playerShip.run(SKAction.sequence([
            SKAction.run { [weak self] in
                (self?.playerShip.children.first as? SKShapeNode)?.fillColor = SKColor.red.withAlphaComponent(0.8)
            },
            SKAction.wait(forDuration: 0.1),
            SKAction.run { [weak self] in
                guard let self else { return }
                (self.playerShip.children.first as? SKShapeNode)?.fillColor = self.hullGray
            }
        ]))

        if health <= 0 {
            GameFeedback.heavyImpact()
            gameOver()
        }
    }

    // MARK: - Game Over

    func gameOver() {
        isGameOver = true
        motionManager.stopDeviceMotionUpdates()

        spawnExplosion(at: playerShip.position, color: engineGlow, count: 30)
        playerShip.removeFromParent()

        let overlay = SKShapeNode(rectOf: size)
        overlay.fillColor = SKColor.black.withAlphaComponent(0.6)
        overlay.strokeColor = .clear
        overlay.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        overlay.zPosition = 70
        overlay.alpha = 0
        addChild(overlay)
        overlay.run(SKAction.fadeAlpha(to: 0.6, duration: 1.0))

        let gameOverNode = SKNode()
        gameOverNode.zPosition = 80
        gameOverNode.alpha = 0

        let title = SKLabelNode(fontNamed: "Helvetica-Bold")
        title.text = "MISSION FAILED"
        title.fontSize = 36
        title.fontColor = nasaOrange
        title.position = CGPoint(x: size.width * 0.5, y: size.height * 0.6)
        gameOverNode.addChild(title)

        let finalScore = SKLabelNode(fontNamed: "Courier")
        finalScore.text = "FINAL SCORE: \(score)"
        finalScore.fontSize = 14
        finalScore.fontColor = creamWhite
        finalScore.position = CGPoint(x: size.width * 0.5, y: size.height * 0.6 - 35)
        gameOverNode.addChild(finalScore)

        let creditsEarned = SKLabelNode(fontNamed: "Courier")
        creditsEarned.text = "CREDITS EARNED: \(credits)"
        creditsEarned.fontSize = 12
        creditsEarned.fontColor = warmGold
        creditsEarned.position = CGPoint(x: size.width * 0.5, y: size.height * 0.6 - 55)
        gameOverNode.addChild(creditsEarned)

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
}
