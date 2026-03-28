//
//  GameplayScene.swift
//  spritekit
//
//  Created by Clifton Baggerman on 28/03/2026.
//

import SpriteKit
import CoreMotion

class GameplayScene: SKScene, SKPhysicsContactDelegate {

    // MARK: - Physics Categories

    private struct Category {
        static let player:    UInt32 = 0x1 << 0
        static let bullet:    UInt32 = 0x1 << 1
        static let asteroid:  UInt32 = 0x1 << 2
        static let enemy:     UInt32 = 0x1 << 3
        static let loot:      UInt32 = 0x1 << 4
        static let enemyFire: UInt32 = 0x1 << 5
    }

    // MARK: - Colors (Theme aliases for readability)

    private let creamWhite = Theme.creamWhite
    private let nasaOrange = Theme.nasaOrange
    private let deepSpace  = Theme.deepSpace
    private let retroBlue  = Theme.retroBlue
    private let warmGold   = Theme.warmGold
    private let engineGlow = Theme.engineGlow
    private let hullGray   = Theme.hullGray
    private let shieldBlue = Theme.shieldBlue

    // MARK: - Combat Context

    var combatContext: CombatContext?
    var gameState: GameState?
    var onCombatComplete: ((CombatResult) -> Void)?

    private var currentWave: Int = 0
    private var totalWaves: Int = 5
    private var enemiesRemainingInWave: Int = 0
    private var waveInProgress = false
    private var waveLabel: SKLabelNode?
    private var retreatButton: SKNode?
    private var isWaveBased: Bool { combatContext != nil }

    // Fleet modifiers
    private var fireRateMultiplier: Double = 1.0
    private var bonusHP: Int = 0
    private var hasTroopTransport: Bool = false
    private var missileCarrierCount: Int = 0
    private var missileTimer: TimeInterval = 0

    // MARK: - Game State

    private var playerShip: SKNode!
    private var engineEmitter: SKEmitterNode?
    private var shieldNode: SKShapeNode?

    private var health: Int = 100
    private var fuel: Double = 100.0
    private var score: Int = 0
    private var credits: Int = 0
    private var shieldHP: Int = 50

    private var healthLabel: SKLabelNode?
    private var fuelBar: SKShapeNode?
    private var fuelBarBg: SKShapeNode?
    private var scoreLabel: SKLabelNode?
    private var creditsLabel: SKLabelNode?
    private var shieldLabel: SKLabelNode?
    private var speedLabel: SKLabelNode?

    private var lastUpdateTime: TimeInterval = 0
    private var asteroidTimer: TimeInterval = 0
    private var enemyTimer: TimeInterval = 0
    private var fuelTimer: TimeInterval = 0

    private var isTouching = false
    private var touchLocation: CGPoint = .zero
    private var isGameOver = false

    private let motionManager = CMMotionManager()
    private var shipSpeed: CGFloat = 0

    // MARK: - Scene Setup

    override func didMove(to view: SKView) {
        BackgroundBuilder.addSpaceBackground(to: self, drift: .vertical, nebula: true, scanlines: false)

        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self

        // Apply combat context if wave-based
        if let ctx = combatContext {
            totalWaves = ctx.waveCount
            currentWave = 0
        }

        // Apply fleet modifiers
        applyFleetModifiers()

        buildPlayer()
        buildHUD()
        buildWaveHUD()
        buildRetreatButton()
        startGyroscope()

        // Start first wave after brief delay
        if isWaveBased {
            run(SKAction.sequence([
                SKAction.wait(forDuration: 1.5),
                SKAction.run { [weak self] in self?.startNextWave() }
            ]))
        }
    }

    override func willMove(from view: SKView) {
        motionManager.stopDeviceMotionUpdates()
    }

    // MARK: - Gyroscope

    private func startGyroscope() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates()
    }

    // MARK: - Player Ship

    private func buildPlayer() {
        let ship = SKNode()
        ship.position = CGPoint(x: size.width * 0.5, y: size.height * 0.2)
        ship.zPosition = 10
        ship.name = "player"

        // Hull — pointed triangle
        let hullPath = CGMutablePath()
        hullPath.move(to: CGPoint(x: 0, y: 24))
        hullPath.addLine(to: CGPoint(x: -16, y: -16))
        hullPath.addLine(to: CGPoint(x: -6, y: -10))
        hullPath.addLine(to: CGPoint(x: 0, y: -14))
        hullPath.addLine(to: CGPoint(x: 6, y: -10))
        hullPath.addLine(to: CGPoint(x: 16, y: -16))
        hullPath.closeSubpath()

        let hull = SKShapeNode(path: hullPath)
        hull.fillColor = hullGray
        hull.strokeColor = creamWhite.withAlphaComponent(0.5)
        hull.lineWidth = 1
        ship.addChild(hull)

        // Cockpit window
        let cockpit = SKShapeNode(circleOfRadius: 4)
        cockpit.fillColor = retroBlue.withAlphaComponent(0.7)
        cockpit.strokeColor = shieldBlue.withAlphaComponent(0.4)
        cockpit.lineWidth = 0.5
        cockpit.glowWidth = 2
        cockpit.position = CGPoint(x: 0, y: 8)
        ship.addChild(cockpit)

        // Wing accent stripes
        let leftStripe = SKShapeNode(rectOf: CGSize(width: 8, height: 1.5))
        leftStripe.fillColor = nasaOrange
        leftStripe.strokeColor = .clear
        leftStripe.position = CGPoint(x: -8, y: -4)
        ship.addChild(leftStripe)

        let rightStripe = SKShapeNode(rectOf: CGSize(width: 8, height: 1.5))
        rightStripe.fillColor = nasaOrange
        rightStripe.strokeColor = .clear
        rightStripe.position = CGPoint(x: 8, y: -4)
        ship.addChild(rightStripe)

        // Engine glow
        let engine = SKEmitterNode()
        engine.particleBirthRate = 80
        engine.particleLifetime = 0.4
        engine.particleLifetimeRange = 0.2
        engine.particleSpeed = 100
        engine.particleSpeedRange = 30
        engine.emissionAngle = .pi * 1.5
        engine.emissionAngleRange = 0.2
        engine.particleScale = 0.04
        engine.particleScaleRange = 0.02
        engine.particleScaleSpeed = -0.05
        engine.particleAlpha = 0.8
        engine.particleAlphaSpeed = -1.5
        engine.particleColor = engineGlow
        engine.particleColorBlendFactor = 1.0
        engine.particleBlendMode = .add
        engine.position = CGPoint(x: 0, y: -14)
        engine.zPosition = -1
        ship.addChild(engine)
        engineEmitter = engine

        // Shield
        let shield = SKShapeNode(circleOfRadius: 28)
        shield.fillColor = .clear
        shield.strokeColor = shieldBlue.withAlphaComponent(0.2)
        shield.lineWidth = 1
        shield.glowWidth = 4
        shield.alpha = 0.5
        shield.name = "shield"
        ship.addChild(shield)
        shieldNode = shield

        // Physics body
        let bodyPath = CGMutablePath()
        bodyPath.move(to: CGPoint(x: 0, y: 24))
        bodyPath.addLine(to: CGPoint(x: -16, y: -16))
        bodyPath.addLine(to: CGPoint(x: 16, y: -16))
        bodyPath.closeSubpath()

        ship.physicsBody = SKPhysicsBody(polygonFrom: bodyPath)
        ship.physicsBody?.categoryBitMask = Category.player
        ship.physicsBody?.contactTestBitMask = Category.asteroid | Category.enemy | Category.loot | Category.enemyFire
        ship.physicsBody?.collisionBitMask = 0
        ship.physicsBody?.isDynamic = true
        ship.physicsBody?.allowsRotation = false

        playerShip = ship
        addChild(ship)
    }

    // MARK: - HUD

    private func buildHUD() {
        let hudZ: CGFloat = 40
        let topY = size.height - 50
        let padding: CGFloat = 16

        // Health
        let healthIcon = SKShapeNode(rectOf: CGSize(width: 10, height: 10), cornerRadius: 2)
        healthIcon.fillColor = nasaOrange
        healthIcon.strokeColor = .clear
        healthIcon.position = CGPoint(x: padding + 5, y: topY)
        healthIcon.zPosition = hudZ
        addChild(healthIcon)

        let hl = SKLabelNode(fontNamed: "Courier-Bold")
        hl.text = "HULL 100%"
        hl.fontSize = 12
        hl.fontColor = creamWhite
        hl.horizontalAlignmentMode = .left
        hl.verticalAlignmentMode = .center
        hl.position = CGPoint(x: padding + 16, y: topY)
        hl.zPosition = hudZ
        healthLabel = hl
        addChild(hl)

        // Shield
        let sl = SKLabelNode(fontNamed: "Courier")
        sl.text = "SHLD 50"
        sl.fontSize = 10
        sl.fontColor = shieldBlue.withAlphaComponent(0.7)
        sl.horizontalAlignmentMode = .left
        sl.verticalAlignmentMode = .center
        sl.position = CGPoint(x: padding + 16, y: topY - 18)
        sl.zPosition = hudZ
        shieldLabel = sl
        addChild(sl)

        // Fuel bar background
        let fuelBgWidth: CGFloat = 120
        let fuelBg = SKShapeNode(rectOf: CGSize(width: fuelBgWidth, height: 6), cornerRadius: 3)
        fuelBg.fillColor = SKColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 0.8)
        fuelBg.strokeColor = hullGray.withAlphaComponent(0.3)
        fuelBg.lineWidth = 0.5
        fuelBg.position = CGPoint(x: padding + 76, y: topY - 36)
        fuelBg.zPosition = hudZ
        fuelBarBg = fuelBg
        addChild(fuelBg)

        let fuelFill = SKShapeNode(rectOf: CGSize(width: fuelBgWidth - 4, height: 4), cornerRadius: 2)
        fuelFill.fillColor = warmGold
        fuelFill.strokeColor = .clear
        fuelFill.position = CGPoint(x: padding + 76, y: topY - 36)
        fuelFill.zPosition = hudZ + 1
        fuelBar = fuelFill
        addChild(fuelFill)

        let fuelLabel = SKLabelNode(fontNamed: "Courier")
        fuelLabel.text = "FUEL"
        fuelLabel.fontSize = 9
        fuelLabel.fontColor = warmGold.withAlphaComponent(0.7)
        fuelLabel.horizontalAlignmentMode = .left
        fuelLabel.verticalAlignmentMode = .center
        fuelLabel.position = CGPoint(x: padding + 4, y: topY - 36)
        fuelLabel.zPosition = hudZ
        addChild(fuelLabel)

        // Score (top right)
        let scl = SKLabelNode(fontNamed: "Courier-Bold")
        scl.text = "0"
        scl.fontSize = 20
        scl.fontColor = creamWhite
        scl.horizontalAlignmentMode = .right
        scl.verticalAlignmentMode = .center
        scl.position = CGPoint(x: size.width - padding, y: topY)
        scl.zPosition = hudZ
        scoreLabel = scl
        addChild(scl)

        let scoreTitle = SKLabelNode(fontNamed: "Courier")
        scoreTitle.text = "SCORE"
        scoreTitle.fontSize = 9
        scoreTitle.fontColor = hullGray.withAlphaComponent(0.6)
        scoreTitle.horizontalAlignmentMode = .right
        scoreTitle.verticalAlignmentMode = .center
        scoreTitle.position = CGPoint(x: size.width - padding, y: topY - 16)
        scoreTitle.zPosition = hudZ
        addChild(scoreTitle)

        // Credits
        let cl = SKLabelNode(fontNamed: "Courier")
        cl.text = "CR 0"
        cl.fontSize = 11
        cl.fontColor = warmGold
        cl.horizontalAlignmentMode = .right
        cl.verticalAlignmentMode = .center
        cl.position = CGPoint(x: size.width - padding, y: topY - 34)
        cl.zPosition = hudZ
        creditsLabel = cl
        addChild(cl)

        // Speed indicator (bottom center)
        let spl = SKLabelNode(fontNamed: "Courier")
        spl.text = "SPD 0.0"
        spl.fontSize = 10
        spl.fontColor = retroBlue.withAlphaComponent(0.5)
        spl.horizontalAlignmentMode = .center
        spl.verticalAlignmentMode = .center
        spl.position = CGPoint(x: size.width * 0.5, y: 30)
        spl.zPosition = hudZ
        speedLabel = spl
        addChild(spl)

        // Crosshair / targeting reticle (subtle)
        let reticle = SKShapeNode(circleOfRadius: 20)
        reticle.strokeColor = creamWhite.withAlphaComponent(0.08)
        reticle.fillColor = .clear
        reticle.lineWidth = 0.5
        reticle.position = CGPoint(x: size.width * 0.5, y: size.height * 0.6)
        reticle.zPosition = hudZ - 1
        addChild(reticle)

        let reticleDot = SKShapeNode(circleOfRadius: 1.5)
        reticleDot.fillColor = creamWhite.withAlphaComponent(0.15)
        reticleDot.strokeColor = .clear
        reticleDot.position = reticle.position
        reticleDot.zPosition = hudZ - 1
        addChild(reticleDot)
    }

    private func updateHUD() {
        healthLabel?.text = "HULL \(max(0, health))%"
        if health <= 25 {
            healthLabel?.fontColor = nasaOrange
        } else {
            healthLabel?.fontColor = creamWhite
        }

        shieldLabel?.text = "SHLD \(max(0, shieldHP))"
        shieldLabel?.fontColor = shieldHP > 0 ? shieldBlue.withAlphaComponent(0.7) : hullGray.withAlphaComponent(0.3)
        shieldNode?.alpha = shieldHP > 0 ? CGFloat(shieldHP) / 100.0 : 0

        let fuelPercent = CGFloat(fuel / 100.0)
        let maxWidth: CGFloat = 116.0
        fuelBar?.xScale = max(0.01, fuelPercent)
        if fuel < 20 {
            fuelBar?.fillColor = nasaOrange
        } else {
            fuelBar?.fillColor = warmGold
        }

        scoreLabel?.text = "\(score)"
        creditsLabel?.text = "CR \(credits)"
        speedLabel?.text = String(format: "SPD %.1f", shipSpeed)
    }

    // MARK: - Fleet Modifiers

    private func applyFleetModifiers() {
        guard let state = gameState else { return }

        let fighters = state.player.shipCount(for: .fighter)
        let destroyers = state.player.shipCount(for: .destroyer)
        let missiles = state.player.shipCount(for: .missileCarrier)
        let transports = state.player.shipCount(for: .troopTransport)

        // Fighters: each adds 15% fire rate
        fireRateMultiplier = 1.0 / (1.0 + Double(fighters) * 0.15)

        // Destroyers: each adds 20 HP
        bonusHP = destroyers * 20
        health += bonusHP

        // Missile carriers: spawn homing missiles periodically
        missileCarrierCount = missiles

        // Troop transports: required for planet capture
        hasTroopTransport = transports > 0
    }

    private func spawnHomingMissile() {
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

    // MARK: - Wave HUD

    private func buildWaveHUD() {
        guard isWaveBased else { return }

        let wl = SKLabelNode(fontNamed: "Courier-Bold")
        wl.text = ""
        wl.fontSize = 14
        wl.fontColor = creamWhite
        wl.horizontalAlignmentMode = .center
        wl.verticalAlignmentMode = .center
        wl.position = CGPoint(x: size.width * 0.5, y: size.height - 50)
        wl.zPosition = 40
        waveLabel = wl
        addChild(wl)

        // Planet name being contested
        if let ctx = combatContext {
            let targetLabel = SKLabelNode(fontNamed: "Courier")
            targetLabel.text = "ENGAGING: \(ctx.targetPlanetName)"
            targetLabel.fontSize = 10
            targetLabel.fontColor = nasaOrange.withAlphaComponent(0.7)
            targetLabel.horizontalAlignmentMode = .center
            targetLabel.position = CGPoint(x: size.width * 0.5, y: size.height - 68)
            targetLabel.zPosition = 40
            addChild(targetLabel)
        }
    }

    private func buildRetreatButton() {
        guard isWaveBased else { return }

        let btn = SKNode()
        btn.name = "retreatButton"
        btn.position = CGPoint(x: size.width - 60, y: 50)
        btn.zPosition = 45

        let bg = SKShapeNode(rectOf: CGSize(width: 90, height: 30), cornerRadius: 3)
        bg.fillColor = Theme.offRed.withAlphaComponent(0.15)
        bg.strokeColor = Theme.offRed.withAlphaComponent(0.4)
        bg.lineWidth = 1
        bg.name = "retreatButton"
        btn.addChild(bg)

        let label = SKLabelNode(fontNamed: "Courier-Bold")
        label.text = "RETREAT"
        label.fontSize = 10
        label.fontColor = Theme.offRed.withAlphaComponent(0.7)
        label.verticalAlignmentMode = .center
        label.name = "retreatButton"
        btn.addChild(label)

        retreatButton = btn
        addChild(btn)
    }

    // MARK: - Wave Management

    private func startNextWave() {
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

        // Spawn enemies for this wave with delay
        for i in 0..<enemyCount {
            run(SKAction.sequence([
                SKAction.wait(forDuration: Double(i) * 0.8 + 0.5),
                SKAction.run { [weak self] in self?.spawnEnemy() }
            ]))
        }
    }

    private func onEnemyDestroyed() {
        guard isWaveBased, waveInProgress else { return }
        enemiesRemainingInWave -= 1

        if enemiesRemainingInWave <= 0 {
            waveInProgress = false
            // Delay before next wave
            run(SKAction.sequence([
                SKAction.wait(forDuration: 2.0),
                SKAction.run { [weak self] in self?.startNextWave() }
            ]))
        }
    }

    private func combatVictory() {
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

    // MARK: - Spawning

    private func spawnAsteroid() {
        let radius = CGFloat.random(in: 10...35)
        let sides = Int.random(in: 5...8)
        let points = (0..<sides).map { i -> CGPoint in
            let angle = (CGFloat(i) / CGFloat(sides)) * .pi * 2
            let r = radius * CGFloat.random(in: 0.7...1.0)
            return CGPoint(x: cos(angle) * r, y: sin(angle) * r)
        }

        let path = CGMutablePath()
        path.move(to: points[0])
        for p in points.dropFirst() { path.addLine(to: p) }
        path.closeSubpath()

        let asteroid = SKShapeNode(path: path)
        asteroid.fillColor = SKColor(
            red: CGFloat.random(in: 0.2...0.35),
            green: CGFloat.random(in: 0.18...0.3),
            blue: CGFloat.random(in: 0.15...0.25),
            alpha: 1.0
        )
        asteroid.strokeColor = hullGray.withAlphaComponent(0.3)
        asteroid.lineWidth = 0.5
        asteroid.name = "asteroid"
        asteroid.position = CGPoint(
            x: CGFloat.random(in: radius...size.width - radius),
            y: size.height + radius + 20
        )
        asteroid.zPosition = 5

        asteroid.physicsBody = SKPhysicsBody(polygonFrom: path)
        asteroid.physicsBody?.categoryBitMask = Category.asteroid
        asteroid.physicsBody?.contactTestBitMask = Category.bullet | Category.player
        asteroid.physicsBody?.collisionBitMask = 0
        asteroid.physicsBody?.isDynamic = true
        asteroid.physicsBody?.velocity = CGVector(dx: CGFloat.random(in: -30...30), dy: -CGFloat.random(in: 80...200))
        asteroid.physicsBody?.angularVelocity = CGFloat.random(in: -2...2)
        asteroid.physicsBody?.linearDamping = 0
        asteroid.physicsBody?.angularDamping = 0

        addChild(asteroid)
    }

    private func spawnEnemy() {
        let enemy = SKNode()
        enemy.name = "enemy"
        enemy.position = CGPoint(
            x: CGFloat.random(in: 40...size.width - 40),
            y: size.height + 30
        )
        enemy.zPosition = 8

        // Enemy hull — diamond shape
        let hullPath = CGMutablePath()
        hullPath.move(to: CGPoint(x: 0, y: -18))
        hullPath.addLine(to: CGPoint(x: -14, y: 4))
        hullPath.addLine(to: CGPoint(x: -8, y: 14))
        hullPath.addLine(to: CGPoint(x: 8, y: 14))
        hullPath.addLine(to: CGPoint(x: 14, y: 4))
        hullPath.closeSubpath()

        let hull = SKShapeNode(path: hullPath)
        hull.fillColor = SKColor(red: 0.5, green: 0.15, blue: 0.15, alpha: 0.9)
        hull.strokeColor = SKColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 0.6)
        hull.lineWidth = 1
        enemy.addChild(hull)

        // Red cockpit
        let cockpit = SKShapeNode(circleOfRadius: 3)
        cockpit.fillColor = SKColor(red: 1.0, green: 0.2, blue: 0.1, alpha: 0.8)
        cockpit.strokeColor = .clear
        cockpit.glowWidth = 4
        cockpit.position = CGPoint(x: 0, y: -2)
        enemy.addChild(cockpit)

        let bodyPath = CGMutablePath()
        bodyPath.move(to: CGPoint(x: 0, y: -18))
        bodyPath.addLine(to: CGPoint(x: -14, y: 14))
        bodyPath.addLine(to: CGPoint(x: 14, y: 14))
        bodyPath.closeSubpath()

        enemy.physicsBody = SKPhysicsBody(polygonFrom: bodyPath)
        enemy.physicsBody?.categoryBitMask = Category.enemy
        enemy.physicsBody?.contactTestBitMask = Category.bullet | Category.player
        enemy.physicsBody?.collisionBitMask = 0
        enemy.physicsBody?.isDynamic = true
        enemy.physicsBody?.linearDamping = 0

        // Movement — sweep down then strafe
        let moveDown = SKAction.moveBy(x: 0, y: -200, duration: 1.5)
        let strafe = SKAction.sequence([
            SKAction.moveBy(x: CGFloat.random(in: -80...80), y: -40, duration: 1.0),
            SKAction.moveBy(x: CGFloat.random(in: -80...80), y: -40, duration: 1.0)
        ])
        let exitDown = SKAction.moveBy(x: 0, y: -(size.height), duration: 3.0)

        // Fire at player during strafe
        let fireAction = SKAction.sequence([
            SKAction.wait(forDuration: 0.8),
            SKAction.run { [weak self] in self?.enemyFire(from: enemy) },
            SKAction.wait(forDuration: 0.6),
            SKAction.run { [weak self] in self?.enemyFire(from: enemy) }
        ])

        enemy.run(SKAction.sequence([
            moveDown,
            SKAction.group([strafe, fireAction]),
            exitDown,
            SKAction.removeFromParent()
        ]))

        addChild(enemy)
    }

    private func enemyFire(from enemy: SKNode) {
        guard !isGameOver else { return }

        let bullet = SKShapeNode(rectOf: CGSize(width: 2, height: 8), cornerRadius: 1)
        bullet.fillColor = SKColor(red: 1.0, green: 0.2, blue: 0.1, alpha: 0.9)
        bullet.strokeColor = .clear
        bullet.glowWidth = 4
        bullet.position = CGPoint(x: enemy.position.x, y: enemy.position.y + 18)
        bullet.zPosition = 7
        bullet.name = "enemyBullet"

        bullet.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 2, height: 8))
        bullet.physicsBody?.categoryBitMask = Category.enemyFire
        bullet.physicsBody?.contactTestBitMask = Category.player
        bullet.physicsBody?.collisionBitMask = 0
        bullet.physicsBody?.isDynamic = true
        bullet.physicsBody?.velocity = CGVector(dx: 0, dy: -300)
        bullet.physicsBody?.linearDamping = 0

        addChild(bullet)
    }

    // MARK: - Player Fire

    private func fireBullet() {
        guard !isGameOver else { return }

        let bullet = SKShapeNode(rectOf: CGSize(width: 2, height: 10), cornerRadius: 1)
        bullet.fillColor = nasaOrange
        bullet.strokeColor = .clear
        bullet.glowWidth = 5
        bullet.position = CGPoint(x: playerShip.position.x, y: playerShip.position.y + 28)
        bullet.zPosition = 9
        bullet.name = "bullet"

        bullet.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 2, height: 10))
        bullet.physicsBody?.categoryBitMask = Category.bullet
        bullet.physicsBody?.contactTestBitMask = Category.asteroid | Category.enemy
        bullet.physicsBody?.collisionBitMask = 0
        bullet.physicsBody?.isDynamic = true
        bullet.physicsBody?.velocity = CGVector(dx: 0, dy: 500)
        bullet.physicsBody?.linearDamping = 0

        addChild(bullet)
    }

    // MARK: - Loot Drop

    private func spawnLoot(at position: CGPoint) {
        let lootKinds: [(color: SKColor, label: String)] = [
            (warmGold, "CR"),
            (shieldBlue, "SH"),
            (SKColor(red: 0.2, green: 0.9, blue: 0.3, alpha: 1.0), "HP"),
            (nasaOrange, "FU")
        ]
        let kind = lootKinds.randomElement()!

        let loot = SKNode()
        loot.name = "loot_\(kind.label)"
        loot.position = position
        loot.zPosition = 6

        let gem = SKShapeNode(rectOf: CGSize(width: 10, height: 10), cornerRadius: 2)
        gem.fillColor = kind.color.withAlphaComponent(0.7)
        gem.strokeColor = kind.color
        gem.lineWidth = 1
        gem.glowWidth = 5
        loot.addChild(gem)

        let label = SKLabelNode(fontNamed: "Courier-Bold")
        label.text = kind.label
        label.fontSize = 7
        label.fontColor = creamWhite
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        loot.addChild(label)

        loot.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 14, height: 14))
        loot.physicsBody?.categoryBitMask = Category.loot
        loot.physicsBody?.contactTestBitMask = Category.player
        loot.physicsBody?.collisionBitMask = 0
        loot.physicsBody?.isDynamic = true
        loot.physicsBody?.velocity = CGVector(dx: 0, dy: -60)
        loot.physicsBody?.linearDamping = 0

        let bob = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 4, duration: 0.5),
            SKAction.moveBy(x: 0, y: -4, duration: 0.5)
        ])
        loot.run(SKAction.repeatForever(bob))

        addChild(loot)
    }

    // MARK: - Explosions

    private func spawnExplosion(at position: CGPoint, color: SKColor, count: Int = 12) {
        for _ in 0..<count {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...4))
            particle.fillColor = color
            particle.strokeColor = .clear
            particle.glowWidth = 4
            particle.position = position
            particle.zPosition = 12

            let angle = CGFloat.random(in: 0...(.pi * 2))
            let distance = CGFloat.random(in: 20...60)
            let dest = CGPoint(x: position.x + cos(angle) * distance, y: position.y + sin(angle) * distance)

            let burst = SKAction.group([
                SKAction.move(to: dest, duration: Double.random(in: 0.2...0.5)),
                SKAction.fadeOut(withDuration: 0.5),
                SKAction.scale(to: 0.1, duration: 0.5)
            ])
            addChild(particle)
            particle.run(SKAction.sequence([burst, SKAction.removeFromParent()]))
        }
    }

    // MARK: - Damage

    private func takeDamage(_ amount: Int) {
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
            gameOver()
        }
    }

    // MARK: - Game Over

    private func gameOver() {
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

        // Retreat button
        let tapped = nodes(at: location)
        for node in tapped where node.name == "retreatButton" {
            onCombatComplete?(.retreat)
            return
        }

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

    private func updatePlayerMovement(dt: TimeInterval) {
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
