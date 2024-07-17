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

/// Number of autogenerated names to try as handles
private let alternativeAutogeneratedNames = 3

/// Tracks the status of request to update the user profile
@objcMembers public class UserProfileUpdateStatus: NSObject {

    /// email to set
    fileprivate(set) var emailToSet: String?

    /// password to set
    fileprivate(set) var passwordToSet: String?

    /// handle to check for availability
    fileprivate(set) var handleToCheck: String?

    /// handle to check
    fileprivate(set) var handleToSet: String?

    /// last set password and email
    fileprivate(set) var lastEmailAndPassword: UserEmailCredentials?

    /// suggested handles to check for availability
    fileprivate(set) var suggestedHandlesToCheck: [String]?

    /// best handle suggestion found so far
    fileprivate(set) public var bestHandleSuggestion: String?

    /// analytics instance used to perform the tracking calls
    fileprivate weak var analytics: AnalyticsType?

    let managedObjectContext: NSManagedObjectContext

    /// Callback invoked when there is a new request to send
    let newRequestCallback: () -> Void

    public convenience init(managedObjectContext: NSManagedObjectContext) {
        self.init(managedObjectContext: managedObjectContext, analytics: managedObjectContext.analytics)
    }

    // This separate initializer is needed as functions with default arguments are not visible in objective-c
    init(managedObjectContext: NSManagedObjectContext, analytics: AnalyticsType?) {
        self.managedObjectContext = managedObjectContext
        self.newRequestCallback = { RequestAvailableNotification.notifyNewRequestsAvailable(nil) }
        self.analytics = analytics
    }

}

// MARK: - User profile protocol
extension UserProfileUpdateStatus: UserProfile {

    public var lastSuggestedHandle: String? {
        return self.bestHandleSuggestion
    }

    public func requestEmailChange(email: String) throws {
        guard !email.isEmpty else {
            throw UserProfileUpdateError.missingArgument
        }

        self.managedObjectContext.performGroupedBlock {
            let selfUser = ZMUser.selfUser(in: self.managedObjectContext)
            guard selfUser.emailAddress != nil else {
                self.didFailEmailUpdate(error: UserProfileUpdateError.emailNotSet)
                return
            }

            self.emailToSet = email
            self.newRequestCallback()
        }
    }

    public func requestSettingEmailAndPassword(credentials: UserEmailCredentials) throws {
        guard let email = credentials.email, let password = credentials.password else {
            throw UserProfileUpdateError.missingArgument
        }

        self.managedObjectContext.performGroupedBlock {
            let selfUser = ZMUser.selfUser(in: self.managedObjectContext)
            guard selfUser.emailAddress == nil else {
                self.didFailEmailUpdate(error: UserProfileUpdateError.emailAlreadySet)
                return
            }

            self.lastEmailAndPassword = credentials

            self.emailToSet = email
            self.passwordToSet = password

            self.newRequestCallback()
        }
    }

    public func cancelSettingEmailAndPassword() {
        self.managedObjectContext.performGroupedBlock {
            self.lastEmailAndPassword = nil
            self.emailToSet = nil
            self.passwordToSet = nil
            self.newRequestCallback()
        }
    }

    public func requestCheckHandleAvailability(handle: String) {
        self.managedObjectContext.performGroupedBlock {
            self.handleToCheck = handle
            self.newRequestCallback()
        }
    }

    public func requestSettingHandle(handle: String) {
        self.managedObjectContext.performGroupedBlock {
            self.handleToSet = handle
            self.newRequestCallback()
        }
    }

    public func cancelSettingHandle() {
        self.managedObjectContext.performGroupedBlock {
            self.handleToSet = nil
        }
    }

    public func suggestHandles() {
        self.managedObjectContext.performGroupedBlock {
            guard self.suggestedHandlesToCheck == nil else {
                // already searching
                return
            }

            if let bestHandle = self.bestHandleSuggestion {
                self.suggestedHandlesToCheck = [bestHandle]
            } else {
                let name = ZMUser.selfUser(in: self.managedObjectContext).name
                self.suggestedHandlesToCheck = RandomHandleGenerator.generatePossibleHandles(displayName: name ?? "",
                                                                                             alternativeNames: alternativeAutogeneratedNames)
            }
            self.newRequestCallback()
        }
    }

}

// MARK: - Update status
extension UserProfileUpdateStatus {

    /// Invoked when the request to set password succedeed
    func didUpdatePasswordSuccessfully() {
        self.passwordToSet = nil
    }

    /// Invoked when the request to set password failed
    func didFailPasswordUpdate() {
        self.lastEmailAndPassword = nil
        self.emailToSet = nil
        self.passwordToSet = nil
        UserProfileUpdateNotification(type: .passwordUpdateDidFail).post(in: managedObjectContext.notificationContext)
    }

    /// Invoked when the request to change email was sent successfully
    func didUpdateEmailSuccessfully() {
        self.emailToSet = nil
        UserProfileUpdateNotification(type: .emailDidSendVerification).post(in: managedObjectContext.notificationContext)
    }

    /// Invoked when the request to change email failed
    func didFailEmailUpdate(error: Error) {
        self.lastEmailAndPassword = nil
        self.emailToSet = nil
        self.passwordToSet = nil
        UserProfileUpdateNotification(type: .emailUpdateDidFail(error: error)).post(in: managedObjectContext.notificationContext)
    }

    /// Invoked when the request to fetch a handle returned not found
    func didNotFindHandle(handle: String) {
        if self.handleToCheck == handle {
            self.handleToCheck = nil
        }
        UserProfileUpdateNotification(type: .didCheckAvailabilityOfHandle(handle: handle, available: true)).post(in: managedObjectContext.notificationContext)
    }

    /// Invoked when the request to fetch a handle returned successfully
    func didFetchHandle(handle: String) {
        if self.handleToCheck == handle {
            self.handleToCheck = nil
        }
        UserProfileUpdateNotification(type: .didCheckAvailabilityOfHandle(handle: handle, available: false)).post(in: managedObjectContext.notificationContext)
    }

    /// Invoked when the request to fetch a handle failed with
    /// an error that is not "not found"
    func didFailRequestToFetchHandle(handle: String) {
        if self.handleToCheck == handle {
            self.handleToCheck = nil
        }
        UserProfileUpdateNotification(type: .didFailToCheckAvailabilityOfHandle(handle: handle)).post(in: managedObjectContext.notificationContext)
    }

    /// Invoked when the handle was succesfully set
    func didSetHandle() {
        if let handle = self.handleToSet {
            ZMUser.selfUser(in: self.managedObjectContext).handle = handle
        }
        self.handleToSet = nil
        UserProfileUpdateNotification(type: .didSetHandle).post(in: managedObjectContext.notificationContext)

    }

    /// Invoked when the handle was not set because of a generic error
    func didFailToSetHandle() {
        self.handleToSet = nil
        UserProfileUpdateNotification(type: .didFailToSetHandle).post(in: managedObjectContext.notificationContext)
    }

    /// Invoked when the handle was not set because it was already existing
    func didFailToSetAlreadyExistingHandle() {
        self.handleToSet = nil
        UserProfileUpdateNotification(type: .didFailToSetHandleBecauseExisting).post(in: managedObjectContext.notificationContext)
    }

    /// Invoked when a good handle suggestion is found
    func didFindHandleSuggestion(handle: String) {
        self.bestHandleSuggestion = handle
        self.suggestedHandlesToCheck = nil
        UserProfileUpdateNotification(type: .didFindHandleSuggestion(handle: handle)).post(in: managedObjectContext.notificationContext)
    }

    /// Invoked when all potential suggested handles were not available
    func didNotFindAvailableHandleSuggestion() {
        if ZMUser.selfUser(in: self.managedObjectContext).handle != nil {
            // it has handle, no need to keep suggesting
            self.suggestedHandlesToCheck = nil
        } else {
            let name = ZMUser.selfUser(in: self.managedObjectContext).name
            self.suggestedHandlesToCheck = RandomHandleGenerator.generatePossibleHandles(displayName: name ?? "",
                                                                                     alternativeNames: alternativeAutogeneratedNames)
        }
    }

    /// Invoked when failed to fetch handle suggestion
    func didFailToFindHandleSuggestion() {
        self.suggestedHandlesToCheck = nil
    }

}

// MARK: - Data
extension UserProfileUpdateStatus: ZMCredentialProvider {

    /// The email credentials being set
    public func emailCredentials() -> UserEmailCredentials? {
        guard !self.currentlySettingEmail && !self.currentlySettingPassword else {
            return nil
        }
        return self.lastEmailAndPassword
    }

    public func credentialsMayBeCleared() {
        self.lastEmailAndPassword = nil
    }
}

// MARK: - External status
extension UserProfileUpdateStatus {

    /// Whether the current user has an email set in the profile
    private var selfUserHasEmail: Bool {
        let selfUser = ZMUser.selfUser(in: self.managedObjectContext)
        return selfUser.emailAddress != nil && selfUser.emailAddress != ""
    }

    /// Whether the current user has a phone number set in the profile
    private var selfUserHasPhoneNumber: Bool {
        let selfUser = ZMUser.selfUser(in: self.managedObjectContext)
        return selfUser.phoneNumber != nil && selfUser.phoneNumber != ""
    }

    /// Whether we are currently changing email
    public var currentlyChangingEmail: Bool {
        guard self.selfUserHasEmail else {
            return false
        }
        return self.emailToSet != nil
    }

    /// Whether we are currently setting the email.
    public var currentlySettingEmail: Bool {

        guard !self.selfUserHasEmail else {
            return false
        }
        return self.emailToSet != nil && self.passwordToSet == nil
    }

    /// Whether we are currently setting the password.
    public var currentlySettingPassword: Bool {

        guard !self.selfUserHasEmail else {
            return false
        }
        return self.passwordToSet != nil
    }

    /// Whether we are currently waiting to check for availability of a handle
    public var currentlyCheckingHandleAvailability: Bool {
        return self.handleToCheck != nil
    }

    /// Whether we are currently requesting a change of handle
    public var currentlySettingHandle: Bool {
        return self.handleToSet != nil
    }

    /// Whether we are currently looking for a valid suggestion for a handle
    public var currentlyGeneratingHandleSuggestion: Bool {
        return ZMUser.selfUser(in: self.managedObjectContext).handle == nil && self.suggestedHandlesToCheck != nil
    }
}

// MARK: - Helpers

/// Errors
public enum UserProfileUpdateError: Int, Error {
    case missingArgument
    case emailAlreadySet
    case emailNotSet
    case removingLastIdentity
}
