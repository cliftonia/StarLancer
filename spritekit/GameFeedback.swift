//
//  GameFeedback.swift
//  spritekit
//
//  Handles screen shake, hit flash, and haptic feedback.
//

import SpriteKit
import UIKit

enum GameFeedback {

    // MARK: - Screen Shake

    static func shake(_ scene: SKScene, intensity: CGFloat = 6, duration: Double = 0.3) {
        guard GameSettings.shared.isScreenShakeEnabled else { return }

        let shakeCount = Int(duration / 0.04)
        var actions: [SKAction] = []

        for _ in 0..<shakeCount {
            let dx = CGFloat.random(in: -intensity...intensity)
            let dy = CGFloat.random(in: -intensity...intensity)
            actions.append(SKAction.moveBy(x: dx, y: dy, duration: 0.02))
            actions.append(SKAction.moveBy(x: -dx, y: -dy, duration: 0.02))
        }

        let shakeGroup = SKAction.sequence(actions)

        // Apply to all children (not the scene itself)
        for child in scene.children where child.zPosition < 40 {
            child.run(shakeGroup)
        }
    }

    // MARK: - Hit Flash (white overlay that fades)

    static func hitFlash(_ scene: SKScene, color: SKColor = .white, alpha: CGFloat = 0.2) {
        let flash = SKShapeNode(rectOf: scene.size)
        flash.fillColor = color
        flash.strokeColor = .clear
        flash.position = CGPoint(x: scene.size.width * 0.5, y: scene.size.height * 0.5)
        flash.alpha = alpha
        flash.zPosition = 45
        scene.addChild(flash)

        flash.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.15),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Damage Flash (red tint)

    static func damageFlash(_ scene: SKScene) {
        hitFlash(scene, color: SKColor(red: 1, green: 0, blue: 0, alpha: 1), alpha: 0.15)
    }

    // MARK: - Haptics

    static func lightImpact() {
        guard GameSettings.shared.isHapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    static func mediumImpact() {
        guard GameSettings.shared.isHapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    static func heavyImpact() {
        guard GameSettings.shared.isHapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    static func success() {
        guard GameSettings.shared.isHapticsEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    static func warning() {
        guard GameSettings.shared.isHapticsEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
}
