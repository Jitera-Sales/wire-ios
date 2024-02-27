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
import LocalAuthentication
import WireSyncEngineSupport
import WireDataModelSupport
import WireRequestStrategySupport

@testable import Wire

final class UserSessionMock: UserSession {
    var isE2eIdentityEnabled  = false
    var certificate = E2eIdentityCertificate.mockNotActivated
    typealias Preference = AppLockPasscodePreference
    typealias Callback = (AppLockModule.AuthenticationResult, LAContext) -> Void

    lazy var mockGetUserClientFingerprintUseCaseProtocol: MockGetUserClientFingerprintUseCaseProtocol = {
        let mock = MockGetUserClientFingerprintUseCaseProtocol()
        mock.invokeUserClient_MockMethod = { _ in
            return "102030405060708090102030405060708090102030405060708090".data(using: .utf8)
        }
        return mock
    }()

    var _authenticationResult: AppLockAuthenticationResult = .unavailable
    var _evaluationContext = LAContext()

    var mockConversationDirectory = MockConversationDirectory()

    var setEncryptionAtRest: [(enabled: Bool, skipMigration: Bool)] = []

    var unlockDatabase: [LAContext] = []

    var openApp: [Void] = []

    var evaluateAuthentication: [(preference: Preference, description: String, callback: Callback)] = []

    var evaluateAuthenticationWithCustomPasscode: [String] = []

    var _passcode: String?

    var networkState: ZMNetworkState = .offline

    var selfUser: UserType
    var selfLegalHoldSubject: SelfLegalHoldSubject & UserType
    var mockConversationList: ZMConversationList?

    convenience init(mockUser: MockZMEditableUser) {
        self.init(
            selfUser: mockUser,
            selfLegalHoldSubject: mockUser
        )
    }

    convenience init(mockUser: MockUserType = .createDefaultSelfUser()) {
        self.init(
            selfUser: mockUser,
            selfLegalHoldSubject: mockUser
        )
    }

    init(
        selfUser: UserType,
        selfLegalHoldSubject: SelfLegalHoldSubject & UserType
    ) {
        self.selfUser = selfUser
        self.selfLegalHoldSubject = selfLegalHoldSubject
    }

    var lock: SessionLock? = .screen

    var isLocked = false
    var requiresScreenCurtain = false
    var isAppLockActive: Bool = false
    var isAppLockAvailable: Bool = false
    var isAppLockForced: Bool = false
    var appLockTimeout: UInt = 60
    var requireCustomAppLockPasscode: Bool  = false
    var isCustomAppLockPasscodeSet: Bool = false
    var needsToNotifyUserOfAppLockConfiguration: Bool = false

    func openAppLock() throws {
        openApp.append(())
    }

    func evaluateAppLockAuthentication(
        passcodePreference: AppLockPasscodePreference,
        description: String,
        callback: @escaping (
            AppLockAuthenticationResult,
            LAContextProtocol
        ) -> Void
    ) {
        evaluateAuthentication.append((passcodePreference, description, callback))
        callback(_authenticationResult, _evaluationContext)
    }

    func evaluateAuthentication(customPasscode: String) -> AppLockAuthenticationResult {
        evaluateAuthenticationWithCustomPasscode.append(customPasscode)
        return _passcode == customPasscode ? .granted : .denied
    }

    func unlockDatabase(with context: LAContext) throws {
        unlockDatabase.append(context)
    }

    var maxAudioMessageLength: TimeInterval = 1500 // 25 minutes (25 * 60.0)
    var maxUploadFileSize: UInt64 = 26214400 // 25 megabytes (25 * 1024 * 1024)
    var maxVideoLength: TimeInterval = 240 // 4 minutes (4.0 * 60.0)

    var shouldNotifyUserOfDisabledAppLock = false
    var isNotificationContentHidden = false
    var encryptMessagesAtRest = false
    var ringingCallConversation: ZMConversation?

    var deleteAppLockPasscodeCalls = 0
    func deleteAppLockPasscode() throws {
        deleteAppLockPasscodeCalls += 1
    }

    var conversationDirectory: ConversationDirectoryType {
        return mockConversationDirectory
    }

    func perform(_ changes: @escaping () -> Void) {
        changes()
    }

    func enqueue(_ changes: @escaping () -> Void) {
        changes()
    }

    func enqueue(_ changes: @escaping () -> Void, completionHandler: (() -> Void)?) {
        fatalError("not implemented")
    }

    func addUserObserver(_ observer: UserObserving, for user: UserType) -> NSObjectProtocol? {
        return nil
    }

    func addUserObserver(_ observer: UserObserving) -> NSObjectProtocol {
        return NSObject()
    }

    func addConversationListObserver(
        _ observer: WireDataModel.ZMConversationListObserver,
        for list: ZMConversationList
    ) -> NSObjectProtocol {
        return NSObject()
    }

    func conversationList() -> ZMConversationList {
        guard let mockConversationList else { fatalError("mockConversationList is not set") }
        return mockConversationList
    }

    func pendingConnectionConversationsInUserSession() -> ZMConversationList {
        guard let mockConversationList else { fatalError("mockConversationList is not set") }
        return mockConversationList
    }

    func archivedConversationsInUserSession() -> ZMConversationList {
        guard let mockConversationList else { fatalError("mockConversationList is not set") }
        return mockConversationList
    }

    func setEncryptionAtRest(
        enabled: Bool,
        skipMigration: Bool
    ) throws {
        setEncryptionAtRest.append((enabled: enabled, skipMigration: skipMigration))
    }

    func addMessageObserver(
        _ observer: ZMMessageObserver,
        for message: ZMConversationMessage
    ) -> NSObjectProtocol {
        return NSObject()
    }

    func addConferenceCallingUnavailableObserver(
        _ observer: ConferenceCallingUnavailableObserver
    ) -> Any {
        return NSObject()
    }

    func addConferenceCallStateObserver(
        _ observer: WireCallCenterCallStateObserver
    ) -> Any {
        return NSObject()
    }

    func addConferenceCallErrorObserver(
        _ observer: WireCallCenterCallErrorObserver
    ) -> Any {
        return NSObject()
    }

    func acknowledgeFeatureChange(for feature: Feature.Name) {

    }

    func fetchMarketingConsent(
        completion: @escaping (
            Result<Bool, Error>
        ) -> Void
    ) {

    }

    func setMarketingConsent(
        granted: Bool,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {

    }

    func classification(
        with users: [UserType],
        conversationDomain: String?
    ) -> SecurityClassification {
        return .none
    }

    func proxiedRequest(
        path: String,
        method: ZMTransportRequestMethod,
        type: WireSyncEngine.ProxiedRequestType,
        callback: WireSyncEngine.ProxyRequestCallback?
    ) -> WireSyncEngine.ProxyRequest {
        return ProxyRequest(type: type, path: path, method: method, callback: callback)
    }

    func cancelProxiedRequest(_ request: WireSyncEngine.ProxyRequest) {

    }

    var getUserClientFingerprint: GetUserClientFingerprintUseCaseProtocol {
        mockGetUserClientFingerprintUseCaseProtocol
    }

    lazy var isSelfUserProteusVerifiedUseCase: IsSelfUserProteusVerifiedUseCaseProtocol = MockIsSelfUserProteusVerifiedUseCaseProtocol()
    lazy var isSelfUserE2EICertifiedUseCase: IsSelfUserE2EICertifiedUseCaseProtocol = MockIsSelfUserE2EICertifiedUseCaseProtocol()

    var selfUserClient: UserClient? {
        return nil
    }

    var enrollE2EICertificate: EnrollE2EICertificateUseCaseProtocol {
        MockEnrollE2EICertificateUseCaseProtocol()
    }

    var getIsE2eIdentityEnabled: GetIsE2EIdentityEnabledUseCaseProtocol {
        MockGetIsE2EIdentityEnabledUseCaseProtocol()
    }

    var getE2eIdentityCertificates: GetE2eIdentityCertificatesUseCaseProtocol {
        MockGetE2eIdentityCertificatesUseCaseProtocol()
    }

    var updateMLSGroupVerificationStatus: UpdateMLSGroupVerificationStatusUseCaseProtocol {
        MockUpdateMLSGroupVerificationStatusUseCaseProtocol()
    }

    var e2eiFeature: Feature.E2EI = Feature.E2EI(status: .enabled)

    func fetchAllClients() {}
}
