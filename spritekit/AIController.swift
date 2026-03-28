//
//  AIController.swift
//  spritekit
//
//  Created by Clifton Baggerman on 28/03/2026.
//

import Foundation

enum AIController {

    static func processTurn(for faction: Faction, in state: inout GameState) {
        guard let info = FactionData.info(for: faction) else { return }

        let ownedPlanets = state.planets.filter { $0.owner == faction }
        guard !ownedPlanets.isEmpty else { return }

        // Phase 1: Collect resources (already done by GameState.processTurn)

        // Phase 2: Build infrastructure
        for planet in ownedPlanets {
            buildOnPlanet(planet, faction: faction, info: info, state: &state)
        }

        // Phase 3: Attempt expansion
        if shouldExpand(info: info, ownedCount: ownedPlanets.count, turn: state.turn) {
            attemptExpansion(faction: faction, state: &state)
        }
    }

    // MARK: - Building

    private static func buildOnPlanet(_ planet: Planet, faction: Faction, info: FactionInfo, state: inout GameState) {
        guard var p = state.planet(withID: planet.id), p.owner == faction else { return }

        // Economic factions prioritize mines/factories, aggressive factions rush spaceport
        if info.economyFocus > 0.5 {
            // Economy priority: mine → factory → biosphere → spaceport
            if p.canBuild(.mine) && p.mines < 3 {
                p.build(.mine)
            } else if p.canBuild(.factory) && p.factories < 2 {
                p.build(.factory)
            } else if p.canBuild(.biosphere) && !p.hasBiosphere {
                p.build(.biosphere)
            } else if p.canBuild(.spaceport) && !p.hasSpaceport {
                p.build(.spaceport)
            }
        } else {
            // Military priority: mine → spaceport → factory → biosphere
            if p.canBuild(.mine) && p.mines < 2 {
                p.build(.mine)
            } else if p.canBuild(.spaceport) && !p.hasSpaceport {
                p.build(.spaceport)
            } else if p.canBuild(.factory) && p.factories < 2 {
                p.build(.factory)
            } else if p.canBuild(.biosphere) && !p.hasBiosphere {
                p.build(.biosphere)
            }
        }

        state.updatePlanet(p)
    }

    // MARK: - Expansion

    private static func shouldExpand(info: FactionInfo, ownedCount: Int, turn: Int) -> Bool {
        // More aggressive factions expand earlier and more often
        let expandChance = info.aggression * 0.3 + (turn > 5 ? 0.2 : 0)
        return Double.random(in: 0...1) < expandChance && ownedCount < 6
    }

    private static func attemptExpansion(faction: Faction, state: inout GameState) {
        let ownedPlanets = state.planets.filter { $0.owner == faction }

        // Find adjacent unclaimed or weak planets
        for owned in ownedPlanets {
            let neighbors = state.connectedPlanets(from: owned.id)
            let targets = neighbors.filter { neighbor in
                // Target unclaimed planets or weak enemy planets
                if neighbor.owner == nil { return true }
                if neighbor.owner == faction { return false }
                return neighbor.defenseStrength < owned.defenseStrength
            }

            guard let target = targets.first else { continue }

            // Capture the weakest target
            if var targetPlanet = state.planet(withID: target.id) {
                // Simple capture — AI doesn't go through combat, just takes unclaimed
                // For enemy-owned planets, only capture if significantly stronger
                if targetPlanet.owner == nil {
                    targetPlanet.owner = faction
                    state.updatePlanet(targetPlanet)
                    return // One expansion per turn
                } else if targetPlanet.defenseStrength < owned.defenseStrength / 2 {
                    targetPlanet.owner = faction
                    targetPlanet.factories = max(0, targetPlanet.factories - 1)
                    state.updatePlanet(targetPlanet)
                    return
                }
            }
        }
    }
}
