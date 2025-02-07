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

import avs
import UIKit
import WireDataModel
import WireDesign
import WireSyncEngine

private let zmLog = ZMSLog(tag: "calling")

protocol ActiveCallViewControllerDelegate: AnyObject {
    func activeCallViewControllerDidDisappear(_ activeCallViewController: UIViewController,
                                              for conversation: ZMConversation?)
}

protocol CallInfoConfigurationObserver: AnyObject {
    func didUpdateConfiguration(configuration: CallInfoConfiguration)
}

final class CallingBottomSheetViewController: BottomSheetContainerViewController {
    private let bottomSheetMaxHeight = UIScreen.main.bounds.height * 0.7

    weak var delegate: ActiveCallViewControllerDelegate?
    private var participantsObserverToken: Any?
    private var voiceChannel: VoiceChannel
    private let headerBar = CallHeaderBar()
    private let overlay = PassThroughOpaqueView()
    private var callStateObserverToken: Any?
    private weak var callDurationTimer: Timer?
    private var callInfoConfiguration: CallInfoConfiguration?
    private let callDegradationController = CallDegradationController()

    var bottomSheetMinimalOffset: CGFloat {
        return callingActionsInfoViewController.actionsViewHeightConstraint.constant
    }

    let userSession: UserSession

    let callingActionsInfoViewController: CallingActionsInfoViewController
    var visibleVoiceChannelViewController: CallViewController {
        didSet {
            transition(to: visibleVoiceChannelViewController, from: oldValue)
        }
    }

    init(voiceChannel: VoiceChannel, userSession: UserSession) {
        self.voiceChannel = voiceChannel
        self.userSession = userSession

        visibleVoiceChannelViewController = CallViewController(voiceChannel: voiceChannel, selfUser: userSession.selfUser, isOverlayEnabled: false, userSession: userSession)
        callingActionsInfoViewController = CallingActionsInfoViewController(participants: voiceChannel.getParticipantsList(), selfUser: userSession.selfUser)
        super.init(contentViewController: visibleVoiceChannelViewController, bottomSheetViewController: callingActionsInfoViewController, bottomSheetConfiguration: .init(height: bottomSheetMaxHeight, initialOffset: 112.0))

        callingActionsInfoViewController.setCallingActionsViewDelegate(actionsDelegate: visibleVoiceChannelViewController)
        callingActionsInfoViewController.actionsView.bottomSheetScrollingDelegate = self
        visibleVoiceChannelViewController.configurationObserver = self
        participantsObserverToken = voiceChannel.addParticipantObserver(self)
        visibleVoiceChannelViewController.delegate = self

        callDegradationController.targetViewController = self
        view.insertSubview(overlay, belowSubview: bottomSheetViewController.view)
        view.insertSubview(headerBar, belowSubview: overlay)
        setupViews()
        addConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        stopCallDurationTimer()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let userSession = ZMUserSession.shared() else {
            zmLog.error("UserSession not available when initializing \(type(of: self))")
            return
        }
        callStateObserverToken = WireCallCenterV3.addCallStateObserver(observer: self, userSession: userSession)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        visibleVoiceChannelViewController.reloadGrid()
    }

    private func setupViews() {
        view.backgroundColor = SemanticColors.View.backgroundDefault
        headerBar.minimalizeButton.addTarget(self, action: #selector(hideCallView), for: .touchUpInside)
        overlay.alpha = 0.0
        overlay.backgroundColor = SemanticColors.View.backgroundCallOverlay
        addToSelf(callDegradationController)
        callDegradationController.delegate = self
    }

    private func addConstraints() {
        headerBar.translatesAutoresizingMaskIntoConstraints = false
        overlay.translatesAutoresizingMaskIntoConstraints = false
        callDegradationController.view.fitIn(view: view)

        NSLayoutConstraint.activate([
            headerBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerBar.bottomAnchor.constraint(equalTo: visibleVoiceChannelViewController.view.topAnchor).withPriority(.required),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // after rotating device recalculate bottom sheet max height
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        updateConstraints(forHeight: size.height)
    }

    private func updateConstraints(forHeight height: CGFloat) {
        let isLandscape = UIDevice.current.twoDimensionOrientation.isLandscape
        // if landscape then bottom sheet should take whole screen (without headerBar)
        let bottomSheetMaxHeight = isLandscape ? (height - headerBar.bounds.height) : bottomSheetMaxHeight
        let newConfiguration = BottomSheetConfiguration(height: bottomSheetMaxHeight, initialOffset: bottomSheetMinimalOffset)
        guard self.configuration != newConfiguration else { return }
        self.configuration = newConfiguration
        callingActionsInfoViewController.updateActionViewHeight()
        callingActionsInfoViewController.actionsView.viewWillRotate(toPortrait: !isLandscape)
        hideBottomSheet()
    }

    override func didChangeState() {
        switch state {
        case .initial:
            visibleVoiceChannelViewController.view.accessibilityElementsHidden = false
            visibleVoiceChannelViewController.view.isUserInteractionEnabled = true
        case .full:
            visibleVoiceChannelViewController.view.accessibilityElementsHidden = true
            visibleVoiceChannelViewController.view.isUserInteractionEnabled = false
        }
    }

    func transition(to toViewController: CallViewController, from fromViewController: CallViewController) {
        guard toViewController != fromViewController else { return }
        addChild(toViewController)

        transition(from: fromViewController,
                   to: toViewController,
                   duration: 0.35,
                   options: .transitionCrossDissolve,
                   animations: nil,
                   completion: { _ in
            self.addContentViewController(contentViewController: toViewController)
            NSLayoutConstraint.activate(
                [self.headerBar.bottomAnchor.constraint(equalTo: toViewController.view.topAnchor).withPriority(.required)])
            fromViewController.removeFromParent()
            self.view.bringSubviewToFront(self.bottomSheetViewController.view)
        })
    }

    func updateVisibleVoiceChannelViewController() {
        guard
            let conversation = ZMUserSession.shared()?.priorityCallConversation,
            visibleVoiceChannelViewController.conversation != conversation,
            let voiceChannel = conversation.voiceChannel
        else {
            return
        }

        self.voiceChannel = voiceChannel
        visibleVoiceChannelViewController = CallViewController(voiceChannel: voiceChannel, selfUser: userSession.selfUser, isOverlayEnabled: false, userSession: userSession)
        visibleVoiceChannelViewController.configurationObserver = self
        visibleVoiceChannelViewController.delegate = self
        callingActionsInfoViewController.setCallingActionsViewDelegate(actionsDelegate: visibleVoiceChannelViewController)
        callingActionsInfoViewController.participants = voiceChannel.getParticipantsList()
        participantsObserverToken = voiceChannel.addParticipantObserver(self)
    }

    override func bottomSheetChangedOffset(fullHeightPercentage: CGFloat) {
        overlay.alpha = fullHeightPercentage * 0.7
    }

    private func updateState() {
        switch callInfoConfiguration?.state {
        case .established: startCallDurationTimer()
        case .terminating: stopCallDurationTimer()
        default: break
        }
    }

    private func startCallDurationTimer() {
        stopCallDurationTimer()
        callDurationTimer = .scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let configuration = self?.callInfoConfiguration, case .established = configuration.state else { return }
            self?.headerBar.updateConfiguration(configuration: configuration)
        }
    }

    private func stopCallDurationTimer() {
        callDurationTimer?.invalidate()
        callDurationTimer = nil
    }
}

extension CallingBottomSheetViewController: CallInfoConfigurationObserver {
    func didUpdateConfiguration(configuration: CallInfoConfiguration) {
        if configuration.state != callInfoConfiguration?.state {
            if case .established = configuration.state {
                headerBar.updateConfiguration(configuration: configuration)
            }
            visibleVoiceChannelViewController.reloadGrid()
            callInfoConfiguration = configuration
            updateState()
        } else {
            callInfoConfiguration = configuration
        }

        callDegradationController.state = configuration.degradationState
        callingActionsInfoViewController.didUpdateConfiguration(configuration: configuration)
        panGesture.isEnabled = !configuration.state.isIncoming
        updateConstraints(forHeight: view.bounds.height)
    }
}

extension CallingBottomSheetViewController: WireCallCenterCallParticipantObserver {
    func callParticipantsDidChange(conversation: ZMConversation, participants: [CallParticipant]) {
        callingActionsInfoViewController.participants = voiceChannel.getParticipantsList()
    }
}

extension CallingBottomSheetViewController: WireCallCenterCallStateObserver {
    func callCenterDidChange(callState: CallState, conversation: ZMConversation, caller: UserType, timestamp: Date?, previousCallState: CallState?) {
        updateVisibleVoiceChannelViewController()
    }
}

extension CallingBottomSheetViewController: CallDegradationControllerDelegate {
    func continueDegradedCall() {
        visibleVoiceChannelViewController.callingActionsViewPerformAction(.continueDegradedCall)
    }

    func cancelDegradedCall() {
        visibleVoiceChannelViewController.callingActionsViewPerformAction(.terminateDegradedCall)
    }
}

extension CallingBottomSheetViewController: CallViewControllerDelegate {
    func callViewControllerDidDisappear(_ callController: CallViewController,
                                        for conversation: ZMConversation?) {
        delegate?.activeCallViewControllerDidDisappear(self, for: conversation)
    }

    @objc func hideCallView() {
        delegate?.activeCallViewControllerDidDisappear(self, for: voiceChannel.conversation)
    }
}

extension VoiceChannel {
    fileprivate func getParticipantsList() -> CallParticipantsList {
        let sortedParticipants = participants(
            ofKind: .all,
            activeSpeakersLimit: CallInfoConfiguration.maxActiveSpeakers
        )

        return sortedParticipants.map {
            CallParticipantsListCellConfiguration.callParticipant(
                user: HashBox(value: $0.user),
                callParticipantState: $0.state,
                activeSpeakerState: $0.activeSpeakerState
            )
        }
    }
}

private final class PassThroughOpaqueView: UIView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
            return false
    }
}
