//
//  FactionData.swift
//  spritekit
//
//  Created by Clifton Baggerman on 28/03/2026.
//

import SpriteKit

struct FactionInfo {
    let faction: Faction
    let displayName: String
    let color: SKColor
    let aggression: Double     // 0.0 (passive) to 1.0 (warlike)
    let economyFocus: Double   // 0.0 (military) to 1.0 (economic)
}

enum FactionData {

    static let all: [FactionInfo] = [
        FactionInfo(
            faction: .kethari,
            displayName: "THE KETHARI",
            color: Theme.offRed,
            aggression: 0.8,
            economyFocus: 0.3
        ),
        FactionInfo(
            faction: .vossari,
            displayName: "VOSSARI COLLECTIVE",
            color: Theme.onGreen,
            aggression: 0.3,
            economyFocus: 0.8
        ),
        FactionInfo(
            faction: .draknor,
            displayName: "DRAKNOR EMPIRE",
            color: Theme.warmGold,
            aggression: 0.5,
            economyFocus: 0.5
        )
    ]

    static func info(for faction: Faction) -> FactionInfo? {
        all.first { $0.faction == faction }
    }

    static let aiFactions: [Faction] = [.kethari, .vossari, .draknor]
}
