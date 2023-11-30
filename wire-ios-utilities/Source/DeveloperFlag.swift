//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import Foundation

public enum DeveloperFlag: String, CaseIterable {

    public static var storage = UserDefaults.standard

    case enableMLSSupport
    case showCreateMLSGroupToggle
    case proteusViaCoreCrypto
    case nseV2
    case forceDatabaseLoadingFailure
    case ignoreIncomingEvents
    case enableNewClientDetailsFlow
    case enableE2EIdentityDetails

    public var description: String {
        switch self {
        case .enableMLSSupport:
          return "Turn on to enable MLS support. This will cause the app to register an MLS client."

        case .showCreateMLSGroupToggle:
            return "Turn on to show the MLS toggle when creating a new group."

        case .proteusViaCoreCrypto:
            return "Turn on to use CoreCrypto for proteus messaging."

        case .nseV2:
            return "Turn on to use the new implementation of the notification service extension."

        case .forceDatabaseLoadingFailure:
            return "Turn on to force database loading failure in the process of database migration"

        case .ignoreIncomingEvents:
            return "Turn on to ignore incoming update events"

        case .enableNewClientDetailsFlow:
            return "Enable new client details flow"
        case .enableE2EIdentityDetails:
            return "Enable E2E Identity Details"
        }
    }

    public var isOn: Bool {
        get {
            return Self.storage.object(forKey: rawValue) as? Bool ?? defaultValue
        }

        set {
            Self.storage.set(newValue, forKey: rawValue)
        }
    }

    private var defaultValue: Bool {
        guard let bundleKey = bundleKey else {
            return false
        }
        return DeveloperFlagsDefault.isEnabled(for: bundleKey)
    }

    static public func clearAllFlags() {
        allCases.forEach {
            storage.set(nil, forKey: $0.rawValue)
        }
    }

    var bundleKey: String? {
        switch self {
        case .enableMLSSupport:
            return "MLSEnabled"
        case .showCreateMLSGroupToggle:
            return "CreateMLSGroupEnabled"
        case .proteusViaCoreCrypto:
            return "ProteusByCoreCryptoEnabled"
        case .forceDatabaseLoadingFailure:
            return "ForceDatabaseLoadingFailure"
        case .nseV2:
            return nil
        case .ignoreIncomingEvents:
            return "IgnoreIncomingEventsEnabled"
        case .enableNewClientDetailsFlow:
            return "EnableNewClientDetailsFlow"
        case .enableE2EIdentityDetails:
            return "EnableE2EIdentityDetails"
        }
    }

    /// Convenience method to set flag on or off
    ///
    /// - Note: it can be used in Tests to change storage if provided
    public func enable(_ enabled: Bool, storage: UserDefaults? = nil) {
        if let storage {
            DeveloperFlag.storage = storage
        }
        var flag = self
        flag.isOn = enabled
    }
}

private class DeveloperFlagsDefault {

    static func isEnabled(for bundleKey: String) -> Bool {
        return Bundle(for: self).infoForKey(bundleKey) == "1"
    }
}

public extension Bundle {
    func infoForKey(_ key: String) -> String? {
        return infoDictionary?[key] as? String
    }
}
