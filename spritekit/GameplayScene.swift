//
//  GameplayScene.swift
//  spritekit
//
//  Created by Clifton Baggerman on 28/03/2026.
//

import SpriteKit
import CoreMotion

class GameplayScene: SKScene, SKPhysicsContactDelegate {

    // MARK: - Physics Categories

    struct Category {
        static let player: UInt32 = 0x1 << 0
        static let bullet: UInt32 = 0x1 << 1
        static let asteroid: UInt32 = 0x1 << 2
        static let enemy: UInt32 = 0x1 << 3
        static let loot: UInt32 = 0x1 << 4
        static let enemyFire: UInt32 = 0x1 << 5
    }

    // MARK: - Colors

    let creamWhite = Theme.creamWhite
    let nasaOrange = Theme.nasaOrange
    let deepSpace  = Theme.deepSpace
    let retroBlue  = Theme.retroBlue
    let warmGold   = Theme.warmGold
    let engineGlow = Theme.engineGlow
    let hullGray   = Theme.hullGray
    let shieldBlue = Theme.shieldBlue

    // MARK: - Combat Context

    var combatContext: CombatContext?
    var gameState: GameState?
    var onCombatComplete: ((CombatResult) -> Void)?

    var currentWave: Int = 0
    var totalWaves: Int = 5
    var enemiesRemainingInWave: Int = 0
    var waveInProgress = false
    var waveLabel: SKLabelNode?
    var retreatButton: SKNode?
    var isWaveBased: Bool { combatContext != nil }

    // Fleet modifiers
    var fireRateMultiplier: Double = 1.0
    var bonusHP: Int = 0
    var hasTroopTransport: Bool = false
    var missileCarrierCount: Int = 0
    var missileTimer: TimeInterval = 0

    // MARK: - Game State

    var playerShip: SKNode!
    var engineEmitter: SKEmitterNode?
    var shieldNode: SKShapeNode?

    var health: Int = 100
    var fuel: Double = 100.0
    var score: Int = 0
    var credits: Int = 0
    var shieldHP: Int = 50

    var healthLabel: SKLabelNode?
    var fuelBar: SKShapeNode?
    var fuelBarBg: SKShapeNode?
    var scoreLabel: SKLabelNode?
    var creditsLabel: SKLabelNode?
    var shieldLabel: SKLabelNode?
    var speedLabel: SKLabelNode?

    var lastUpdateTime: TimeInterval = 0
    var asteroidTimer: TimeInterval = 0
    var enemyTimer: TimeInterval = 0
    var fuelTimer: TimeInterval = 0

    var isTouching = false
    var touchLocation: CGPoint = .zero
    var isGameOver = false

    let motionManager = CMMotionManager()
    var shipSpeed: CGFloat = 0

    // Active power-ups
    var rapidFireActive = false
    var speedBoostActive = false

    // Weapon level: 0 = single, 1 = dual, 2 = spread
    var weaponLevel: Int = 0

    // Combo system
    var comboCount: Int = 0
    var comboTimer: TimeInterval = 0
    var scoreMultiplier: Int { max(1, comboCount / 3 + 1) }
    var comboLabel: SKLabelNode?

    // Pause
    var isPaused2 = false
    var pauseOverlay: SKNode?

    // MARK: - Scene Setup

    override func didMove(to view: SKView) {
        BackgroundBuilder.addSpaceBackground(to: self, drift: .vertical, nebula: true, scanlines: false)

        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self

        if let ctx = combatContext {
            totalWaves = ctx.waveCount
            currentWave = 0
        }

        applyFleetModifiers()

        buildPlayer()
        buildHUD()
        buildWaveHUD()
        buildRetreatButton()
        buildPauseButton()
        startGyroscope()

        if isWaveBased {
            showMissionBriefing()
        }
    }

    override func willMove(from view: SKView) {
        motionManager.stopDeviceMotionUpdates()
    }

    func startGyroscope() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates()
    }
}
