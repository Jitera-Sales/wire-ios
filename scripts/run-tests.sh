#!/bin/bash
set -Eeuo pipefail

#
# Wire
# Copyright (C) 2024 Wire Swiss GmbH
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see http://www.gnu.org/licenses/.
#

REPO_ROOT=$(git rev-parse --show-toplevel)
XCODEBUILD="xcrun xcodebuild"

SCHEMES=(WireSystem WireTesting WireUtilities WireCryptobox WireTransport WireLinkPreview WireImages WireProtos WireMockTransport WireDataModel WireRequestStrategy WireShareEngine WireSyncEngine Wire-iOS WireNotificationEngine)
for SCHEME in ${SCHEMES[@]}; do
(
    cd "$REPO_ROOT"
    echo "Building $SCHEME ..."
    xcodebuild build-for-testing -workspace wire-ios-mono.xcworkspace -scheme $SCHEME -destination 'platform=iOS Simulator,OS=17.5,name=iPhone 14'
    echo "Testing $SCHEME ..."
    if [[ $SCHEME != 'Wire-iOS' ]]; then
        xcodebuild test -retry-tests-on-failure -workspace wire-ios-mono.xcworkspace -scheme $SCHEME -destination 'platform=iOS Simulator,OS=17.5,name=iPhone 14'
    else
        xcodebuild test -workspace wire-ios-mono.xcworkspace -scheme $SCHEME -testPlan AllTests -destination 'platform=iOS Simulator,OS=17.5,name=iPhone 14'
        xcodebuild test -workspace wire-ios-mono.xcworkspace -scheme $SCHEME -testPlan GermanLocaleTests -destination 'platform=iOS Simulator,OS=17.5,name=iPhone 14'
    fi
)
done
