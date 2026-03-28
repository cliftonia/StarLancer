//
//  GameSettings.swift
//  spritekit
//
//  Created by Clifton Baggerman on 28/03/2026.
//

import Foundation

final class GameSettings {

    static let shared = GameSettings()

    private enum Key: String {
        case soundFX = "settings_sound_fx"
        case music = "settings_music"
        case haptics = "settings_haptics"
        case screenShake = "settings_screen_shake"
        case notifications = "settings_notifications"
    }

    private let defaults = UserDefaults.standard

    private init() {}

    var isSoundFXEnabled: Bool {
        get { defaults.object(forKey: Key.soundFX.rawValue) == nil ? true : defaults.bool(forKey: Key.soundFX.rawValue) }
        set { defaults.set(newValue, forKey: Key.soundFX.rawValue) }
    }

    var isMusicEnabled: Bool {
        get { defaults.object(forKey: Key.music.rawValue) == nil ? true : defaults.bool(forKey: Key.music.rawValue) }
        set { defaults.set(newValue, forKey: Key.music.rawValue) }
    }

    var isHapticsEnabled: Bool {
        get { defaults.object(forKey: Key.haptics.rawValue) == nil ? true : defaults.bool(forKey: Key.haptics.rawValue) }
        set { defaults.set(newValue, forKey: Key.haptics.rawValue) }
    }

    var isScreenShakeEnabled: Bool {
        get { defaults.object(forKey: Key.screenShake.rawValue) == nil ? true : defaults.bool(forKey: Key.screenShake.rawValue) }
        set { defaults.set(newValue, forKey: Key.screenShake.rawValue) }
    }

    var isNotificationsEnabled: Bool {
        get { defaults.object(forKey: Key.notifications.rawValue) == nil ? false : defaults.bool(forKey: Key.notifications.rawValue) }
        set { defaults.set(newValue, forKey: Key.notifications.rawValue) }
    }
}
