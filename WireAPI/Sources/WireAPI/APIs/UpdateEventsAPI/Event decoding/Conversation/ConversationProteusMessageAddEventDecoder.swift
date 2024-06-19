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

struct ConversationProteusMessageAddEventDecoder {

    func decode(
        from container: KeyedDecodingContainer<ConversationEventCodingKeys>
    ) throws -> ConversationProteusMessageAddEvent {
        let conversationID = try container.decode(
            ConversationID.self,
            forKey: .conversationQualifiedID
        )

        let senderID = try container.decode(
            UserID.self,
            forKey: .senderQualifiedID
        )

        let timestamp = try container.decode(
            Date.self,
            forKey: .timestamp
        )

        let payload = try container.decode(
            Payload.self,
            forKey: .payload
        )

        return ConversationProteusMessageAddEvent(
            conversationID: conversationID,
            senderID: senderID,
            timestamp: timestamp,
            message: payload.text,
            externalData: payload.data,
            messageSenderID: payload.sender,
            messageRecipientID: payload.recipient
        )
    }

    private struct Payload: Decodable {

        let text: String
        let data: String?
        let sender: UUID
        let recipient: UUID

    }

}
