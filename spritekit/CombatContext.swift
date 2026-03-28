//
//  CombatContext.swift
//  spritekit
//
//  Created by Clifton Baggerman on 28/03/2026.
//

import Foundation

enum CombatResult {
    case victory
    case retreat
    case defeat
}

struct CombatContext {
    let targetPlanetID: UUID
    let targetPlanetName: String
    let enemyFaction: Faction?
    let waveCount: Int
    let difficultyMultiplier: Double
    let creditsReward: Int
    let mineralsReward: Int

    static func forPlanet(_ planet: Planet) -> CombatContext {
        let defense = planet.defenseStrength
        let waves = max(2, min(6, defense / 5 + 1))
        let difficulty = 0.5 + Double(defense) / 50.0

        return CombatContext(
            targetPlanetID: planet.id,
            targetPlanetName: planet.name,
            enemyFaction: planet.owner,
            waveCount: waves,
            difficultyMultiplier: difficulty,
            creditsReward: 30 + defense * 5,
            mineralsReward: 15 + defense * 3
        )
    }
}
