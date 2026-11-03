import MossgroveKit
import SwiftUI

/// The app's modal: the checkout confirmation. A SwiftUI alert's buttons cannot carry ids, so this is the app's own
/// dialog, drawn above the tabs, with `dialog`, `dialog_title`, `dialog_text`, `dialog_confirm` and `dialog_dismiss`.
struct DialogView: View {
    let request: DialogRequest
    @Environment(AppModel.self) private var model

    var body: some View {
        ZStack {
            Color.black.opacity(0.32)
                .ignoresSafeArea()
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 16) {
                Text(request.title)
                    .font(.title3)
                    .foregroundStyle(Color(Palette.onSurface))
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier(TestIds.dialogTitle)
                Text(request.text)
                    .font(.body)
                    .foregroundStyle(Color(Palette.onSurfaceVariant))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier(TestIds.dialogText)
                HStack(spacing: 8) {
                    Spacer()
                    Button(Texts.cancel) { model.closeDialog() }
                        .frame(minWidth: 64, minHeight: 44)
                        .accessibilityIdentifier(TestIds.dialogDismiss)
                    Button(request.confirmLabel) {
                        model.closeDialog()
                        request.onConfirm()
                    }
                    .fontWeight(.semibold)
                    .frame(minWidth: 64, minHeight: 44)
                    .accessibilityIdentifier(TestIds.dialogConfirm)
                }
            }
            .padding(24)
            .frame(maxWidth: 360)
            .background(Color(Palette.surfaceContainerHigh), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .padding(32)
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(.isModal)
            .accessibilityIdentifier(TestIds.dialog)
        }
    }
}
