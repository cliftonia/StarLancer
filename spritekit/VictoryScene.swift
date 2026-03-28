//
//  VictoryScene.swift
//  spritekit
//
//  Created by Clifton Baggerman on 28/03/2026.
//

import SpriteKit

class VictoryScene: SKScene {

    var isVictory: Bool = true
    var gameState: GameState?

    override func didMove(to view: SKView) {
        BackgroundBuilder.addSpaceBackground(to: self, drift: .none, nebula: true)

        let centerX = size.width * 0.5

        // Title
        let title = SKLabelNode(fontNamed: Theme.titleFont)
        title.text = isVictory ? "MISSION COMPLETE" : "MISSION FAILED"
        title.fontSize = 32
        title.fontColor = isVictory ? Theme.onGreen : Theme.nasaOrange
        title.position = CGPoint(x: centerX, y: size.height * 0.72)
        title.zPosition = 20
        title.alpha = 0
        addChild(title)

        // Glow
        let glow = title.copy() as! SKLabelNode
        glow.fontColor = (isVictory ? Theme.onGreen : Theme.nasaOrange).withAlphaComponent(0.2)
        glow.setScale(1.06)
        glow.zPosition = 19
        glow.alpha = 0
        addChild(glow)

        title.run(SKAction.sequence([SKAction.wait(forDuration: 0.5), SKAction.fadeIn(withDuration: 1.0)]))
        glow.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.fadeIn(withDuration: 1.0),
            SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.1, duration: 2),
                SKAction.fadeAlpha(to: 0.3, duration: 2)
            ]))
        ]))

        // Subtitle
        let subtitle = SKLabelNode(fontNamed: Theme.captionFont)
        subtitle.text = isVictory ? "// ALL OBJECTIVES ACHIEVED" : "// TERRITORY LOST"
        subtitle.fontSize = 11
        subtitle.fontColor = Theme.retroBlue.withAlphaComponent(0.6)
        subtitle.position = CGPoint(x: centerX, y: size.height * 0.72 - 30)
        subtitle.zPosition = 20
        subtitle.alpha = 0
        addChild(subtitle)
        subtitle.run(SKAction.sequence([SKAction.wait(forDuration: 1.0), SKAction.fadeIn(withDuration: 0.8)]))

        // Stats
        if let state = gameState {
            let playerPlanets = state.planets.filter { $0.owner == .player }.count
            let totalPlanets = state.planets.count
            let turns = state.turn

            let stats: [(label: String, value: String)] = [
                ("TURNS SURVIVED", "\(turns)"),
                ("PLANETS HELD", "\(playerPlanets)/\(totalPlanets)"),
                ("CREDITS", "\(state.player.credits)"),
                ("FLEET SIZE", "\(state.player.totalShips)")
            ]

            let startY = size.height * 0.52
            for (i, stat) in stats.enumerated() {
                let y = startY - CGFloat(i) * 30

                let label = SKLabelNode(fontNamed: Theme.captionFont)
                label.text = stat.label
                label.fontSize = 11
                label.fontColor = Theme.hullGray.withAlphaComponent(0.7)
                label.horizontalAlignmentMode = .left
                label.position = CGPoint(x: centerX - 100, y: y)
                label.zPosition = 20
                label.alpha = 0
                addChild(label)

                let value = SKLabelNode(fontNamed: Theme.bodyFont)
                value.text = stat.value
                value.fontSize = 14
                value.fontColor = Theme.warmGold
                value.horizontalAlignmentMode = .right
                value.position = CGPoint(x: centerX + 100, y: y)
                value.zPosition = 20
                value.alpha = 0
                addChild(value)

                let delay = 1.5 + Double(i) * 0.3
                label.run(SKAction.sequence([SKAction.wait(forDuration: delay), SKAction.fadeIn(withDuration: 0.4)]))
                value.run(SKAction.sequence([SKAction.wait(forDuration: delay), SKAction.fadeIn(withDuration: 0.4)]))
            }
        }

        // Main menu button
        let menuBtn = Theme.makeMenuButton(
            text: "RETURN TO BASE",
            name: "menuButton",
            position: CGPoint(x: centerX, y: size.height * 0.22)
        )
        menuBtn.zPosition = 30
        menuBtn.alpha = 0
        addChild(menuBtn)
        menuBtn.run(SKAction.sequence([SKAction.wait(forDuration: 3.0), SKAction.fadeIn(withDuration: 0.8)]))
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tapped = nodes(at: location)

        for node in tapped where node.name == "menuButton" {
            // Delete save on game end
            SaveManager.deleteSave()

            let menu = GameScene(size: size)
            menu.scaleMode = .resizeFill
            view?.presentScene(menu, transition: SKTransition.fade(withDuration: 0.8))
            return
        }
    }
}
