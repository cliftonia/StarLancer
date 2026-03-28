//
//  GameplayScene+Player.swift
//  spritekit
//

import SpriteKit
import CoreMotion

extension GameplayScene {

    // MARK: - Build Player Ship

    func buildPlayer() {
        let ship = SKNode()
        ship.position = CGPoint(x: size.width * 0.5, y: size.height * 0.2)
        ship.zPosition = 10
        ship.name = "player"

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

        let cockpit = SKShapeNode(circleOfRadius: 4)
        cockpit.fillColor = retroBlue.withAlphaComponent(0.7)
        cockpit.strokeColor = shieldBlue.withAlphaComponent(0.4)
        cockpit.lineWidth = 0.5
        cockpit.glowWidth = 2
        cockpit.position = CGPoint(x: 0, y: 8)
        ship.addChild(cockpit)

        for side in [-1.0, 1.0] {
            let stripe = SKShapeNode(rectOf: CGSize(width: 8, height: 1.5))
            stripe.fillColor = nasaOrange
            stripe.strokeColor = .clear
            stripe.position = CGPoint(x: side * 8, y: -4)
            ship.addChild(stripe)
        }

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

        let shield = SKShapeNode(circleOfRadius: 28)
        shield.fillColor = .clear
        shield.strokeColor = shieldBlue.withAlphaComponent(0.2)
        shield.lineWidth = 1
        shield.glowWidth = 4
        shield.alpha = 0.5
        shield.name = "shield"
        ship.addChild(shield)
        shieldNode = shield

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

    // MARK: - Player Movement

    func updatePlayerMovement(dt: TimeInterval) {
        guard let ship = playerShip else { return }

        var dx: CGFloat = 0
        var dy: CGFloat = 0

        if let motion = motionManager.deviceMotion {
            let tiltX = CGFloat(motion.attitude.roll) * 400
            let tiltY = CGFloat(motion.attitude.pitch - 0.6) * 300
            dx += tiltX
            dy += tiltY
        }

        if isTouching {
            let target = touchLocation
            let diff = CGPoint(x: target.x - ship.position.x, y: target.y - ship.position.y)
            let speedMul: CGFloat = speedBoostActive ? 4.0 : 2.5
            dx += diff.x * speedMul
            dy += diff.y * speedMul
        }

        shipSpeed = sqrt(dx * dx + dy * dy) * 0.01

        let newX = ship.position.x + dx * CGFloat(dt)
        let newY = ship.position.y + dy * CGFloat(dt)

        ship.position.x = max(20, min(size.width - 20, newX))
        ship.position.y = max(40, min(size.height - 80, newY))

        let tiltAngle = -dx * 0.0005
        ship.zRotation = max(-.pi * 0.15, min(.pi * 0.15, tiltAngle))
    }
}
