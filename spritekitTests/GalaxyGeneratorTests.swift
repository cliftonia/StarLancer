//
//  GalaxyGeneratorTests.swift
//  spritekitTests
//
//  Created by Clifton Baggerman on 28/03/2026.
//

import Testing
@testable import spritekit

struct GalaxyGeneratorTests {

    // MARK: - Planet Generation

    @Test func `generates correct number of planets`() {
        let state = GalaxyGenerator.generate(config: GalaxyConfig(planetCount: 10, seed: 42))
        #expect(state.planets.count == 10)
    }

    @Test func `clamps planet count to valid range`() {
        let small = GalaxyGenerator.generate(config: GalaxyConfig(planetCount: 2, seed: 42))
        #expect(small.planets.count == 6) // minimum 6

        let large = GalaxyGenerator.generate(config: GalaxyConfig(planetCount: 20, seed: 42))
        #expect(large.planets.count == 12) // maximum 12
    }

    @Test func `all planets have unique IDs`() {
        let state = GalaxyGenerator.generate(config: GalaxyConfig(planetCount: 10, seed: 42))
        let ids = Set(state.planets.map(\.id))
        #expect(ids.count == state.planets.count)
    }

    @Test func `all planets have unique names`() {
        let state = GalaxyGenerator.generate(config: GalaxyConfig(planetCount: 10, seed: 42))
        let names = Set(state.planets.map(\.name))
        #expect(names.count == state.planets.count)
    }

    // MARK: - Player Starting Conditions

    @Test func `player starts with home planet`() {
        let state = GalaxyGenerator.generate(config: GalaxyConfig(planetCount: 10, seed: 42))
        let playerPlanets = state.planets.filter { $0.owner == .player }
        #expect(playerPlanets.count == 1)
        #expect(playerPlanets.first?.isHQ == true)
    }

    @Test func `player home planet has starting infrastructure`() {
        let state = GalaxyGenerator.generate(config: GalaxyConfig(planetCount: 10, seed: 42))
        let home = state.planets.first { $0.owner == .player && $0.isHQ }!
        #expect(home.mines >= 1)
        #expect(home.factories >= 1)
        #expect(home.hasSpaceport)
    }

    @Test func `player starts with credits and fuel`() {
        let state = GalaxyGenerator.generate(config: GalaxyConfig(planetCount: 10, seed: 42))
        #expect(state.player.credits == 200)
        #expect(state.player.fuel == 100.0)
        #expect(state.player.totalShips == 2) // 2 fighters
    }

    // MARK: - AI Faction Assignment

    @Test func `AI factions receive starting planets`() {
        let state = GalaxyGenerator.generate(config: GalaxyConfig(planetCount: 10, seed: 42))
        let kethariPlanets = state.planets.filter { $0.owner == .kethari }
        let vossariPlanets = state.planets.filter { $0.owner == .vossari }
        let draknorPlanets = state.planets.filter { $0.owner == .draknor }

        #expect(kethariPlanets.count >= 1)
        #expect(vossariPlanets.count >= 1)
        #expect(draknorPlanets.count >= 1)
    }

    @Test func `AI HQ planets are marked`() {
        let state = GalaxyGenerator.generate(config: GalaxyConfig(planetCount: 10, seed: 42))
        let aiHQs = state.planets.filter { $0.isHQ && $0.owner != .player }
        #expect(aiHQs.count == 3) // one per AI faction
    }

    // MARK: - Route Connectivity

    @Test func `all planets are reachable via routes`() {
        let state = GalaxyGenerator.generate(config: GalaxyConfig(planetCount: 10, seed: 42))

        // BFS from first planet to verify full connectivity
        var visited = Set<UUID>()
        var queue = [state.planets[0].id]
        visited.insert(state.planets[0].id)

        while !queue.isEmpty {
            let current = queue.removeFirst()
            let neighbors = state.routes.compactMap { route -> UUID? in
                route.destination(from: current)
            }
            for neighbor in neighbors where !visited.contains(neighbor) {
                visited.insert(neighbor)
                queue.append(neighbor)
            }
        }

        #expect(visited.count == state.planets.count)
    }

    @Test func `routes reference valid planet IDs`() {
        let state = GalaxyGenerator.generate(config: GalaxyConfig(planetCount: 10, seed: 42))
        let planetIDs = Set(state.planets.map(\.id))

        for route in state.routes {
            #expect(planetIDs.contains(route.planetA))
            #expect(planetIDs.contains(route.planetB))
        }
    }

    // MARK: - Seeded Reproducibility

    @Test func `same seed produces same galaxy`() {
        let state1 = GalaxyGenerator.generate(config: GalaxyConfig(planetCount: 10, seed: 12345))
        let state2 = GalaxyGenerator.generate(config: GalaxyConfig(planetCount: 10, seed: 12345))

        #expect(state1.planets.count == state2.planets.count)
        for i in 0..<state1.planets.count {
            #expect(state1.planets[i].name == state2.planets[i].name)
            #expect(state1.planets[i].positionX == state2.planets[i].positionX)
            #expect(state1.planets[i].positionY == state2.planets[i].positionY)
        }
    }

    @Test func `different seeds produce different galaxies`() {
        let state1 = GalaxyGenerator.generate(config: GalaxyConfig(planetCount: 10, seed: 111))
        let state2 = GalaxyGenerator.generate(config: GalaxyConfig(planetCount: 10, seed: 222))

        let names1 = state1.planets.map(\.name)
        let names2 = state2.planets.map(\.name)

        // Planet names should be shuffled differently
        #expect(names1 != names2)
    }

    // MARK: - Turn 1 State

    @Test func `game starts on turn 1`() {
        let state = GalaxyGenerator.generate(config: GalaxyConfig(planetCount: 10, seed: 42))
        #expect(state.turn == 1)
    }

    @Test func `player starts at home planet`() {
        let state = GalaxyGenerator.generate(config: GalaxyConfig(planetCount: 10, seed: 42))
        let home = state.planets.first { $0.owner == .player && $0.isHQ }
        #expect(state.player.currentPlanetID == home?.id)
    }
}
