import MossgroveKit
import SwiftUI

/// iOS has no snackbar, so the app shows the same message in a bottom banner, with the same ids and the same 10 s
/// (SPEC.md §5). The banner is one container, `snackbar`; its message and its action keep their own ids.
///
/// It sits above a panel the screen pins to its bottom (`AppModel.snackbarLift`), never over it: on the Cart the
/// banner from Add to cart lay over Check out for its 10 s, and a tap on Check out landed on the banner (third CI run,
/// flow 03: the dialog's title never came). A person meets that, and so does NthCase, whose tap lands where the
/// button is.
struct SnackbarHost: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        if let snack = model.snack {
            HStack(spacing: 12) {
                Text(snack.message)
                    .font(.subheadline)
                    .foregroundStyle(Color(Palette.inverseOnSurface))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier(TestIds.snackbarText)
                if let label = snack.actionLabel {
                    Button(label) { model.performSnackAction() }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color(Palette.inversePrimary))
                        .frame(minHeight: 44)
                        .accessibilityIdentifier(TestIds.snackbarAction)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .frame(minHeight: 48)
            .background(Color(Palette.inverseSurface), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 16)
            .padding(.bottom, 8 + model.snackbarLift)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(TestIds.snackbar)
            .id(snack.id)
        }
    }
}
