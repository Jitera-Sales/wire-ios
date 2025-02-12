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

@testable import Wire
import XCTest

final class UIAlertControllerFeatureConfigSnapshotTests: XCTestCase {

    private func createSut(for featureChange: FeatureRepository.FeatureChange) -> UIAlertController? {
        let result = UIAlertController.fromFeatureChange(featureChange,
                                                         acknowledger: MockFeatureChangeAcknowledger())
        result?.view.backgroundColor = .white
        return result
    }

    // MARK: - Tests

    func testSelfDeletingMessagesIsDisabled() throws {
        try verify(matching: createSut(for: .selfDeletingMessagesIsDisabled)!)
    }

    func testSelfDeletingMessagsIsEnabled() throws {
        try verify(matching: createSut(for: .selfDeletingMessagesIsEnabled(enforcedTimeout: nil))!)
    }

    func testSelfDeletingMessagesIsForcedOn() throws {
        try verify(matching: createSut(for: .selfDeletingMessagesIsEnabled(enforcedTimeout: 300))!)
    }

    func testFileSharingEnabled() throws {
        try verify(matching: createSut(for: .fileSharingEnabled)!)
    }

    func testFileSharingDisabled() throws {
        try verify(matching: createSut(for: .fileSharingDisabled)!)
    }

}

private final class MockFeatureChangeAcknowledger: FeatureChangeAcknowledger {

    func acknowledgeChange(for featureName: Feature.Name) {
        // no op
    }

}
