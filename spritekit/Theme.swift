//
//  Theme.swift
//  spritekit
//
//  Created by Clifton Baggerman on 28/03/2026.
//

import SpriteKit

enum Theme {

    // MARK: - Colors

    static let creamWhite = SKColor(red: 0.93, green: 0.91, blue: 0.87, alpha: 1.0)
    static let nasaOrange = SKColor(red: 1.0, green: 0.45, blue: 0.1, alpha: 1.0)
    static let deepSpace  = SKColor(red: 0.02, green: 0.02, blue: 0.05, alpha: 1.0)
    static let retroBlue  = SKColor(red: 0.2, green: 0.5, blue: 0.8, alpha: 1.0)
    static let warmGold   = SKColor(red: 0.95, green: 0.75, blue: 0.3, alpha: 1.0)
    static let engineGlow = SKColor(red: 1.0, green: 0.3, blue: 0.05, alpha: 1.0)
    static let hullGray   = SKColor(red: 0.6, green: 0.62, blue: 0.65, alpha: 1.0)
    static let shieldBlue = SKColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 1.0)
    static let onGreen    = SKColor(red: 0.15, green: 0.85, blue: 0.45, alpha: 1.0)
    static let offRed     = SKColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0)

    // MARK: - Fonts

    static let titleFont   = "Helvetica-Bold"
    static let bodyFont    = "Courier-Bold"
    static let captionFont = "Courier"

    // MARK: - Menu Button Builder

    static func makeMenuButton(
        text: String,
        name: String,
        position: CGPoint,
        accentColor: SKColor = nasaOrange
    ) -> SKNode {
        let container = SKNode()
        container.name = name
        container.position = position

        let border = SKShapeNode(rectOf: CGSize(width: 240, height: 46), cornerRadius: 3)
        border.strokeColor = creamWhite.withAlphaComponent(0.5)
        border.fillColor = SKColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 0.7)
        border.lineWidth = 1.0
        border.glowWidth = 2
        border.name = name
        container.addChild(border)

        let accent = SKShapeNode(rectOf: CGSize(width: 3, height: 46))
        accent.fillColor = accentColor
        accent.strokeColor = .clear
        accent.glowWidth = 4
        accent.position = CGPoint(x: -118.5, y: 0)
        accent.name = name
        container.addChild(accent)

        let label = SKLabelNode(fontNamed: bodyFont)
        label.text = text
        label.fontSize = 16
        label.fontColor = creamWhite
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.name = name
        container.addChild(label)

        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.75, duration: 1.5),
            SKAction.fadeAlpha(to: 1.0, duration: 1.5)
        ])
        container.run(SKAction.repeatForever(pulse))

        return container
    }

    // MARK: - Button Press Animation

    static func animateButtonPress(_ node: SKNode, completion: @escaping () -> Void) {
        let flash = SKAction.sequence([
            SKAction.scale(to: 0.94, duration: 0.05),
            SKAction.scale(to: 1.06, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.05)
        ])
        node.run(flash) { completion() }
    }
}
