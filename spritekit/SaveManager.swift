//
//  SaveManager.swift
//  spritekit
//
//  Created by Clifton Baggerman on 28/03/2026.
//

import Foundation

enum SaveManager {

    private static let fileName = "deeporbit_save.json"

    private static var saveURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent(fileName)
    }

    static var hasSave: Bool {
        FileManager.default.fileExists(atPath: saveURL.path)
    }

    static func save(_ state: GameState) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(state)
            try data.write(to: saveURL, options: .atomic)
        } catch {
            print("Save failed: \(error)")
        }
    }

    static func load() -> GameState? {
        guard hasSave else { return nil }
        do {
            let data = try Data(contentsOf: saveURL)
            return try JSONDecoder().decode(GameState.self, from: data)
        } catch {
            print("Load failed: \(error)")
            return nil
        }
    }

    static func deleteSave() {
        try? FileManager.default.removeItem(at: saveURL)
    }
}
