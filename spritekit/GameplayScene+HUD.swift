//
//  GameplayScene+HUD.swift
//  spritekit
//

import SpriteKit

extension GameplayScene {

    // MARK: - Build HUD

    func buildHUD() {
        let hudZ: CGFloat = 40
        let topY = size.height - 50
        let padding: CGFloat = 16

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

    func updateHUD() {
        healthLabel?.text = "HULL \(max(0, health))%"
        healthLabel?.fontColor = health <= 25 ? nasaOrange : creamWhite

        shieldLabel?.text = "SHLD \(max(0, shieldHP))"
        shieldLabel?.fontColor = shieldHP > 0 ? shieldBlue.withAlphaComponent(0.7) : hullGray.withAlphaComponent(0.3)
        shieldNode?.alpha = shieldHP > 0 ? CGFloat(shieldHP) / 100.0 : 0

        fuelBar?.xScale = max(0.01, CGFloat(fuel / 100.0))
        fuelBar?.fillColor = fuel < 20 ? nasaOrange : warmGold

        scoreLabel?.text = "\(score)"
        creditsLabel?.text = "CR \(credits)"
        speedLabel?.text = String(format: "SPD %.1f", shipSpeed)
    }

    // MARK: - Wave HUD

    func buildWaveHUD() {
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

        let barWidth: CGFloat = 160
        let barBg = SKShapeNode(rectOf: CGSize(width: barWidth, height: 6), cornerRadius: 3)
        barBg.fillColor = SKColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 0.8)
        barBg.strokeColor = hullGray.withAlphaComponent(0.3)
        barBg.lineWidth = 0.5
        barBg.position = CGPoint(x: size.width * 0.5, y: size.height - 82)
        barBg.zPosition = 40
        barBg.name = "waveBarBg"
        addChild(barBg)

        let barFill = SKShapeNode(rectOf: CGSize(width: 4, height: 4), cornerRadius: 2)
        barFill.fillColor = nasaOrange
        barFill.strokeColor = .clear
        barFill.position = CGPoint(x: size.width * 0.5 - barWidth * 0.5 + 2, y: size.height - 82)
        barFill.zPosition = 41
        barFill.name = "waveBarFill"
        addChild(barFill)
    }

    func updateWaveProgressBar() {
        guard isWaveBased, let fill = childNode(withName: "waveBarFill") as? SKShapeNode else { return }

        let progress = CGFloat(currentWave) / CGFloat(totalWaves)
        let barWidth: CGFloat = 156
        let fillWidth = max(4, barWidth * progress)

        let newFill = SKShapeNode(rectOf: CGSize(width: fillWidth, height: 4), cornerRadius: 2)
        newFill.fillColor = nasaOrange
        newFill.strokeColor = .clear
        newFill.position = CGPoint(x: size.width * 0.5 - 78 + fillWidth * 0.5, y: size.height - 82)
        newFill.zPosition = 41
        newFill.name = "waveBarFill"

        fill.removeFromParent()
        addChild(newFill)
    }

    // MARK: - Retreat Button

    func buildRetreatButton() {
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

    // MARK: - Pause Button

    func buildPauseButton() {
        let btn = SKNode()
        btn.name = "pauseButton"
        btn.position = CGPoint(x: 40, y: size.height - 50)
        btn.zPosition = 45

        let bg = SKShapeNode(rectOf: CGSize(width: 36, height: 36), cornerRadius: 4)
        bg.fillColor = SKColor(red: 0.06, green: 0.06, blue: 0.1, alpha: 0.7)
        bg.strokeColor = creamWhite.withAlphaComponent(0.3)
        bg.lineWidth = 1
        bg.name = "pauseButton"
        btn.addChild(bg)

        for offset in [-5.0, 5.0] {
            let bar = SKShapeNode(rectOf: CGSize(width: 4, height: 16))
            bar.fillColor = creamWhite
            bar.strokeColor = .clear
            bar.position = CGPoint(x: offset, y: 0)
            bar.name = "pauseButton"
            btn.addChild(bar)
        }

        addChild(btn)
    }

    func togglePause() {
        isPaused2.toggle()

        if isPaused2 {
            scene?.isPaused = true

            let overlay = SKNode()
            overlay.zPosition = 90

            let dim = SKShapeNode(rectOf: size)
            dim.fillColor = SKColor.black.withAlphaComponent(0.6)
            dim.strokeColor = .clear
            dim.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
            overlay.addChild(dim)

            let title = SKLabelNode(fontNamed: "Helvetica-Bold")
            title.text = "PAUSED"
            title.fontSize = 36
            title.fontColor = creamWhite
            title.position = CGPoint(x: size.width * 0.5, y: size.height * 0.55)
            overlay.addChild(title)

            let resumeBtn = Theme.makeMenuButton(
                text: "RESUME",
                name: "resumeButton",
                position: CGPoint(x: size.width * 0.5, y: size.height * 0.42)
            )
            overlay.addChild(resumeBtn)

            let quitBtn = Theme.makeMenuButton(
                text: "QUIT TO MENU",
                name: "quitButton",
                position: CGPoint(x: size.width * 0.5, y: size.height * 0.42 - 60),
                accentColor: Theme.offRed
            )
            overlay.addChild(quitBtn)

            pauseOverlay = overlay
            addChild(overlay)
        } else {
            scene?.isPaused = false
            pauseOverlay?.removeFromParent()
            pauseOverlay = nil
        }
    }
}
