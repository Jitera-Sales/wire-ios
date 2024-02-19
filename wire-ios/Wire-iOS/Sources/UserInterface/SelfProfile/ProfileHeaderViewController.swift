//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

import UIKit
import WireSyncEngine
import WireCommonComponents

final class ProfileHeaderViewController: UIViewController {

    /// The options to customize the appearance and behavior of the view.
    var options: Options {
        didSet { applyOptions() }
    }

    /// Associated conversation, if displayed in the context of a conversation
    private let conversation: ZMConversation?

    private var userStatus: UserStatus {
        didSet { updateNameAndVerificationStatus() }
    }

    /// The user that is displayed.
    private let user: UserType

    private let userSession: UserSession

    /// The user who is viewing this view
    private let viewer: UserType

    /// The current group admin status.
    var isAdminRole: Bool {
        didSet { groupRoleIndicator.isHidden = !isAdminRole }
    }

    private var stackView: CustomSpacingStackView!

    typealias AccountPageStrings = L10n.Accessibility.AccountPage
    typealias LabelColors = SemanticColors.Label

    private let nameLabel: DynamicFontLabel = {
        let label = DynamicFontLabel(fontSpec: .accountName, color: LabelColors.textDefault)
        label.accessibilityLabel = AccountPageStrings.Name.description
        label.accessibilityIdentifier = "name"

        label.setContentHuggingPriority(UILayoutPriority.required, for: .vertical)
        label.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)

        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        label.accessibilityTraits.insert(.header)
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 3
        label.textAlignment = .center

        return label
    }()

    private let e2eiCertifiedImageView = {
        let imageView = UIImageView(image: .init(resource: .certificateValid))
        imageView.contentMode = .center
        imageView.isHidden = true
        return imageView
    }()
    private let proteusVerifiedImageView = {
        let imageView = UIImageView(image: .init(resource: .verifiedShield))
        imageView.contentMode = .center
        imageView.isHidden = true
        return imageView
    }()

    private let handleLabel = DynamicFontLabel(fontSpec: .mediumRegularFont, color: LabelColors.textDefault)
    private let teamNameLabel = DynamicFontLabel(fontSpec: .accountTeam, color: LabelColors.textDefault)
    private let remainingTimeLabel = DynamicFontLabel(fontSpec: .mediumSemiboldFont, color: LabelColors.textDefault)
    let imageView =  UserImageView(size: .big)
    private let userStatusViewController: UserStatusViewController

    private let guestIndicatorStack = UIStackView()
    private let groupRoleIndicator = LabelIndicator(context: .groupRole)

    private let guestIndicator = LabelIndicator(context: .guest)
    private let externalIndicator = LabelIndicator(context: .external)
    private let federatedIndicator = LabelIndicator(context: .federated)
    private let warningView = WarningLabelView()

    private var tokens: [Any?] = []
    private var teamObserver: NSObjectProtocol?

    /**
     * Creates a profile view for the specified user and options.
     * - parameter user: The user to display the profile of.
     * - parameter conversation: The conversation.
     * - parameter options: The options for the appearance and behavior of the view.
     * - parameter userSession: The user session.
     * - note: You can change the options later through the `options` property.
     */
    init(user: UserType, viewer: UserType, conversation: ZMConversation? = nil, options: Options, userSession: UserSession) {
        userStatus = .init(
            user: user,
            isCertified: false // TODO [WPB-765]: provide value after merging into `epic/e2ei`
        )
        print("user.isVerified", user.isVerified)
        self.user = user
        self.userSession = userSession
        isAdminRole = conversation.map(self.user.isGroupAdmin) ?? false
        self.viewer = viewer
        self.conversation = conversation
        self.options = options
        userStatusViewController = .init(
            options: options.contains(.allowEditingAvailability) ? [.allowSettingStatus] : [.hideActionHint],
            settings: .shared
        )

        super.init(nibName: nil, bundle: nil)

        userStatusViewController.delegate = self
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        let session = SessionManager.shared?.activeUserSession

        imageView.isAccessibilityElement = true
        imageView.accessibilityElementsHidden = false
        imageView.accessibilityIdentifier = "user image"
        imageView.setImageConstraint(resistance: 249, hugging: 750)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        imageView.initialsFont = UIFont.systemFont(ofSize: 55, weight: .semibold).monospaced()
        imageView.userSession = session
        imageView.user = user

        if !ProcessInfo.processInfo.isRunningTests,
           let session = session {
            tokens.append(UserChangeInfo.add(observer: self, for: user, in: session))
        }

        handleLabel.accessibilityLabel = AccountPageStrings.Handle.description
        handleLabel.accessibilityIdentifier = "username"
        handleLabel.setContentHuggingPriority(UILayoutPriority.required, for: .vertical)
        handleLabel.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)

        let nameShieldStackView = UIStackView(arrangedSubviews: [nameLabel, e2eiCertifiedImageView, proteusVerifiedImageView])
        nameShieldStackView.axis = .horizontal
        nameShieldStackView.spacing = 4

        let nameHandleStack = UIStackView(arrangedSubviews: [nameShieldStackView, handleLabel])
        nameHandleStack.axis = .vertical
        nameHandleStack.alignment = .center
        nameHandleStack.spacing = 8

        teamNameLabel.accessibilityLabel = AccountPageStrings.TeamName.description
        teamNameLabel.accessibilityIdentifier = "team name"
        teamNameLabel.setContentHuggingPriority(UILayoutPriority.required, for: .vertical)
        teamNameLabel.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)

        nameLabel.text = user.name
        nameLabel.accessibilityValue = nameLabel.text

        let remainingTimeString = user.expirationDisplayString
        remainingTimeLabel.text = remainingTimeString
        remainingTimeLabel.isHidden = remainingTimeString == nil

        guestIndicatorStack.addArrangedSubview(guestIndicator)
        guestIndicatorStack.addArrangedSubview(remainingTimeLabel)
        guestIndicatorStack.spacing = 12
        guestIndicatorStack.axis = .vertical
        guestIndicatorStack.alignment = .center

        updateGuestIndicator()
        updateExternalIndicator()
        updateFederatedIndicator()
        updateGroupRoleIndicator()
        updateHandleLabel()
        updateTeamLabel()
        updateNameAndVerificationStatus()

        addChild(userStatusViewController)

        stackView = CustomSpacingStackView(
            customSpacedArrangedSubviews: [
                nameHandleStack,
                teamNameLabel,
                imageView,
                userStatusViewController.view,
                guestIndicatorStack,
                externalIndicator,
                federatedIndicator,
                groupRoleIndicator,
                warningView
            ]
        )

        stackView.alignment = .center
        stackView.axis = .vertical

        stackView.wr_addCustomSpacing(32, after: nameHandleStack)
        stackView.wr_addCustomSpacing(32, after: teamNameLabel)
        stackView.wr_addCustomSpacing(24, after: imageView)
        stackView.wr_addCustomSpacing(20, after: guestIndicatorStack)
        stackView.wr_addCustomSpacing(20, after: externalIndicator)
        stackView.wr_addCustomSpacing(20, after: federatedIndicator)

        view.addSubview(stackView)

        guestIndicator.tintColor = SemanticColors.Icon.foregroundDefault
        view.backgroundColor = UIColor.clear

        configureConstraints()
        applyOptions()

        userStatusViewController.didMove(toParent: self)

        if let team = (user as? ZMUser)?.team {
            teamObserver = TeamChangeInfo.add(observer: self, for: team)
        }
        view.backgroundColor = UIColor.clear
    }

    private func configureConstraints() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let leadingSpaceConstraint = stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40)
        let topSpaceConstraint = stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20)
        let trailingSpaceConstraint = stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        let bottomSpaceConstraint = stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)

        let widthImageConstraint = imageView.widthAnchor.constraint(lessThanOrEqualToConstant: 164)
        NSLayoutConstraint.activate([
            // stackView
            widthImageConstraint, leadingSpaceConstraint, topSpaceConstraint, trailingSpaceConstraint, bottomSpaceConstraint
        ])
    }

    private func updateGuestIndicator() {
        if let conversation = conversation {
            guestIndicatorStack.isHidden = !user.isGuest(in: conversation)
        } else {
            guestIndicatorStack.isHidden = !viewer.isTeamMember || viewer.canAccessCompanyInformation(of: user)
        }
    }

    private func updateExternalIndicator() {
        externalIndicator.isHidden = !user.isExternalPartner
    }

    private func updateFederatedIndicator() {
        federatedIndicator.isHidden = !user.isFederated
    }

    private func updateGroupRoleIndicator() {
        let groupRoleIndicatorHidden: Bool
        switch conversation?.conversationType {
        case .group?:
            groupRoleIndicatorHidden = !(conversation.map(user.isGroupAdmin) ?? false)
        default:
            groupRoleIndicatorHidden = true
        }
        groupRoleIndicator.isHidden = groupRoleIndicatorHidden

    }

    private func applyOptions() {
        updateHandleLabel()
        updateTeamLabel()
        updateImageButton()
        updateAvailabilityVisibility()
        warningView.update(withUser: user)
    }

    private func updateNameAndVerificationStatus() {
        userStatusViewController.userStatus = userStatus
        e2eiCertifiedImageView.isHidden = !userStatus.isCertified
        proteusVerifiedImageView.isHidden = !userStatus.isVerified
    }

    private func updateHandleLabel() {
        if let handle = user.handle, !handle.isEmpty {
            handleLabel.text = "@" + handle
            handleLabel.accessibilityValue = handleLabel.text
        } else {
            handleLabel.isHidden = true
        }
    }

    private func updateTeamLabel() {
        if let teamName = user.teamName, !options.contains(.hideTeamName) {
            teamNameLabel.text = teamName
            teamNameLabel.accessibilityValue = teamNameLabel.text
            teamNameLabel.isHidden = false
        } else {
            teamNameLabel.isHidden = true
        }
    }

    private func updateAvailabilityVisibility() {
        let isHidden = options.contains(.hideAvailability) || !options.contains(.allowEditingAvailability) && user.availability == .none
        userStatusViewController.view?.isHidden = isHidden
    }

    private func updateImageButton() {
        if options.contains(.allowEditingProfilePicture) {
            imageView.accessibilityLabel = AccountPageStrings.ProfilePicture.description
            imageView.accessibilityHint = AccountPageStrings.ProfilePicture.hint
            imageView.accessibilityTraits = .button
            imageView.isUserInteractionEnabled = true
        } else {
            imageView.accessibilityLabel = AccountPageStrings.ProfilePicture.description
            imageView.accessibilityTraits = [.image]
            imageView.isUserInteractionEnabled = false
        }
    }

    // MARK: -

    /// The options to customize the appearance and behavior of the view.
    struct Options: OptionSet {

        let rawValue: Int

        /// Whether to hide the availability status of the user.
        static let hideAvailability = Options(rawValue: 1 << 2)

        /// Whether to hide the team name of the user.
        static let hideTeamName = Options(rawValue: 1 << 3)

        /// Whether to allow the user to change their availability.
        static let allowEditingAvailability = Options(rawValue: 1 << 4)

        /// Whether to allow the user to change their availability.
        static let allowEditingProfilePicture = Options(rawValue: 1 << 5)

    }
}

// MARK: - UserStatusViewControllerDelegate

extension ProfileHeaderViewController: UserStatusViewControllerDelegate {

    func userStatusViewController(_ viewController: UserStatusViewController, didSelect availability: Availability) {
        guard viewController === userStatusViewController else { return }

        userSession.perform { [weak self] in
            self?.user.availability = availability
        }
    }
}

// MARK: - ZMUserObserving

extension ProfileHeaderViewController: UserObserving {

    func userDidChange(_ changes: UserChangeInfo) {

        if changes.nameChanged {
            userStatus.name = changes.user.name ?? ""
            nameLabel.text = changes.user.name
        }

        if changes.availabilityChanged {
            userStatus.availability = changes.user.availability
            updateAvailabilityVisibility()
        }

        if changes.handleChanged {
            updateHandleLabel()
        }
    }
}

extension ProfileHeaderViewController: TeamObserver {

    func teamDidChange(_ changes: TeamChangeInfo) {

        if changes.nameChanged {
            updateTeamLabel()
        }
    }
}
