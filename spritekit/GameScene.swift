//
//  GameScene.swift
//  spritekit
//
//  Created by Clifton Baggerman on 28/03/2026.
//

import SpriteKit

class GameScene: SKScene {

    var titleLabel: SKLabelNode?
    var menuNode: SKNode?
    var lastUpdateTime: TimeInterval = 0
    var glitchTimer: TimeInterval = 0

    static var hasSavedGame: Bool {
        SaveManager.hasSave
    }

    static func deleteSave() {
        SaveManager.deleteSave()
    }

    // MARK: - Scene Setup

    override func didMove(to view: SKView) {
        BackgroundBuilder.addSpaceBackground(to: self, drift: .horizontal)

        buildPlanet()
        buildOrbitalRings()
        buildSpaceStation()
        buildDriftingDebris()
        buildTitle()
        buildLensFlare()
        buildMenu()
    }

    // MARK: - Title

    func buildTitle() {
        let centerX = size.width * 0.5
        let titleY = size.height * 0.78

        let title = SKLabelNode(fontNamed: Theme.titleFont)
        title.text = "DEEP ORBIT"
        title.fontSize = 44
        title.fontColor = Theme.creamWhite
        title.position = CGPoint(x: centerX, y: titleY)
        title.zPosition = 20
        title.alpha = 0

        let glow = title.copy() as! SKLabelNode
        glow.fontColor = Theme.nasaOrange.withAlphaComponent(0.25)
        glow.zPosition = 19
        glow.setScale(1.06)
        glow.position = title.position
        glow.alpha = 0
        addChild(glow)

        glow.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.fadeIn(withDuration: 1.5),
            SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.1, duration: 2.0),
                SKAction.fadeAlpha(to: 0.3, duration: 2.0)
            ]))
        ]))

        let subtitle = SKLabelNode(fontNamed: Theme.captionFont)
        subtitle.text = "MISSION DESIGNATION: ARTEMIS-VII"
        subtitle.fontSize = 12
        subtitle.fontColor = Theme.warmGold.withAlphaComponent(0.7)
        subtitle.position = CGPoint(x: centerX, y: titleY - 30)
        subtitle.zPosition = 20
        subtitle.alpha = 0

        let status = SKLabelNode(fontNamed: Theme.captionFont)
        status.text = "// AWAITING COMMAND"
        status.fontSize = 11
        status.fontColor = Theme.retroBlue.withAlphaComponent(0.6)
        status.position = CGPoint(x: centerX, y: titleY - 50)
        status.zPosition = 20
        status.alpha = 0

        title.run(SKAction.sequence([SKAction.wait(forDuration: 0.5), SKAction.fadeIn(withDuration: 1.5)]))
        subtitle.run(SKAction.sequence([SKAction.wait(forDuration: 1.2), SKAction.fadeIn(withDuration: 1.0)]))
        status.run(SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.fadeAlpha(to: 0.6, duration: 0.8),
            SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.2, duration: 1.0),
                SKAction.fadeAlpha(to: 0.6, duration: 1.0),
                SKAction.wait(forDuration: 2.0)
            ]))
        ]))

        let lineLength: CGFloat = 60
        let lineY = titleY + 4
        for startX in [centerX - 140, centerX + 80] {
            let line = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: startX, y: lineY))
            path.addLine(to: CGPoint(x: startX + lineLength, y: lineY))
            line.path = path
            line.strokeColor = Theme.nasaOrange.withAlphaComponent(0.4)
            line.lineWidth = 1
            line.glowWidth = 2
            line.zPosition = 20
            addChild(line)
        }

        titleLabel = title
        addChild(title)
        addChild(subtitle)
        addChild(status)
    }

    // MARK: - Menu

    func buildMenu() {
        let menu = SKNode()
        menu.zPosition = 60

        let centerX = size.width * 0.5
        var buttonY = size.height * 0.48

        if GameScene.hasSavedGame {
            menu.addChild(Theme.makeMenuButton(text: "CONTINUE MISSION", name: "continueButton", position: CGPoint(x: centerX, y: buttonY)))
            buttonY -= 65
        }

        menu.addChild(Theme.makeMenuButton(text: "NEW MISSION", name: "startButton", position: CGPoint(x: centerX, y: buttonY)))
        buttonY -= 65

        menu.addChild(Theme.makeMenuButton(text: "SETTINGS", name: "settingsButton", position: CGPoint(x: centerX, y: buttonY)))

        menuNode = menu
        menu.alpha = 0
        addChild(menu)

        menu.run(SKAction.sequence([
            SKAction.wait(forDuration: 2.5),
            SKAction.fadeIn(withDuration: 1.0)
        ]))
    }

    // MARK: - Touch Interaction

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tappedNodes = nodes(at: location)

        for node in tappedNodes {
            switch node.name {
            case "startButton":
                if let button = menuNode?.childNode(withName: "startButton") {
                    Theme.animateButtonPress(button) { [weak self] in self?.startNewGame() }
                }
                return
            case "continueButton":
                if let button = menuNode?.childNode(withName: "continueButton") {
                    Theme.animateButtonPress(button) { [weak self] in self?.continueGame() }
                }
                return
            case "settingsButton":
                if let button = menuNode?.childNode(withName: "settingsButton") {
                    Theme.animateButtonPress(button) { [weak self] in self?.openSettings() }
                }
                return
            default:
                break
            }
        }

        spawnThrusterBurst(at: location)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            spawnThrusterTrail(at: touch.location(in: self))
        }
    }

    // MARK: - Game Actions

    func startNewGame() {
        let state = GalaxyGenerator.generate()
        let galaxyMap = GalaxyMapScene(size: size)
        galaxyMap.scaleMode = .resizeFill
        galaxyMap.gameState = state
        view?.presentScene(galaxyMap, transition: SKTransition.fade(withDuration: 0.8))
    }

    func continueGame() {
        guard let state = SaveManager.load() else { return }
        let galaxyMap = GalaxyMapScene(size: size)
        galaxyMap.scaleMode = .resizeFill
        galaxyMap.gameState = state
        view?.presentScene(galaxyMap, transition: SKTransition.fade(withDuration: 0.8))
    }

    func openSettings() {
        let settingsScene = SettingsScene(size: size)
        settingsScene.scaleMode = .resizeFill
        view?.presentScene(settingsScene, transition: SKTransition.fade(withDuration: 0.6))
    }

    // MARK: - Update Loop

    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 { lastUpdateTime = currentTime }
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        glitchTimer += deltaTime
        if glitchTimer > Double.random(in: 4.0...8.0) {
            glitchTimer = 0
            triggerCommFlicker()
        }
    }

    func triggerCommFlicker() {
        guard let label = titleLabel else { return }

        let originalPosition = label.position
        let staticTexts = ["D33P 0RB1T", "DEEP_ORB--", "DE%P ORBIT", "DEEP ORBIT"]

        label.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.03),
            SKAction.run { label.text = staticTexts.randomElement()! },
            SKAction.fadeAlpha(to: 1.0, duration: 0.05),
            SKAction.moveBy(x: CGFloat.random(in: -3...3), y: 0, duration: 0.04),
            SKAction.wait(forDuration: 0.06),
            SKAction.fadeAlpha(to: 0.5, duration: 0.03),
            SKAction.run { label.text = "DEEP ORBIT" },
            SKAction.fadeAlpha(to: 1.0, duration: 0.08),
            SKAction.move(to: originalPosition, duration: 0.04)
        ]))
    }
}
