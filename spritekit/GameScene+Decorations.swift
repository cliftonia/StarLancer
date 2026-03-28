//
//  GameScene+Decorations.swift
//  spritekit
//

import SpriteKit

extension GameScene {

    // MARK: - Planet

    func buildPlanet() {
        let planet = SKNode()
        planet.position = CGPoint(x: size.width * 0.72, y: size.height * 0.2)
        planet.zPosition = -5

        let radius: CGFloat = 120
        let body = SKShapeNode(circleOfRadius: radius)
        body.fillColor = SKColor(red: 0.55, green: 0.35, blue: 0.2, alpha: 1.0)
        body.strokeColor = .clear
        planet.addChild(body)

        let bandColors: [SKColor] = [
            SKColor(red: 0.65, green: 0.4, blue: 0.25, alpha: 0.6),
            SKColor(red: 0.45, green: 0.3, blue: 0.18, alpha: 0.5),
            SKColor(red: 0.7, green: 0.5, blue: 0.3, alpha: 0.4)
        ]
        for i in 0..<6 {
            let bandY = CGFloat(i - 3) * 30
            let bandWidth = sqrt(max(0, radius * radius - bandY * bandY)) * 2
            guard bandWidth > 10 else { continue }
            let band = SKShapeNode(rectOf: CGSize(width: bandWidth, height: 12 + CGFloat.random(in: 0...8)))
            band.fillColor = bandColors[i % bandColors.count]
            band.strokeColor = .clear
            band.position = CGPoint(x: 0, y: bandY)
            planet.addChild(band)
        }

        let atmosphere = SKShapeNode(circleOfRadius: radius + 8)
        atmosphere.fillColor = .clear
        atmosphere.strokeColor = SKColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 0.3)
        atmosphere.lineWidth = 6
        atmosphere.glowWidth = 15
        planet.addChild(atmosphere)

        let shadowPath = CGMutablePath()
        shadowPath.addArc(center: .zero, radius: radius, startAngle: -.pi * 0.5, endAngle: .pi * 0.5, clockwise: false)
        shadowPath.closeSubpath()
        let shadow = SKShapeNode(path: shadowPath)
        shadow.fillColor = SKColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 10, y: 0)
        planet.addChild(shadow)

        addChild(planet)

        let sway = SKAction.sequence([
            SKAction.moveBy(x: 3, y: -1, duration: 8),
            SKAction.moveBy(x: -3, y: 1, duration: 8)
        ])
        planet.run(SKAction.repeatForever(sway))
    }

    // MARK: - Orbital Rings

    func buildOrbitalRings() {
        let centerX = size.width * 0.72
        let centerY = size.height * 0.2

        for i in 0..<3 {
            let ringRadius: CGFloat = 160 + CGFloat(i) * 30
            let ring = SKShapeNode(ellipseOf: CGSize(width: ringRadius * 2, height: ringRadius * 0.4))
            ring.strokeColor = SKColor(red: 0.5, green: 0.6, blue: 0.8, alpha: 0.15 - CGFloat(i) * 0.03)
            ring.lineWidth = 0.8
            ring.glowWidth = 2
            ring.fillColor = .clear
            ring.position = CGPoint(x: centerX, y: centerY)
            ring.zPosition = -4
            addChild(ring)
        }

        let satellite = SKShapeNode(circleOfRadius: 2.5)
        satellite.fillColor = Theme.warmGold
        satellite.strokeColor = .clear
        satellite.glowWidth = 5
        satellite.zPosition = -3

        let orbitPath = CGMutablePath()
        orbitPath.addEllipse(in: CGRect(x: centerX - 160, y: centerY - 32, width: 320, height: 64))
        satellite.run(SKAction.repeatForever(SKAction.follow(orbitPath, asOffset: false, orientToPath: false, duration: 12)))
        addChild(satellite)
    }

    // MARK: - Space Station

    func buildSpaceStation() {
        let station = SKNode()
        station.position = CGPoint(x: size.width * 0.18, y: size.height * 0.6)
        station.zPosition = 2
        station.setScale(0.8)

        let hub = SKShapeNode(rectOf: CGSize(width: 40, height: 20), cornerRadius: 4)
        hub.fillColor = Theme.hullGray.withAlphaComponent(0.8)
        hub.strokeColor = Theme.creamWhite.withAlphaComponent(0.3)
        hub.lineWidth = 0.5
        station.addChild(hub)

        for side in [-1.0, 1.0] {
            for i in 0..<2 {
                let arm = SKShapeNode(rectOf: CGSize(width: 30, height: 1.5))
                arm.fillColor = Theme.hullGray.withAlphaComponent(0.5)
                arm.strokeColor = .clear
                arm.position = CGPoint(x: side * 35, y: CGFloat(i) * 16 - 8)
                station.addChild(arm)

                let panel = SKShapeNode(rectOf: CGSize(width: 8, height: 22))
                panel.fillColor = Theme.retroBlue.withAlphaComponent(0.6)
                panel.strokeColor = Theme.warmGold.withAlphaComponent(0.3)
                panel.lineWidth = 0.5
                panel.position = CGPoint(x: side * 52, y: CGFloat(i) * 16 - 8)
                station.addChild(panel)
            }
        }

        let light = SKShapeNode(circleOfRadius: 2)
        light.fillColor = Theme.nasaOrange
        light.strokeColor = .clear
        light.glowWidth = 6
        light.position = CGPoint(x: 0, y: -12)
        station.addChild(light)

        light.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.2, duration: 0.8),
            SKAction.fadeAlpha(to: 1.0, duration: 0.8),
            SKAction.wait(forDuration: 1.5)
        ])))

        station.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.moveBy(x: 2, y: 4, duration: 6),
            SKAction.moveBy(x: -2, y: -4, duration: 6)
        ])))

        let rotate = SKAction.rotate(byAngle: .pi * 0.02, duration: 10)
        let rotateBack = SKAction.rotate(byAngle: -.pi * 0.02, duration: 10)
        station.run(SKAction.repeatForever(SKAction.sequence([rotate, rotateBack])))

        addChild(station)
    }

    // MARK: - Drifting Debris

    func buildDriftingDebris() {
        for _ in 0..<8 {
            let debris = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...5))
            debris.fillColor = Theme.hullGray.withAlphaComponent(CGFloat.random(in: 0.3...0.6))
            debris.strokeColor = .clear
            debris.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            )
            debris.zPosition = 1

            let speed = Double.random(in: 15...40)
            let sceneSize = size
            let drift = SKAction.sequence([
                SKAction.moveBy(x: -CGFloat(speed), y: CGFloat.random(in: -5...5), duration: 1.0),
                SKAction.run {
                    if debris.position.x < -20 {
                        debris.position.x = sceneSize.width + 20
                        debris.position.y = CGFloat.random(in: 0...sceneSize.height)
                    }
                }
            ])
            debris.run(SKAction.repeatForever(drift))
            debris.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi * CGFloat.random(in: -2...2), duration: Double.random(in: 4...10))))
            addChild(debris)
        }
    }

    // MARK: - Lens Flare

    func buildLensFlare() {
        let sunPos = CGPoint(x: size.width * 0.88, y: size.height * 0.92)

        let sunCore = SKShapeNode(circleOfRadius: 6)
        sunCore.fillColor = SKColor(red: 1.0, green: 0.95, blue: 0.8, alpha: 1.0)
        sunCore.strokeColor = .clear
        sunCore.glowWidth = 30
        sunCore.position = sunPos
        sunCore.zPosition = 3
        addChild(sunCore)

        for i in 0..<8 {
            let angle = CGFloat(i) * (.pi / 4)
            let rayLength = CGFloat.random(in: 30...80)
            let ray = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: sunPos)
            path.addLine(to: CGPoint(x: sunPos.x + cos(angle) * rayLength, y: sunPos.y + sin(angle) * rayLength))
            ray.path = path
            ray.strokeColor = Theme.warmGold.withAlphaComponent(0.15)
            ray.lineWidth = 1.5
            ray.glowWidth = 4
            ray.zPosition = 3
            ray.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.3, duration: Double.random(in: 2...4)),
                SKAction.fadeAlpha(to: 0.8, duration: Double.random(in: 2...4))
            ])))
            addChild(ray)
        }

        let flareColors: [SKColor] = [
            Theme.nasaOrange.withAlphaComponent(0.08),
            Theme.retroBlue.withAlphaComponent(0.06),
            Theme.warmGold.withAlphaComponent(0.05)
        ]
        for i in 1...3 {
            let t = CGFloat(i) * 0.2
            let flare = SKShapeNode(circleOfRadius: CGFloat(i) * 8 + 5)
            flare.fillColor = flareColors[i - 1]
            flare.strokeColor = .clear
            flare.glowWidth = 10
            flare.position = CGPoint(
                x: sunPos.x - t * (sunPos.x - size.width * 0.5),
                y: sunPos.y - t * (sunPos.y - size.height * 0.5)
            )
            flare.zPosition = 3
            addChild(flare)
        }
    }

    // MARK: - Touch Effects

    func spawnThrusterBurst(at position: CGPoint) {
        let colors: [SKColor] = [Theme.nasaOrange, Theme.warmGold, Theme.engineGlow]

        for _ in 0..<15 {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...5))
            particle.fillColor = colors.randomElement()!
            particle.strokeColor = .clear
            particle.glowWidth = 6
            particle.position = position
            particle.zPosition = 15

            let angle = CGFloat.random(in: 0...(.pi * 2))
            let distance = CGFloat.random(in: 40...120)
            let destination = CGPoint(x: position.x + cos(angle) * distance, y: position.y + sin(angle) * distance)

            addChild(particle)
            particle.run(SKAction.sequence([
                SKAction.group([
                    SKAction.move(to: destination, duration: Double.random(in: 0.3...0.7)),
                    SKAction.fadeOut(withDuration: 0.7),
                    SKAction.scale(to: 0.1, duration: 0.7)
                ]),
                SKAction.removeFromParent()
            ]))
        }
    }

    func spawnThrusterTrail(at position: CGPoint) {
        let trail = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...6))
        trail.fillColor = Theme.nasaOrange.withAlphaComponent(0.7)
        trail.strokeColor = .clear
        trail.glowWidth = 8
        trail.position = position
        trail.zPosition = 15

        addChild(trail)
        trail.run(SKAction.sequence([
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.4),
                SKAction.scale(to: 0.01, duration: 0.4)
            ]),
            SKAction.removeFromParent()
        ]))
    }

}
