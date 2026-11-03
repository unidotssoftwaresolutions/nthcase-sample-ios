import MossgroveKit
import SwiftUI

/// Sign in: fixed credentials, a show/hide password button, two error texts, and the printed test account.
struct SignInView: View {
    @Environment(AppModel.self) private var model
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var error: String?
    @FocusState private var focus: Field?

    private enum Field { case email, password }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Art.icon("shop")
                    .resizable()
                    .frame(width: 48, height: 48)
                    .foregroundStyle(Color(Palette.primary))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(Texts.appName).font(.largeTitle).accessibilityAddTraits(.isHeader)
                    Text(Texts.tagline).font(.body).foregroundStyle(Color(Palette.onSurfaceVariant))
                }
                .padding(.bottom, 8)

                OutlinedField(label: "Email", isError: error != nil) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                        .focused($focus, equals: .email)
                        .onSubmit { focus = .password }
                        .accessibilityIdentifier(TestIds.signinEmail)
                }
                OutlinedField(label: "Password", isError: error != nil) {
                    HStack {
                        Group {
                            if showPassword {
                                TextField("Password", text: $password)
                            } else {
                                SecureField("Password", text: $password)
                            }
                        }
                        .textContentType(.password)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.go)
                        .focused($focus, equals: .password)
                        .onSubmit(submit)
                        .accessibilityIdentifier(TestIds.signinPassword)
                        Button { showPassword.toggle() } label: {
                            Art.icon(showPassword ? "eye-off" : "eye").frame(width: 44, height: 44)
                        }
                        .foregroundStyle(Color(Palette.onSurfaceVariant))
                        .accessibilityLabel(showPassword ? Texts.hidePassword : Texts.showPassword)
                        .accessibilityIdentifier(TestIds.signinPasswordToggle)
                    }
                }
                .onChange(of: email) { error = nil }
                .onChange(of: password) { error = nil }

                if let error {
                    HStack(spacing: 8) {
                        Art.icon("warning").resizable().frame(width: 18, height: 18).accessibilityHidden(true)
                        Text(error).font(.subheadline).accessibilityIdentifier(TestIds.signinError)
                    }
                    .foregroundStyle(Color(Palette.error))
                }

                Button(Texts.signIn, action: submit)
                    .buttonStyle(FilledButtonStyle())
                    .accessibilityIdentifier(TestIds.signinSubmit)

                VStack(alignment: .leading, spacing: 4) {
                    Text(Texts.testAccount).font(.subheadline.weight(.semibold))
                    Text(Texts.testAccountHelp).font(.subheadline).foregroundStyle(Color(Palette.onSurfaceVariant))
                    Text(Account.email).font(Typeface.itemNumber)
                    Text(Account.password).font(Typeface.itemNumber)
                    Button(Texts.useTestAccount) {
                        email = Account.email
                        password = Account.password
                        error = nil
                    }
                    .fontWeight(.semibold)
                    .frame(minHeight: 44)
                    .accessibilityIdentifier(TestIds.signinUseTestAccount)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(Palette.outlineVariant), lineWidth: 1))
                .container(TestIds.signinTestAccount)
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .screenBackground()
        .container(TestIds.signinScreen)
    }

    private func submit() {
        error = Account.signInError(email: email, password: password)
        if error == nil {
            focus = nil
            model.signIn(email: email)
        }
    }
}

/// An outlined text field: a label above a 4-point frame that thickens in primary when focused and turns error-red
/// with an error. The label is a caption, so the field's own label stays the placeholder.
struct OutlinedField<Content: View>: View {
    let label: String
    var isError = false
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(isError ? Color(Palette.error) : Color(Palette.onSurfaceVariant))
                .accessibilityHidden(true)
            content
                .padding(.horizontal, 12)
                .frame(minHeight: 48)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(isError ? Color(Palette.error) : Color(Palette.outline), lineWidth: 1))
        }
    }
}
