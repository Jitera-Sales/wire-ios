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

import MessageUI
import WireCommonComponents
import WireSyncEngine

final class SettingsDebugReportViewModel: SettingsDebugReportViewModelProtocol {

    // MARK: - Properties

    private let router: SettingsDebugReportRouterProtocol
    private let shareFile: ShareFileUseCaseProtocol
    private let fetchShareableConversations: FetchShareableConversationsUseCaseProtocol
    private let logsProvider: LogFilesProviding
    private let fileMetaDataGenerator: FileMetaDataGeneratorProtocol

    // MARK: - Life cycle

    init(
        router: SettingsDebugReportRouterProtocol,
        shareFile: ShareFileUseCaseProtocol,
        fetchShareableConversations: FetchShareableConversationsUseCaseProtocol,
        logsProvider: LogFilesProviding = LogFilesProvider(),
        fileMetaDataGenerator: FileMetaDataGeneratorProtocol
    ) {
        self.router = router
        self.shareFile = shareFile
        self.fetchShareableConversations = fetchShareableConversations
        self.logsProvider = logsProvider
        self.fileMetaDataGenerator = fileMetaDataGenerator
    }

    // MARK: - Interface

    func sendReport(sender: UIView) {
        if MFMailComposeViewController.canSendMail() {
            Task {
                await router.presentMailComposer()
            }
        } else {
            router.presentFallbackAlert(sender: sender)
        }
    }

    @MainActor
    func shareReport() async {

        do {
            let conversations = fetchShareableConversations.invoke()
            let logsURL = try logsProvider.generateLogFilesZip()
            let metadata = await fileMetaDataGenerator.metadataForFile(at: logsURL)
            let shareableDebugReport = ShareableDebugReport(logFileMetadata: metadata, shareFile: shareFile)
            router.presentShareViewController(
                destinations: conversations,
                debugReport: shareableDebugReport
            )
        } catch {
            WireLogger.system.error("failed to generate log files \(error)")
        }
    }
}
