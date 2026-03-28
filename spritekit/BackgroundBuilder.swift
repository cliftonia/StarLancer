//
//  BackgroundBuilder.swift
//  spritekit
//
//  Created by Clifton Baggerman on 28/03/2026.
//

import SpriteKit

enum StarDriftDirection {
    case horizontal
    case vertical
    case none
}

enum BackgroundBuilder {

    // MARK: - Parallax Starfield

    static func addStarfield(
        to scene: SKScene,
        drift: StarDriftDirection = .horizontal,
        layers: [(count: Int, sizeRange: ClosedRange<CGFloat>, alphaRange: ClosedRange<CGFloat>, speed: CGFloat)] = [
            (120, 0.3...0.8, 0.15...0.35, 0.08),
            (80, 0.8...1.5, 0.3...0.6, 0.2),
            (30, 1.5...2.5, 0.6...1.0, 0.5)
        ]
    ) {
        let sceneSize = scene.size

        for (index, layer) in layers.enumerated() {
            for _ in 0..<layer.count {
                let star = SKShapeNode(circleOfRadius: CGFloat.random(in: layer.sizeRange))
                let warmth = CGFloat.random(in: 0...1)
                let r: CGFloat = warmth > 0.7 ? 1.0 : (0.8 + warmth * 0.2)
                let g: CGFloat = 0.85 + warmth * 0.15
                let b: CGFloat = warmth < 0.3 ? 1.0 : (0.7 + warmth * 0.3)
                star.fillColor = SKColor(red: r, green: g, blue: b, alpha: CGFloat.random(in: layer.alphaRange))
                star.strokeColor = .clear
                star.position = CGPoint(
                    x: CGFloat.random(in: 0...sceneSize.width),
                    y: CGFloat.random(in: 0...sceneSize.height)
                )
                star.zPosition = CGFloat(-10 + index)

                let twinkle = SKAction.sequence([
                    SKAction.fadeAlpha(to: CGFloat.random(in: 0.1...0.4), duration: Double.random(in: 1.0...4.0)),
                    SKAction.fadeAlpha(to: CGFloat.random(in: 0.5...1.0), duration: Double.random(in: 1.0...4.0))
                ])
                star.run(SKAction.repeatForever(twinkle))

                switch drift {
                case .horizontal:
                    let driftAction = SKAction.moveBy(x: -layer.speed * 60, y: 0, duration: 1.0)
                    let reset = SKAction.run {
                        if star.position.x < -10 {
                            star.position.x = sceneSize.width + 10
                            star.position.y = CGFloat.random(in: 0...sceneSize.height)
                        }
                    }
                    star.run(SKAction.repeatForever(SKAction.sequence([driftAction, reset])))

                case .vertical:
                    let driftAction = SKAction.moveBy(x: 0, y: -layer.speed * 60, duration: 1.0)
                    let reset = SKAction.run {
                        if star.position.y < -5 {
                            star.position.y = sceneSize.height + 5
                            star.position.x = CGFloat.random(in: 0...sceneSize.width)
                        }
                    }
                    star.run(SKAction.repeatForever(SKAction.sequence([driftAction, reset])))

                case .none:
                    break
                }

                scene.addChild(star)
            }
        }
    }

    // MARK: - Nebula Clouds

    static func addNebula(to scene: SKScene, count: Int = 5) {
        let nebulaColors: [SKColor] = [
            SKColor(red: 0.15, green: 0.1, blue: 0.3, alpha: 0.15),
            SKColor(red: 0.3, green: 0.1, blue: 0.15, alpha: 0.1),
            SKColor(red: 0.1, green: 0.15, blue: 0.3, alpha: 0.12)
        ]

        for _ in 0..<count {
            let cloud = SKShapeNode(circleOfRadius: CGFloat.random(in: 80...200))
            cloud.fillColor = nebulaColors.randomElement()!
            cloud.strokeColor = .clear
            cloud.glowWidth = 40
            cloud.position = CGPoint(
                x: CGFloat.random(in: 0...scene.size.width),
                y: CGFloat.random(in: scene.size.height * 0.3...scene.size.height)
            )
            cloud.zPosition = -8
            cloud.alpha = CGFloat.random(in: 0.3...0.6)

            let breathe = SKAction.sequence([
                SKAction.group([
                    SKAction.fadeAlpha(to: CGFloat.random(in: 0.15...0.3), duration: Double.random(in: 6...12)),
                    SKAction.scale(to: CGFloat.random(in: 0.9...1.1), duration: Double.random(in: 6...12))
                ]),
                SKAction.group([
                    SKAction.fadeAlpha(to: CGFloat.random(in: 0.4...0.6), duration: Double.random(in: 6...12)),
                    SKAction.scale(to: 1.0, duration: Double.random(in: 6...12))
                ])
            ])
            cloud.run(SKAction.repeatForever(breathe))
            scene.addChild(cloud)
        }
    }

    // MARK: - CRT Scanlines

    static func addScanlines(to scene: SKScene, spacing: CGFloat = 3, alpha: CGFloat = 0.03) {
        let scanlineNode = SKNode()
        scanlineNode.zPosition = 50
        scanlineNode.alpha = alpha

        var y: CGFloat = 0
        while y < scene.size.height {
            let line = SKShapeNode(rectOf: CGSize(width: scene.size.width, height: 1))
            line.fillColor = .black
            line.strokeColor = .clear
            line.position = CGPoint(x: scene.size.width * 0.5, y: y)
            scanlineNode.addChild(line)
            y += spacing
        }

        scene.addChild(scanlineNode)
    }

    // MARK: - Full Background (convenience)

    static func addSpaceBackground(
        to scene: SKScene,
        drift: StarDriftDirection = .horizontal,
        nebula: Bool = true,
        scanlines: Bool = true
    ) {
        scene.backgroundColor = Theme.deepSpace
        addStarfield(to: scene, drift: drift)
        if nebula { addNebula(to: scene) }
        if scanlines { addScanlines(to: scene) }
    }
}
