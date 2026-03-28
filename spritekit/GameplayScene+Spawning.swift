//
//  GameplayScene+Spawning.swift
//  spritekit
//

import SpriteKit

extension GameplayScene {

    // MARK: - Spawning

    func spawnAsteroid() {
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

    func spawnEnemy() {
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

    func enemyFire(from enemy: SKNode) {
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

    func fireBullet() {
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

    func spawnLoot(at position: CGPoint) {
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

    func spawnExplosion(at position: CGPoint, color: SKColor, count: Int = 12) {
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

}
