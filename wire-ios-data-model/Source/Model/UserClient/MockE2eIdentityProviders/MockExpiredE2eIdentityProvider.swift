//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

public final class MockExpiredE2eIdentityProvider: E2eIdentityProviding {
    public var isE2EIdentityEnabled: Bool = UserDefaults.standard.bool(forKey: "isE2eIdentityViewEnabled")

    public init() {}

    public func fetchCertificate() async throws -> E2eIdentityCertificate {
        return E2eIdentityCertificate(
            certificateDetails: .random(length: 450),
            expiryDate: Date.now.addingTimeInterval(36000),
            certificateStatus: "Expired",
            serialNumber: .random(length: 32)
        )
    }
}
