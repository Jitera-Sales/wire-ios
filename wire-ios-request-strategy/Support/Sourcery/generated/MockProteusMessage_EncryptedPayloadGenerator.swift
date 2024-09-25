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
import WireDataModel
import WireRequestStrategy

// this model was generated by sourcery but edited to make it work

public class MockProteusMessage: ProteusMessage {

    // MARK: - Life cycle

    public init() {}

    // MARK: - shouldExpire

    public var shouldExpire: Bool {
        get { return underlyingShouldExpire }
        set(value) { underlyingShouldExpire = value }
    }

    public var underlyingShouldExpire: Bool!

    // MARK: - underlyingMessage

    public var underlyingMessage: GenericMessage?

    // MARK: - targetRecipients

    public var targetRecipients: Recipients {
        get { return underlyingTargetRecipients }
        set(value) { underlyingTargetRecipients = value }
    }

    public var underlyingTargetRecipients: Recipients!

    // MARK: - context

    public var context: NSManagedObjectContext {
        get { return underlyingContext }
        set(value) { underlyingContext = value }
    }

    public var underlyingContext: NSManagedObjectContext!

    // MARK: - conversation

    public var conversation: ZMConversation?

    // MARK: - dependentObjectNeedingUpdateBeforeProcessing

    public var dependentObjectNeedingUpdateBeforeProcessing: NSObject?

    // MARK: - isExpired

    public var isExpired: Bool {
        get { return underlyingIsExpired }
        set(value) { underlyingIsExpired = value }
    }

    public var underlyingIsExpired: Bool!

    // MARK: - shouldIgnoreTheSecurityLevelCheck

    public var shouldIgnoreTheSecurityLevelCheck: Bool {
        get { return underlyingShouldIgnoreTheSecurityLevelCheck }
        set(value) { underlyingShouldIgnoreTheSecurityLevelCheck = value }
    }

    public var underlyingShouldIgnoreTheSecurityLevelCheck: Bool!

    // MARK: - expirationDate

    public var expirationDate: Date?

    // MARK: - expirationReasonCode

    public var expirationReasonCode: NSNumber?

    // MARK: - setExpirationDate

    public var setExpirationDate_Invocations: [Void] = []
    public var setExpirationDate_MockMethod: (() -> Void)?

    public func setExpirationDate() {
        setExpirationDate_Invocations.append(())

        guard let mock = setExpirationDate_MockMethod else {
            fatalError("no mock for `setExpirationDate`")
        }

        mock()
    }

    // MARK: - prepareMessageForSending

    public var prepareMessageForSending_Invocations: [Void] = []
    public var prepareMessageForSending_MockError: Error?
    public var prepareMessageForSending_MockMethod: (() async throws -> Void)?

    public func prepareMessageForSending() async throws {
        prepareMessageForSending_Invocations.append(())

        if let error = prepareMessageForSending_MockError {
            throw error
        }

        guard let mock = prepareMessageForSending_MockMethod else {
            fatalError("no mock for `prepareMessageForSending`")
        }

        try await mock()
    }

    // MARK: - missesRecipients

    public var missesRecipients_Invocations: [Set<WireDataModel.UserClient>] = []
    public var missesRecipients_MockMethod: ((Set<WireDataModel.UserClient>) -> Void)?

    public func missesRecipients(_ recipients: Set<WireDataModel.UserClient>!) {
        missesRecipients_Invocations.append(recipients)

        guard let mock = missesRecipients_MockMethod else {
            fatalError("no mock for `missesRecipients`")
        }

        mock(recipients)
    }

    // MARK: - detectedRedundantUsers   

    public var detectedRedundantUsers_Invocations: [[ZMUser]] = []
    public var detectedRedundantUsers_MockMethod: (([ZMUser]) -> Void)?

    public func detectedRedundantUsers(_ users: [ZMUser]) {
        detectedRedundantUsers_Invocations.append(users)

        guard let mock = detectedRedundantUsers_MockMethod else {
            fatalError("no mock for `detectedRedundantUsers`")
        }

        mock(users)
    }

    // MARK: - delivered

    public var deliveredWith_Invocations: [ZMTransportResponse] = []
    public var deliveredWith_MockMethod: ((ZMTransportResponse) -> Void)?

    public func delivered(with response: ZMTransportResponse) {
        deliveredWith_Invocations.append(response)

        guard let mock = deliveredWith_MockMethod else {
            fatalError("no mock for `deliveredWith`")
        }

        mock(response)
    }

    // MARK: - addFailedToSendRecipients

    public var addFailedToSendRecipients_Invocations: [[ZMUser]] = []
    public var addFailedToSendRecipients_MockMethod: (([ZMUser]) -> Void)?

    public func addFailedToSendRecipients(_ recipients: [ZMUser]) {
        addFailedToSendRecipients_Invocations.append(recipients)

        guard let mock = addFailedToSendRecipients_MockMethod else {
            fatalError("no mock for `addFailedToSendRecipients`")
        }

        mock(recipients)
    }

    // MARK: - expire

    public var expireWithReason_Invocations: [ExpirationReason] = []
    public var expireWithReason_MockMethod: ((ExpirationReason) -> Void)?

    public func expire(withReason reason: ExpirationReason) {
        expireWithReason_Invocations.append(reason)

        guard let mock = expireWithReason_MockMethod else {
            fatalError("no mock for `expireWithReason`")
        }

        mock(reason)
    }

}

// as ProteusMessage is combined of two protocols, it seems sourcery doesn't generate it
// this will be remove after removing EncryptedPayloadGenerator completly
extension MockProteusMessage: EncryptedPayloadGenerator {

    public typealias Payload = (data: Data, strategy: WireDataModel.MissingClientsStrategy)

    public func encryptForTransport() async -> Payload? {
        return nil
    }

    public func encryptForTransportQualified() async -> Payload? {
        nil
    }

    public var debugInfo: String {
        return ""
    }
}
