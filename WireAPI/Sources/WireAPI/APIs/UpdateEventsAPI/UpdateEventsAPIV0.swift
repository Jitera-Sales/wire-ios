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

class UpdateEventsAPIV0: UpdateEventsAPI, VersionedAPI {

    let apiService: any APIServiceProtocol

    init(apiService: any APIServiceProtocol) {
        self.apiService = apiService
    }

    var apiVersion: APIVersion {
        .v0
    }

    private var basePath: String {
        "/notifications"
    }

    // MARK: - Get last update event

    func getLastUpdateEvent(selfClientID: String) async throws -> UpdateEventEnvelope {
        var components = URLComponents(string: "\(pathPrefix)\(basePath)/last")
        components?.queryItems = [URLQueryItem(name: "client", value: selfClientID)]

        guard let url = components?.url else {
            assertionFailure("generated an invalid url")
            throw UpdateEventsAPIError.invalidURL
        }

        let request = URLRequestBuilder(url: url)
            .withMethod(.get)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        return try ResponseParser()
            .success(code: .ok, type: UpdateEventEnvelopeV0.self)
            .failure(code: .badRequest, error: UpdateEventsAPIError.invalidClient)
            .failure(code: .notFound, label: "not-found", error: UpdateEventsAPIError.notFound)
            .parse(code: response.statusCode, data: data)
    }

    // MARK: - Get events since

    func getUpdateEvents(
        selfClientID: String,
        sinceEventID: UUID
    ) -> PayloadPager<UpdateEventEnvelope> {
        let resourcePath = "\(pathPrefix)\(basePath)"

        return PayloadPager(start: sinceEventID.transportString()) { nextSince in
            var components = URLComponents(string: resourcePath)
            components?.queryItems = [
                URLQueryItem(name: "client", value: selfClientID),
                URLQueryItem(name: "since", value: nextSince),
                URLQueryItem(name: "size", value: "500")
            ]

            guard let url = components?.url else {
                assertionFailure("generated an invalid url")
                throw UpdateEventsAPIError.invalidURL
            }

            let request = URLRequestBuilder(url: url)
                .withMethod(.get)
                .build()

            let (data, response) = try await self.apiService.executeRequest(
                request,
                requiringAccessToken: true
            )

            return try ResponseParser()
                .success(code: .ok, type: UpdateEventListResponseV0.self)
                .failure(code: .badRequest, error: UpdateEventsAPIError.invalidParameters)
                .failure(code: .notFound, error: UpdateEventsAPIError.notFound)
                .parse(code: response.statusCode, data: data)
        }
    }

}
