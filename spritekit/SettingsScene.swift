//
//  SettingsScene.swift
//  spritekit
//
//  Created by Clifton Baggerman on 28/03/2026.
//

import SpriteKit

class SettingsScene: SKScene {

    private let settings = GameSettings.shared

    private var toggles: [(label: String, keyPath: ReferenceWritableKeyPath<GameSettings, Bool>, node: SKNode?)] = []
    private var lastUpdateTime: TimeInterval = 0

    // MARK: - Colors (Theme aliases)

    private let creamWhite = Theme.creamWhite
    private let nasaOrange = Theme.nasaOrange
    private let deepSpace  = Theme.deepSpace
    private let retroBlue  = Theme.retroBlue
    private let warmGold   = Theme.warmGold
    private let hullGray   = Theme.hullGray
    private let onGreen    = Theme.onGreen
    private let offRed     = Theme.offRed

    // MARK: - Scene Setup

    override func didMove(to view: SKView) {
        BackgroundBuilder.addSpaceBackground(to: self, drift: .none, nebula: false)

        buildHeader()
        buildToggles()
        buildBackButton()
        buildDeleteSaveButton()
    }

    // MARK: - Header

    private func buildHeader() {
        let centerX = size.width * 0.5

        // Title
        let title = SKLabelNode(fontNamed: "Helvetica-Bold")
        title.text = "SETTINGS"
        title.fontSize = 34
        title.fontColor = creamWhite
        title.position = CGPoint(x: centerX, y: size.height - 80)
        title.zPosition = 20
        addChild(title)

        // Subtitle
        let subtitle = SKLabelNode(fontNamed: "Courier")
        subtitle.text = "// SYSTEM CONFIGURATION"
        subtitle.fontSize = 11
        subtitle.fontColor = retroBlue.withAlphaComponent(0.6)
        subtitle.position = CGPoint(x: centerX, y: size.height - 105)
        subtitle.zPosition = 20
        addChild(subtitle)

        // Decorative lines
        let lineY = size.height - 76
        for (startX, endX) in [(centerX - 130, centerX - 70), (centerX + 70, centerX + 130)] {
            let line = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: startX, y: lineY))
            path.addLine(to: CGPoint(x: endX, y: lineY))
            line.path = path
            line.strokeColor = nasaOrange.withAlphaComponent(0.4)
            line.lineWidth = 1
            line.glowWidth = 2
            line.zPosition = 20
            addChild(line)
        }

        // Separator line below header
        let sep = SKShapeNode()
        let sepPath = CGMutablePath()
        sepPath.move(to: CGPoint(x: centerX - 140, y: size.height - 120))
        sepPath.addLine(to: CGPoint(x: centerX + 140, y: size.height - 120))
        sep.path = sepPath
        sep.strokeColor = hullGray.withAlphaComponent(0.2)
        sep.lineWidth = 0.5
        sep.zPosition = 20
        addChild(sep)
    }

    // MARK: - Toggles

    private func buildToggles() {
        toggles = [
            ("SOUND FX", \GameSettings.isSoundFXEnabled, nil),
            ("MUSIC", \GameSettings.isMusicEnabled, nil),
            ("HAPTICS", \GameSettings.isHapticsEnabled, nil),
            ("SCREEN SHAKE", \GameSettings.isScreenShakeEnabled, nil),
            ("NOTIFICATIONS", \GameSettings.isNotificationsEnabled, nil)
        ]

        let startY = size.height - 165
        let rowHeight: CGFloat = 60

        for i in 0..<toggles.count {
            let y = startY - CGFloat(i) * rowHeight
            let row = makeToggleRow(
                label: toggles[i].label,
                isOn: settings[keyPath: toggles[i].keyPath],
                name: "toggle_\(i)",
                position: CGPoint(x: size.width * 0.5, y: y)
            )
            toggles[i].node = row
            addChild(row)
        }
    }

    private func makeToggleRow(label: String, isOn: Bool, name: String, position: CGPoint) -> SKNode {
        let container = SKNode()
        container.name = name
        container.position = position
        container.zPosition = 30

        // Row background
        let bg = SKShapeNode(rectOf: CGSize(width: 280, height: 44), cornerRadius: 3)
        bg.fillColor = SKColor(red: 0.06, green: 0.06, blue: 0.1, alpha: 0.6)
        bg.strokeColor = hullGray.withAlphaComponent(0.15)
        bg.lineWidth = 0.5
        bg.name = name
        container.addChild(bg)

        // Label on left
        let textLabel = SKLabelNode(fontNamed: "Courier-Bold")
        textLabel.text = label
        textLabel.fontSize = 14
        textLabel.fontColor = creamWhite.withAlphaComponent(0.85)
        textLabel.horizontalAlignmentMode = .left
        textLabel.verticalAlignmentMode = .center
        textLabel.position = CGPoint(x: -125, y: 0)
        textLabel.name = name
        container.addChild(textLabel)

        // Toggle switch on right
        let toggleBg = SKShapeNode(rectOf: CGSize(width: 50, height: 24), cornerRadius: 12)
        toggleBg.fillColor = isOn ? onGreen.withAlphaComponent(0.3) : SKColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 0.8)
        toggleBg.strokeColor = isOn ? onGreen.withAlphaComponent(0.6) : hullGray.withAlphaComponent(0.3)
        toggleBg.lineWidth = 1
        toggleBg.glowWidth = isOn ? 3 : 0
        toggleBg.position = CGPoint(x: 105, y: 0)
        toggleBg.name = name + "_bg"
        container.addChild(toggleBg)

        // Toggle knob
        let knob = SKShapeNode(circleOfRadius: 9)
        knob.fillColor = isOn ? onGreen : hullGray
        knob.strokeColor = .clear
        knob.glowWidth = isOn ? 4 : 0
        knob.position = CGPoint(x: isOn ? 117 : 93, y: 0)
        knob.name = name + "_knob"
        container.addChild(knob)

        // Status text
        let statusLabel = SKLabelNode(fontNamed: "Courier")
        statusLabel.text = isOn ? "ON" : "OFF"
        statusLabel.fontSize = 9
        statusLabel.fontColor = isOn ? onGreen : offRed.withAlphaComponent(0.6)
        statusLabel.horizontalAlignmentMode = .right
        statusLabel.verticalAlignmentMode = .center
        statusLabel.position = CGPoint(x: 72, y: 0)
        statusLabel.name = name + "_status"
        container.addChild(statusLabel)

        return container
    }

    private func updateToggleVisual(index: Int, isOn: Bool) {
        guard let container = toggles[index].node else { return }
        let name = "toggle_\(index)"

        guard let bg = container.childNode(withName: name + "_bg") as? SKShapeNode,
              let knob = container.childNode(withName: name + "_knob") as? SKShapeNode,
              let statusLabel = container.childNode(withName: name + "_status") as? SKLabelNode else { return }

        let moveKnob = SKAction.moveTo(x: isOn ? 117 : 93, duration: 0.15)
        moveKnob.timingMode = .easeInEaseOut
        knob.run(moveKnob)

        knob.fillColor = isOn ? onGreen : hullGray
        knob.glowWidth = isOn ? 4 : 0

        bg.fillColor = isOn ? onGreen.withAlphaComponent(0.3) : SKColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 0.8)
        bg.strokeColor = isOn ? onGreen.withAlphaComponent(0.6) : hullGray.withAlphaComponent(0.3)
        bg.glowWidth = isOn ? 3 : 0

        statusLabel.text = isOn ? "ON" : "OFF"
        statusLabel.fontColor = isOn ? onGreen : offRed.withAlphaComponent(0.6)
    }

    // MARK: - Back Button

    private func buildBackButton() {
        let container = SKNode()
        container.name = "backButton"
        container.position = CGPoint(x: size.width * 0.5, y: 100)
        container.zPosition = 30

        let border = SKShapeNode(rectOf: CGSize(width: 200, height: 42), cornerRadius: 3)
        border.strokeColor = creamWhite.withAlphaComponent(0.4)
        border.fillColor = SKColor(red: 0.06, green: 0.06, blue: 0.1, alpha: 0.7)
        border.lineWidth = 1
        border.glowWidth = 2
        border.name = "backButton"
        container.addChild(border)

        let accent = SKShapeNode(rectOf: CGSize(width: 3, height: 42))
        accent.fillColor = retroBlue
        accent.strokeColor = .clear
        accent.glowWidth = 3
        accent.position = CGPoint(x: -98.5, y: 0)
        accent.name = "backButton"
        container.addChild(accent)

        let label = SKLabelNode(fontNamed: "Courier-Bold")
        label.text = "< BACK"
        label.fontSize = 15
        label.fontColor = creamWhite
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.name = "backButton"
        container.addChild(label)

        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.75, duration: 1.5),
            SKAction.fadeAlpha(to: 1.0, duration: 1.5)
        ])
        container.run(SKAction.repeatForever(pulse))

        addChild(container)
    }

    // MARK: - Delete Save Button

    private func buildDeleteSaveButton() {
        let container = SKNode()
        container.name = "deleteButton"
        container.position = CGPoint(x: size.width * 0.5, y: 48)
        container.zPosition = 30

        let label = SKLabelNode(fontNamed: "Courier")
        label.text = "DELETE SAVE DATA"
        label.fontSize = 11
        label.fontColor = offRed.withAlphaComponent(0.5)
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.name = "deleteButton"
        container.addChild(label)

        addChild(container)
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tappedNodes = nodes(at: location)

        for node in tappedNodes {
            guard let name = node.name else { continue }

            // Back button
            if name == "backButton" {
                navigateBack()
                return
            }

            // Delete save
            if name == "deleteButton" {
                confirmDeleteSave()
                return
            }

            // Toggle rows
            if name.hasPrefix("toggle_") {
                let indexString = name.replacingOccurrences(of: "toggle_", with: "")
                    .components(separatedBy: "_").first ?? ""
                if let index = Int(indexString), index < toggles.count {
                    let keyPath = toggles[index].keyPath
                    let newValue = !settings[keyPath: keyPath]
                    settings[keyPath: keyPath] = newValue
                    updateToggleVisual(index: index, isOn: newValue)
                    return
                }
            }
        }
    }

    // MARK: - Navigation

    private func navigateBack() {
        let mainMenu = GameScene(size: size)
        mainMenu.scaleMode = .resizeFill
        let transition = SKTransition.fade(withDuration: 0.6)
        view?.presentScene(mainMenu, transition: transition)
    }

    // MARK: - Delete Save Confirmation

    private func confirmDeleteSave() {
        // Check if confirmation is already showing
        if childNode(withName: "confirmOverlay") != nil { return }

        let overlay = SKNode()
        overlay.name = "confirmOverlay"
        overlay.zPosition = 80

        // Dimmed background
        let dim = SKShapeNode(rectOf: size)
        dim.fillColor = SKColor.black.withAlphaComponent(0.7)
        dim.strokeColor = .clear
        dim.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        dim.name = "confirmDismiss"
        overlay.addChild(dim)

        // Dialog box
        let dialog = SKShapeNode(rectOf: CGSize(width: 260, height: 160), cornerRadius: 4)
        dialog.fillColor = SKColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 0.95)
        dialog.strokeColor = offRed.withAlphaComponent(0.5)
        dialog.lineWidth = 1
        dialog.glowWidth = 4
        dialog.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        overlay.addChild(dialog)

        // Warning text
        let warning = SKLabelNode(fontNamed: "Courier-Bold")
        warning.text = "WARNING"
        warning.fontSize = 18
        warning.fontColor = offRed
        warning.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5 + 45)
        warning.zPosition = 81
        overlay.addChild(warning)

        let message = SKLabelNode(fontNamed: "Courier")
        message.text = "Erase all save data?"
        message.fontSize = 13
        message.fontColor = creamWhite.withAlphaComponent(0.8)
        message.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5 + 15)
        message.zPosition = 81
        overlay.addChild(message)

        let subMessage = SKLabelNode(fontNamed: "Courier")
        subMessage.text = "This cannot be undone."
        subMessage.fontSize = 11
        subMessage.fontColor = hullGray.withAlphaComponent(0.6)
        subMessage.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5 - 5)
        subMessage.zPosition = 81
        overlay.addChild(subMessage)

        // Confirm button
        let confirmBtn = SKNode()
        confirmBtn.name = "confirmDelete"
        confirmBtn.position = CGPoint(x: size.width * 0.5 - 55, y: size.height * 0.5 - 45)
        confirmBtn.zPosition = 81

        let confirmBg = SKShapeNode(rectOf: CGSize(width: 90, height: 34), cornerRadius: 3)
        confirmBg.fillColor = offRed.withAlphaComponent(0.3)
        confirmBg.strokeColor = offRed.withAlphaComponent(0.6)
        confirmBg.lineWidth = 1
        confirmBg.name = "confirmDelete"
        confirmBtn.addChild(confirmBg)

        let confirmLabel = SKLabelNode(fontNamed: "Courier-Bold")
        confirmLabel.text = "ERASE"
        confirmLabel.fontSize = 13
        confirmLabel.fontColor = offRed
        confirmLabel.verticalAlignmentMode = .center
        confirmLabel.name = "confirmDelete"
        confirmBtn.addChild(confirmLabel)

        overlay.addChild(confirmBtn)

        // Cancel button
        let cancelBtn = SKNode()
        cancelBtn.name = "confirmDismiss"
        cancelBtn.position = CGPoint(x: size.width * 0.5 + 55, y: size.height * 0.5 - 45)
        cancelBtn.zPosition = 81

        let cancelBg = SKShapeNode(rectOf: CGSize(width: 90, height: 34), cornerRadius: 3)
        cancelBg.fillColor = SKColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 0.8)
        cancelBg.strokeColor = creamWhite.withAlphaComponent(0.3)
        cancelBg.lineWidth = 1
        cancelBg.name = "confirmDismiss"
        cancelBtn.addChild(cancelBg)

        let cancelLabel = SKLabelNode(fontNamed: "Courier-Bold")
        cancelLabel.text = "CANCEL"
        cancelLabel.fontSize = 13
        cancelLabel.fontColor = creamWhite.withAlphaComponent(0.7)
        cancelLabel.verticalAlignmentMode = .center
        cancelLabel.name = "confirmDismiss"
        cancelBtn.addChild(cancelLabel)

        overlay.addChild(cancelBtn)

        overlay.alpha = 0
        addChild(overlay)
        overlay.run(SKAction.fadeIn(withDuration: 0.2))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tappedNodes = nodes(at: location)

        for node in tappedNodes {
            guard let name = node.name else { continue }

            if name == "confirmDelete" {
                GameScene.deleteSave()
                if let overlay = childNode(withName: "confirmOverlay") {
                    overlay.run(SKAction.sequence([
                        SKAction.fadeOut(withDuration: 0.2),
                        SKAction.removeFromParent()
                    ]))
                }
                // Flash confirmation
                let flash = SKLabelNode(fontNamed: "Courier")
                flash.text = "SAVE DATA ERASED"
                flash.fontSize = 12
                flash.fontColor = onGreen
                flash.position = CGPoint(x: size.width * 0.5, y: 48)
                flash.zPosition = 30
                addChild(flash)
                flash.run(SKAction.sequence([
                    SKAction.wait(forDuration: 1.5),
                    SKAction.fadeOut(withDuration: 0.5),
                    SKAction.removeFromParent()
                ]))
                return
            }

            if name == "confirmDismiss" {
                if let overlay = childNode(withName: "confirmOverlay") {
                    overlay.run(SKAction.sequence([
                        SKAction.fadeOut(withDuration: 0.2),
                        SKAction.removeFromParent()
                    ]))
                }
                return
            }
        }
    }

    // MARK: - Update

    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 { lastUpdateTime = currentTime }
        lastUpdateTime = currentTime
    }
}
