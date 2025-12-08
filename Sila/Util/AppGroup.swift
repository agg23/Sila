//
//  AppGroup.swift
//  Sila
//
//  Created by Adam Gastineau on 12/6/25.
//

import Foundation
import KeychainWrapper

/// Shared constants and utilities for App Group communication between the app and widget extension
class AppGroup {
    static let shared = AppGroup()

    private static let identifier = "group.im.agg.Sila"

    private static let userInfoKey = "user_info"
    private static let oauthKeychainKey = "oauth_token"
    private static let publicKeychainKey = "public_token"

    private static let migrationCompleteKey = "did_migrate_to_app_group"

    // This should never be nil (only when suiteName is empty)
    private static var defaults: UserDefaults = UserDefaults(suiteName: AppGroup.identifier)!
    private static var keychain: KeychainWrapper = KeychainWrapper(serviceName: "im.agg.sila", accessGroup: AppGroup.identifier)

    var user: AuthUser? {
        get {
            let data = AppGroup.defaults.object(forKey: AppGroup.userInfoKey) as? Data
            return data != nil ? try? JSONDecoder().decode(AuthUser.self, from: data!) : nil
        }
        set {
            var encoded: Data? = nil

            do {
                encoded = newValue != nil ? try JSONEncoder().encode(newValue) : nil
            } catch {
                print("Failed to encode user info \(error)")
            }
            AppGroup.defaults.set(encoded, forKey: AppGroup.userInfoKey)
        }
    }

    var oauthToken: String? {
        get {
            AppGroup.keychain.string(forKey: AppGroup.oauthKeychainKey)
        }
        set {
            if let oauthToken = newValue {
                AppGroup.keychain.set(oauthToken, forKey: AppGroup.oauthKeychainKey)
            } else {
                AppGroup.keychain.removeObject(forKey: AppGroup.oauthKeychainKey)
            }
        }
    }

    var publicToken: String? {
        get {
            AppGroup.keychain.string(forKey: AppGroup.publicKeychainKey)
        }
        set {
            if let publicToken = newValue {
                AppGroup.keychain.set(publicToken, forKey: AppGroup.publicKeychainKey)
            } else {
                AppGroup.keychain.removeObject(forKey: AppGroup.publicKeychainKey)
            }
        }
    }

    private var isMigrationComplete: Bool {
        get {
            AppGroup.defaults.bool(forKey: AppGroup.migrationCompleteKey)
        }
        set {
            AppGroup.defaults.set(newValue, forKey: AppGroup.migrationCompleteKey)
        }
    }

    func updateUser(_ user: AuthUser?, token: String?) {
        AppGroup.shared.user = user
        AppGroup.shared.oauthToken = token
    }

    func migrateIfNecessary() {
        guard !self.isMigrationComplete else {
            return
        }

        print("Migrating user data to App Group")

        if let userData = UserDefaults.standard.object(forKey: AppGroup.userInfoKey) {
            AppGroup.defaults.set(userData, forKey: AppGroup.userInfoKey)
        }

        // Move from default keychain to App Group keychain
        let oauthToken = KeychainWrapper.default.string(forKey: AppGroup.oauthKeychainKey)
        if let oauthToken {
            print("Migrating oauth token")
            self.oauthToken = oauthToken
        }

        let publicToken = KeychainWrapper.default.string(forKey: AppGroup.publicKeychainKey)
        if let publicToken {
            print("Migrating public token")
            self.publicToken = publicToken
        }

        self.isMigrationComplete = true
        print("App Group migration complete")
    }
}
