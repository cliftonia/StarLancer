//
//  GameState.swift
//  spritekit
//
//  Created by Clifton Baggerman on 28/03/2026.
//

import CoreGraphics
import Foundation

// MARK: - Faction

enum Faction: String, Codable, CaseIterable, Hashable {
    case player
    case kethari    // aggressive expansionists
    case vossari    // defensive builders
    case draknor    // balanced strategists
}

// MARK: - Ship Type

enum ShipType: String, Codable, CaseIterable, Hashable {
    case fighter
    case destroyer
    case bomber
    case missileCarrier
    case troopTransport

    var displayName: String {
        switch self {
        case .fighter:        return "FIGHTER"
        case .destroyer:      return "DESTROYER"
        case .bomber:         return "BOMBER"
        case .missileCarrier: return "MISSILE CARRIER"
        case .troopTransport: return "TROOP TRANSPORT"
        }
    }

    var creditsCost: Int {
        switch self {
        case .fighter:        return 30
        case .destroyer:      return 80
        case .bomber:         return 60
        case .missileCarrier: return 100
        case .troopTransport: return 50
        }
    }

    var mineralsCost: Int {
        switch self {
        case .fighter:        return 10
        case .destroyer:      return 30
        case .bomber:         return 20
        case .missileCarrier: return 40
        case .troopTransport: return 15
        }
    }
}

// MARK: - Building Type

enum BuildingType: String, Codable, CaseIterable, Hashable {
    case mine
    case factory
    case spaceport
    case biosphere

    var displayName: String {
        switch self {
        case .mine:      return "MINE"
        case .factory:   return "FACTORY"
        case .spaceport: return "SPACEPORT"
        case .biosphere: return "BIOSPHERE"
        }
    }

    var creditsCost: Int {
        switch self {
        case .mine:      return 50
        case .factory:   return 100
        case .spaceport: return 200
        case .biosphere: return 150
        }
    }

    var mineralsCost: Int {
        switch self {
        case .mine:      return 0
        case .factory:   return 20
        case .spaceport: return 50
        case .biosphere: return 30
        }
    }
}

// MARK: - Planet

struct Planet: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var positionX: Double
    var positionY: Double
    var owner: Faction?

    var minerals: Int
    var population: Int
    var credits: Int

    var mines: Int
    var factories: Int
    var hasSpaceport: Bool
    var hasBiosphere: Bool

    var isHQ: Bool

    var position: CGPoint {
        CGPoint(x: positionX, y: positionY)
    }

    var defenseStrength: Int {
        population / 10 + factories * 2
    }

    var mineralsPerTurn: Int {
        mines * 5
    }

    var creditsPerTurn: Int {
        factories * 10
    }

    var populationPerTurn: Int {
        hasBiosphere ? 10 : 2
    }

    mutating func processTurn() {
        minerals += mineralsPerTurn
        credits += creditsPerTurn
        population += populationPerTurn
    }

    func canBuild(_ building: BuildingType) -> Bool {
        credits >= building.creditsCost && minerals >= building.mineralsCost
    }

    mutating func build(_ building: BuildingType) {
        credits -= building.creditsCost
        minerals -= building.mineralsCost

        switch building {
        case .mine:      mines += 1
        case .factory:   factories += 1
        case .spaceport: hasSpaceport = true
        case .biosphere: hasBiosphere = true
        }
    }
}

// MARK: - Player State

struct PlayerState: Codable, Hashable {
    var credits: Int
    var fuel: Double
    var minerals: Int
    var currentPlanetID: UUID?
    var fleet: [String: Int] // ShipType.rawValue -> count

    func shipCount(for type: ShipType) -> Int {
        fleet[type.rawValue] ?? 0
    }

    mutating func addShip(_ type: ShipType) {
        fleet[type.rawValue, default: 0] += 1
    }

    mutating func removeShip(_ type: ShipType) {
        let current = fleet[type.rawValue, default: 0]
        fleet[type.rawValue] = max(0, current - 1)
    }

    var totalShips: Int {
        fleet.values.reduce(0, +)
    }
}

// MARK: - Galaxy Config

struct GalaxyConfig: Codable, Hashable {
    var planetCount: Int
    var seed: UInt64
}

// MARK: - Route

struct Route: Codable, Hashable {
    let planetA: UUID
    let planetB: UUID

    func connects(_ id: UUID) -> Bool {
        planetA == id || planetB == id
    }

    func destination(from id: UUID) -> UUID? {
        if planetA == id { return planetB }
        if planetB == id { return planetA }
        return nil
    }
}

// MARK: - Game State

struct GameState: Codable {
    var planets: [Planet]
    var routes: [Route]
    var player: PlayerState
    var turn: Int
    var config: GalaxyConfig

    func planet(withID id: UUID) -> Planet? {
        planets.first { $0.id == id }
    }

    mutating func updatePlanet(_ planet: Planet) {
        guard let index = planets.firstIndex(where: { $0.id == planet.id }) else { return }
        planets[index] = planet
    }

    func connectedPlanets(from planetID: UUID) -> [Planet] {
        let connectedIDs = routes.compactMap { $0.destination(from: planetID) }
        return connectedIDs.compactMap { id in planets.first { $0.id == id } }
    }

    func fuelCost(from a: UUID, to b: UUID) -> Double {
        guard let planetA = planet(withID: a), let planetB = planet(withID: b) else { return 0 }
        let dx = planetA.positionX - planetB.positionX
        let dy = planetA.positionY - planetB.positionY
        let distance = sqrt(dx * dx + dy * dy)
        return distance * 0.05
    }

    mutating func processTurn() {
        for i in planets.indices {
            guard planets[i].owner != nil else { continue }
            planets[i].processTurn()
        }
        turn += 1
    }
}
