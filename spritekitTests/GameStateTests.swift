//
//  GameStateTests.swift
//  spritekitTests
//
//  Created by Clifton Baggerman on 28/03/2026.
//

import Testing
@testable import spritekit

struct GameStateTests {

    // MARK: - Test Helpers

    private func makeTestPlanet(
        owner: Faction? = .player,
        minerals: Int = 50,
        credits: Int = 100,
        population: Int = 100,
        mines: Int = 1,
        factories: Int = 1,
        hasSpaceport: Bool = false,
        hasBiosphere: Bool = false,
        isHQ: Bool = false
    ) -> Planet {
        Planet(
            id: UUID(),
            name: "TEST",
            positionX: 100,
            positionY: 100,
            owner: owner,
            minerals: minerals,
            population: population,
            credits: credits,
            mines: mines,
            factories: factories,
            hasSpaceport: hasSpaceport,
            hasBiosphere: hasBiosphere,
            isHQ: isHQ
        )
    }

    // MARK: - Planet Resource Generation

    @Test func `planet processTurn adds minerals from mines`() {
        var planet = makeTestPlanet(minerals: 50, mines: 2)
        planet.processTurn()
        #expect(planet.minerals == 60) // 50 + (2 * 5)
    }

    @Test func `planet processTurn adds credits from factories`() {
        var planet = makeTestPlanet(credits: 100, factories: 3)
        planet.processTurn()
        #expect(planet.credits == 130) // 100 + (3 * 10)
    }

    @Test func `planet processTurn adds population with biosphere`() {
        var planet = makeTestPlanet(population: 100, hasBiosphere: true)
        planet.processTurn()
        #expect(planet.population == 110) // 100 + 10
    }

    @Test func `planet processTurn adds minimal population without biosphere`() {
        var planet = makeTestPlanet(population: 100, hasBiosphere: false)
        planet.processTurn()
        #expect(planet.population == 102) // 100 + 2
    }

    // MARK: - Building

    @Test func `canBuild returns true when resources sufficient`() {
        let planet = makeTestPlanet(minerals: 100, credits: 200)
        #expect(planet.canBuild(.mine))
        #expect(planet.canBuild(.factory))
        #expect(planet.canBuild(.spaceport))
        #expect(planet.canBuild(.biosphere))
    }

    @Test func `canBuild returns false when credits insufficient`() {
        let planet = makeTestPlanet(minerals: 100, credits: 10)
        #expect(!planet.canBuild(.factory)) // needs 100 CR
    }

    @Test func `canBuild returns false when minerals insufficient`() {
        let planet = makeTestPlanet(minerals: 5, credits: 200)
        #expect(!planet.canBuild(.spaceport)) // needs 50 MIN
    }

    @Test func `build mine deducts credits and increments count`() {
        var planet = makeTestPlanet(minerals: 50, credits: 100, mines: 0)
        planet.build(.mine)
        #expect(planet.mines == 1)
        #expect(planet.credits == 50) // 100 - 50
    }

    @Test func `build spaceport sets flag and deducts resources`() {
        var planet = makeTestPlanet(minerals: 100, credits: 300, hasSpaceport: false)
        planet.build(.spaceport)
        #expect(planet.hasSpaceport)
        #expect(planet.credits == 100) // 300 - 200
        #expect(planet.minerals == 50) // 100 - 50
    }

    // MARK: - Player State

    @Test func `addShip increments fleet count`() {
        var player = PlayerState(credits: 100, fuel: 50, minerals: 50, currentPlanetID: nil, fleet: [:])
        player.addShip(.fighter)
        player.addShip(.fighter)
        player.addShip(.destroyer)
        #expect(player.shipCount(for: .fighter) == 2)
        #expect(player.shipCount(for: .destroyer) == 1)
        #expect(player.totalShips == 3)
    }

    @Test func `removeShip decrements fleet count`() {
        var player = PlayerState(credits: 100, fuel: 50, minerals: 50, currentPlanetID: nil, fleet: [ShipType.fighter.rawValue: 3])
        player.removeShip(.fighter)
        #expect(player.shipCount(for: .fighter) == 2)
    }

    @Test func `removeShip does not go below zero`() {
        var player = PlayerState(credits: 100, fuel: 50, minerals: 50, currentPlanetID: nil, fleet: [:])
        player.removeShip(.fighter)
        #expect(player.shipCount(for: .fighter) == 0)
    }

    // MARK: - Route Connectivity

    @Test func `connectedPlanets returns adjacent planets`() {
        let a = makeTestPlanet()
        let b = makeTestPlanet()
        let c = makeTestPlanet()

        let state = GameState(
            planets: [a, b, c],
            routes: [Route(planetA: a.id, planetB: b.id)],
            player: PlayerState(credits: 0, fuel: 50, minerals: 0, currentPlanetID: a.id, fleet: [:]),
            turn: 1,
            config: GalaxyConfig(planetCount: 3, seed: 1)
        )

        let connected = state.connectedPlanets(from: a.id)
        #expect(connected.count == 1)
        #expect(connected.first?.id == b.id)
    }

    @Test func `fuelCost is proportional to distance`() {
        let a = Planet(id: UUID(), name: "A", positionX: 0, positionY: 0, owner: .player, minerals: 0, population: 0, credits: 0, mines: 0, factories: 0, hasSpaceport: false, hasBiosphere: false, isHQ: false)
        let b = Planet(id: UUID(), name: "B", positionX: 100, positionY: 0, owner: nil, minerals: 0, population: 0, credits: 0, mines: 0, factories: 0, hasSpaceport: false, hasBiosphere: false, isHQ: false)

        let state = GameState(
            planets: [a, b],
            routes: [Route(planetA: a.id, planetB: b.id)],
            player: PlayerState(credits: 0, fuel: 50, minerals: 0, currentPlanetID: a.id, fleet: [:]),
            turn: 1,
            config: GalaxyConfig(planetCount: 2, seed: 1)
        )

        let cost = state.fuelCost(from: a.id, to: b.id)
        #expect(cost == 5.0) // distance 100 * 0.05
    }

    // MARK: - Win/Lose Conditions

    @Test func `playerHasWon when all enemy HQs captured`() {
        var playerHQ = makeTestPlanet(owner: .player, isHQ: true)
        playerHQ.isHQ = true
        var enemyHQ = makeTestPlanet(owner: .player, isHQ: true) // captured by player
        enemyHQ.isHQ = true

        let state = GameState(
            planets: [playerHQ, enemyHQ],
            routes: [],
            player: PlayerState(credits: 0, fuel: 50, minerals: 0, currentPlanetID: playerHQ.id, fleet: [:]),
            turn: 1,
            config: GalaxyConfig(planetCount: 2, seed: 1)
        )

        #expect(state.playerHasWon)
    }

    @Test func `playerHasWon is false when enemy HQ still standing`() {
        let playerHQ = makeTestPlanet(owner: .player, isHQ: true)
        let enemyHQ = makeTestPlanet(owner: .kethari, isHQ: true)

        let state = GameState(
            planets: [playerHQ, enemyHQ],
            routes: [],
            player: PlayerState(credits: 0, fuel: 50, minerals: 0, currentPlanetID: playerHQ.id, fleet: [:]),
            turn: 1,
            config: GalaxyConfig(planetCount: 2, seed: 1)
        )

        #expect(!state.playerHasWon)
    }

    @Test func `playerHasLost when no planets owned`() {
        let lostPlanet = makeTestPlanet(owner: .kethari)

        let state = GameState(
            planets: [lostPlanet],
            routes: [],
            player: PlayerState(credits: 0, fuel: 50, minerals: 0, currentPlanetID: nil, fleet: [:]),
            turn: 1,
            config: GalaxyConfig(planetCount: 1, seed: 1)
        )

        #expect(state.playerHasLost)
    }

    @Test func `playerHasLost is false when player owns planets`() {
        let planet = makeTestPlanet(owner: .player)

        let state = GameState(
            planets: [planet],
            routes: [],
            player: PlayerState(credits: 0, fuel: 50, minerals: 0, currentPlanetID: planet.id, fleet: [:]),
            turn: 1,
            config: GalaxyConfig(planetCount: 1, seed: 1)
        )

        #expect(!state.playerHasLost)
    }

    // MARK: - Defense Strength

    @Test func `defenseStrength scales with population and factories`() {
        let weak = makeTestPlanet(population: 50, factories: 0)
        let strong = makeTestPlanet(population: 200, factories: 3)

        #expect(weak.defenseStrength == 5)    // 50/10 + 0*2
        #expect(strong.defenseStrength == 26) // 200/10 + 3*2
    }
}
