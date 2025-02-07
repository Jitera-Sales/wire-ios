//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

class UserPropertiesAPIV4: UserPropertiesAPIV3 {

    override var apiVersion: APIVersion {
        .v4
    }

    override func parseResponse<Payload: UserPropertiesResponseAPIV0>(
        _ response: HTTPResponse,
        forPayloadType type: Payload.Type
    ) throws -> UserProperty where Payload.APIModel == UserProperty {
        try ResponseParser()
            .success(code: .ok, type: type)
            .failure(code: .badRequest, error: UserPropertiesAPIError.invalidKey) /// Error code only present in api v4.
            .failure(code: .notFound, error: UserPropertiesAPIError.propertyNotFound)
            .parse(response)
    }

}
