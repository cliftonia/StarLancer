//
//  GalaxyGenerator.swift
//  spritekit
//
//  Created by Clifton Baggerman on 28/03/2026.
//

import CoreGraphics
import Foundation

enum GalaxyGenerator {

    private static let planetNames = [
        "KEPLER", "PROXIMA", "VEGA", "ARCADIA",
        "HELIOS", "NOVUS", "TITAN", "CYGNUS",
        "OLYMPUS", "EREBUS", "SOLACE", "DRAVEN"
    ]

    static func generate(config: GalaxyConfig = GalaxyConfig(planetCount: 10, seed: 0)) -> GameState {
        var rng = SeededRNG(seed: config.seed == 0 ? UInt64.random(in: 1...UInt64.max) : config.seed)

        let count = max(6, min(12, config.planetCount))
        let names = planetNames.shuffled(using: &rng)

        // Generate planet positions spread across a map area
        let mapWidth: Double = 800
        let mapHeight: Double = 1200
        let padding: Double = 80

        var positions: [CGPoint] = []
        let minDistance: Double = 120

        for _ in 0..<count {
            var attempts = 0
            var pos: CGPoint
            repeat {
                pos = CGPoint(
                    x: padding + Double.random(in: 0...(mapWidth - padding * 2), using: &rng),
                    y: padding + Double.random(in: 0...(mapHeight - padding * 2), using: &rng)
                )
                attempts += 1
            } while positions.contains(where: { distance($0, pos) < minDistance }) && attempts < 100
            positions.append(pos)
        }

        // Create planets
        var planets: [Planet] = []
        for i in 0..<count {
            let planet = Planet(
                id: UUID(),
                name: names[i],
                positionX: positions[i].x,
                positionY: positions[i].y,
                owner: nil,
                minerals: Int.random(in: 20...80, using: &rng),
                population: Int.random(in: 50...200, using: &rng),
                credits: Int.random(in: 10...50, using: &rng),
                mines: 0,
                factories: 0,
                hasSpaceport: false,
                hasBiosphere: false,
                isHQ: false
            )
            planets.append(planet)
        }

        // Assign player home planet (first planet, better starting resources)
        planets[0].owner = .player
        planets[0].isHQ = true
        planets[0].mines = 1
        planets[0].factories = 1
        planets[0].hasSpaceport = true
        planets[0].credits = 100
        planets[0].minerals = 60
        planets[0].population = 150

        // Assign AI faction home planets (spread across the map)
        let aiFactions: [Faction] = FactionData.aiFactions
        let factionStartIndices = spreadIndices(count: aiFactions.count, total: count, avoiding: 0)
        for (i, factionIndex) in factionStartIndices.enumerated() where i < aiFactions.count {
            planets[factionIndex].owner = aiFactions[i]
            planets[factionIndex].isHQ = true
            planets[factionIndex].mines = 1
            planets[factionIndex].factories = 1
            planets[factionIndex].hasSpaceport = false
            planets[factionIndex].credits = 80
            planets[factionIndex].minerals = 40
            planets[factionIndex].population = 120
        }

        // Generate routes using minimum spanning tree + extra connections
        var routes = buildMinimumSpanningTree(planets: planets)

        // Add extra routes for variety (30% chance per non-connected nearby pair)
        for i in 0..<planets.count {
            for j in (i + 1)..<planets.count {
                let alreadyConnected = routes.contains { r in
                    (r.planetA == planets[i].id && r.planetB == planets[j].id) ||
                    (r.planetA == planets[j].id && r.planetB == planets[i].id)
                }
                if !alreadyConnected {
                    let dist = distance(planets[i].position, planets[j].position)
                    if dist < 250 && Double.random(in: 0...1, using: &rng) < 0.3 {
                        routes.append(Route(planetA: planets[i].id, planetB: planets[j].id))
                    }
                }
            }
        }

        let player = PlayerState(
            credits: 200,
            fuel: 100.0,
            minerals: 50,
            currentPlanetID: planets[0].id,
            fleet: [ShipType.fighter.rawValue: 2]
        )

        return GameState(
            planets: planets,
            routes: routes,
            player: player,
            turn: 1,
            config: config
        )
    }

    // MARK: - Minimum Spanning Tree (Prim's)

    private static func buildMinimumSpanningTree(planets: [Planet]) -> [Route] {
        guard planets.count > 1 else { return [] }

        var inTree = Set<UUID>([planets[0].id])
        var routes: [Route] = []

        while inTree.count < planets.count {
            var bestRoute: Route?
            var bestDist = Double.infinity

            for planet in planets where inTree.contains(planet.id) {
                for candidate in planets where !inTree.contains(candidate.id) {
                    let dist = distance(planet.position, candidate.position)
                    if dist < bestDist {
                        bestDist = dist
                        bestRoute = Route(planetA: planet.id, planetB: candidate.id)
                    }
                }
            }

            if let route = bestRoute {
                routes.append(route)
                if let dest = route.destination(from: route.planetA), !inTree.contains(dest) {
                    inTree.insert(dest)
                } else if let dest = route.destination(from: route.planetB) {
                    inTree.insert(dest)
                }
            }
        }

        return routes
    }

    // MARK: - Helpers

    private static func spreadIndices(count: Int, total: Int, avoiding: Int) -> [Int] {
        // Pick indices spread across the range, avoiding a specific index
        guard total > 1 else { return [] }
        let step = total / (count + 1)
        var indices: [Int] = []
        for i in 1...count {
            var idx = (step * i) % total
            if idx == avoiding { idx = (idx + 1) % total }
            if !indices.contains(idx) && idx != avoiding {
                indices.append(idx)
            }
        }
        return indices
    }

    private static func distance(_ a: CGPoint, _ b: CGPoint) -> Double {
        let dx = a.x - b.x
        let dy = a.y - b.y
        return sqrt(dx * dx + dy * dy)
    }
}

// MARK: - Seeded RNG

struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
