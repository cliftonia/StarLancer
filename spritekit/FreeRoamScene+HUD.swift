//
//  FreeRoamScene+HUD.swift
//  spritekit
//
//  HUD overlay for free-roam: fuel, resources, MAP button, speed.
//

import SpriteKit

extension FreeRoamScene {

    // MARK: - Build HUD

    func buildHUD() {
        let hudZ: CGFloat = 90
        let padding: CGFloat = 14

        // Top bar background
        let topBar = SKShapeNode(rectOf: CGSize(width: size.width, height: 50))
        topBar.fillColor = SKColor.black.withAlphaComponent(0.5)
        topBar.strokeColor = Theme.hullGray.withAlphaComponent(0.15)
        topBar.lineWidth = 0.5
        topBar.position = CGPoint(x: 0, y: size.height * 0.5 - 25)
        topBar.zPosition = hudZ - 1
        cameraNode.addChild(topBar)

        // Fuel
        let fuelLabel = SKLabelNode(fontNamed: Theme.bodyFont)
        fuelLabel.text = "FUEL \(Int(gameState.player.fuel))"
        fuelLabel.fontSize = 12
        fuelLabel.fontColor = Theme.warmGold
        fuelLabel.horizontalAlignmentMode = .left
        fuelLabel.verticalAlignmentMode = .center
        fuelLabel.position = CGPoint(x: -size.width * 0.5 + padding, y: size.height * 0.5 - 18)
        fuelLabel.zPosition = hudZ
        fuelLabel.name = "fuelLabel"
        cameraNode.addChild(fuelLabel)

        // Credits + Minerals
        let resLabel = SKLabelNode(fontNamed: Theme.captionFont)
        resLabel.text = "CR \(gameState.player.credits)  MIN \(gameState.player.minerals)"
        resLabel.fontSize = 10
        resLabel.fontColor = Theme.warmGold.withAlphaComponent(0.7)
        resLabel.horizontalAlignmentMode = .left
        resLabel.verticalAlignmentMode = .center
        resLabel.position = CGPoint(x: -size.width * 0.5 + padding, y: size.height * 0.5 - 36)
        resLabel.zPosition = hudZ
        resLabel.name = "resLabel"
        cameraNode.addChild(resLabel)

        // Speed indicator
        let speedLabel = SKLabelNode(fontNamed: Theme.captionFont)
        speedLabel.text = "SPD 0"
        speedLabel.fontSize = 9
        speedLabel.fontColor = Theme.retroBlue.withAlphaComponent(0.5)
        speedLabel.horizontalAlignmentMode = .center
        speedLabel.verticalAlignmentMode = .center
        speedLabel.position = CGPoint(x: 0, y: -size.height * 0.5 + 25)
        speedLabel.zPosition = hudZ
        speedLabel.name = "speedLabel"
        cameraNode.addChild(speedLabel)

        // MAP button (top right)
        let mapBtn = SKNode()
        mapBtn.name = "mapButton"
        mapBtn.position = CGPoint(x: size.width * 0.5 - 50, y: size.height * 0.5 - 25)
        mapBtn.zPosition = hudZ

        let mapBg = SKShapeNode(rectOf: CGSize(width: 70, height: 32), cornerRadius: 4)
        mapBg.fillColor = SKColor(red: 0.06, green: 0.06, blue: 0.12, alpha: 0.8)
        mapBg.strokeColor = Theme.retroBlue.withAlphaComponent(0.5)
        mapBg.lineWidth = 1
        mapBg.glowWidth = 2
        mapBg.name = "mapButton"
        mapBtn.addChild(mapBg)

        let mapLabel = SKLabelNode(fontNamed: Theme.bodyFont)
        mapLabel.text = "MAP"
        mapLabel.fontSize = 12
        mapLabel.fontColor = Theme.retroBlue
        mapLabel.verticalAlignmentMode = .center
        mapLabel.name = "mapButton"
        mapBtn.addChild(mapLabel)

        cameraNode.addChild(mapBtn)

        // Planet count
        let playerPlanets = gameState.planets.filter { $0.owner == .player }.count
        let planetLabel = SKLabelNode(fontNamed: Theme.captionFont)
        planetLabel.text = "PLANETS \(playerPlanets)/\(gameState.planets.count)"
        planetLabel.fontSize = 9
        planetLabel.fontColor = Theme.hullGray.withAlphaComponent(0.5)
        planetLabel.horizontalAlignmentMode = .right
        planetLabel.verticalAlignmentMode = .center
        planetLabel.position = CGPoint(x: size.width * 0.5 - padding, y: size.height * 0.5 - 42)
        planetLabel.zPosition = hudZ
        planetLabel.name = "planetLabel"
        cameraNode.addChild(planetLabel)

        // Turn counter
        let turnLabel = SKLabelNode(fontNamed: Theme.captionFont)
        turnLabel.text = "TURN \(gameState.turn)"
        turnLabel.fontSize = 10
        turnLabel.fontColor = Theme.creamWhite.withAlphaComponent(0.6)
        turnLabel.horizontalAlignmentMode = .center
        turnLabel.verticalAlignmentMode = .center
        turnLabel.position = CGPoint(x: 0, y: size.height * 0.5 - 18)
        turnLabel.zPosition = hudZ
        turnLabel.name = "turnLabel"
        cameraNode.addChild(turnLabel)
    }

    // MARK: - Update HUD

    func updateHUD() {
        if let fl = cameraNode.childNode(withName: "fuelLabel") as? SKLabelNode {
            fl.text = "FUEL \(Int(gameState.player.fuel))"
            fl.fontColor = gameState.player.fuel < 20 ? Theme.nasaOrange : Theme.warmGold
        }
        if let rl = cameraNode.childNode(withName: "resLabel") as? SKLabelNode {
            rl.text = "CR \(gameState.player.credits)  MIN \(gameState.player.minerals)"
        }
        if let sl = cameraNode.childNode(withName: "speedLabel") as? SKLabelNode {
            let speed = Int(hypot(shipVelocity.dx, shipVelocity.dy))
            sl.text = "SPD \(speed)"
        }
        if let tl = cameraNode.childNode(withName: "turnLabel") as? SKLabelNode {
            tl.text = "TURN \(gameState.turn)"
        }
        if let pl = cameraNode.childNode(withName: "planetLabel") as? SKLabelNode {
            let count = gameState.planets.filter { $0.owner == .player }.count
            pl.text = "PLANETS \(count)/\(gameState.planets.count)"
        }
    }
}
