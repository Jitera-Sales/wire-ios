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

import SwiftUI

struct DeviceDetailsE2EIdentityCertificateView: View {
    @ObservedObject var viewModel: DeviceInfoViewModel
    @Binding var isCertificateViewPreseneted: Bool
    var body: some View {
        Text(
            L10n.Localizable.Device.Details.Section.E2e.title
        ).font(
            UIFont.normalSemiboldFont.swiftUIFont
        ).multilineTextAlignment(
            .leading
        )
        .padding(
            [
                .top,
                .bottom
            ],
            16
        )
        HStack {
            switch viewModel.certificateStatus {
            case .notActivated:
                viewForStatus(
                    titleText: L10n.Localizable.Device.Details.Section.E2e.Status.title,
                    statusText: viewModel.certificateStatus.titleForStatus(),
                    textColor: SemanticColors.DrawingColors.red.swiftUIColor,
                    image: Image(.certificateExpired)
                )
            case .revoked:
                viewForStatus(
                    titleText: L10n.Localizable.Device.Details.Section.E2e.Status.title,
                    statusText: viewModel.certificateStatus.titleForStatus(),
                    textColor: SemanticColors.DrawingColors.red.swiftUIColor,
                    image: Image(.certificateRevoked)
                )
            case .expired:
                viewForStatus(
                    titleText: L10n.Localizable.Device.Details.Section.E2e.Status.title,
                    statusText: viewModel.certificateStatus.titleForStatus(),
                    textColor: SemanticColors.DrawingColors.red.swiftUIColor,
                    image: Image(.certificateExpired)
                )
            case .valid:
                viewForStatus(
                    titleText: L10n.Localizable.Device.Details.Section.E2e.Status.title,
                    statusText: viewModel.certificateStatus.titleForStatus(),
                    textColor: SemanticColors.DrawingColors.green.swiftUIColor,
                    image: Image(.certificateValid)
                )
            case .none:
                Spacer()
            }
            Spacer()
        }
        if let certificate = viewModel.e2eIdentityCertificate {
            Text(
                L10n.Localizable.Device.Details.Section.E2e.serialnumber
            )
            .font(
                UIFont.smallSemiboldFont.swiftUIFont
            )
            .foregroundColor(
                .gray
            ).padding(
                .top,
                8
            )
            Text(
                certificate.serialNumber
            )
        }
    }

    @ViewBuilder
    func viewForStatus(titleText: String, statusText: String, textColor: Color, image: Image) -> some View {
        Text(
            L10n.Localizable.Device.Details.Section.E2e.Status.title
        ).font(
            UIFont.mediumSemiboldFont.swiftUIFont
        ).foregroundColor(
            .gray
        ).multilineTextAlignment(
            .leading
        )
        Text(
            viewModel.certificateStatus.titleForStatus()
        ).foregroundColor(
            SemanticColors.DrawingColors.green.swiftUIColor
        ).font(
            .subheadline
        ).font(
            UIFont.normalMediumFont.swiftUIFont
        )
        Image(
            .certificateValid
        )
    }
}
