import MossgroveKit
import SwiftUI

/// Join the club: every form control and its validation error. Errors appear after the first Join, then follow
/// every edit. Each error is a line of its own under its field, so its id is its own element.
struct FormView: View {
    @Environment(AppModel.self) private var model
    @State private var form = ClubForm()
    @State private var showPassword = false
    @State private var aisleOpen = false
    @State private var dateOpen = false
    @State private var pickedDate = Date()
    @State private var budget = 50.0
    @State private var submitted = false
    @State private var joined: String?
    @FocusState private var focus: Field?
    /// Each change puts the cursor in the password (PasswordField).
    @State private var passwordFocus = 0

    private enum Field { case name, email, age }

    var body: some View {
        let errors = submitted ? FormRules.errors(form) : [:]
        ScrollViewReader { scroller in
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(Texts.formIntro).font(.subheadline).foregroundStyle(Color(Palette.onSurfaceVariant))

                    textField("Full name", text: $form.name, field: .name, id: TestIds.formName, error: errors[.name], errorId: TestIds.formNameError)
                    textField("Email", text: $form.email, field: .email, id: TestIds.formEmail, error: errors[.email],
                              errorId: TestIds.formEmailError, keyboard: .emailAddress)
                    textField("Age", text: Binding(get: { form.age }, set: { form.age = FormRules.ageInput($0) }), field: .age, id: TestIds.formAge,
                              error: errors[.age], errorId: TestIds.formAgeError, keyboard: .numberPad)
                    passwordField(error: errors[.password])
                    aislePicker(error: errors[.category])
                    dateField(error: errors[.date])

                    Toggle(isOn: $form.newsletter) { Text("Email me about new drawers") }
                        .frame(minHeight: 48)
                        .accessibilityIdentifier(TestIds.formNewsletter)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Monthly budget").font(.body)
                            Spacer()
                            Text(FormRules.budgetText(budget)).font(.headline).accessibilityIdentifier(TestIds.formBudgetValue)
                        }
                        Slider(value: $budget, in: FormRules.budgetRange, step: FormRules.budgetStep) { Text("Monthly budget") }
                            .accessibilityIdentifier(TestIds.formBudget)
                            .onChange(of: budget) { form.budget = Int(budget.rounded()) }
                    }

                    checkbox(error: errors[.terms])

                    Button(Texts.join) { join() }
                        .buttonStyle(FilledButtonStyle())
                        .padding(.top, 4)
                        .accessibilityIdentifier(TestIds.formSubmit)

                    if let joined {
                        HStack(alignment: .top, spacing: 12) {
                            Art.icon("check").accessibilityHidden(true)
                            Text(joined).fixedSize(horizontal: false, vertical: true)
                        }
                        .foregroundStyle(Color(Palette.onPrimaryContainer))
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(Palette.primaryContainer), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        // one element with the whole message, so a check on form_result reads its text
                        .accessibilityElement(children: .combine)
                        .accessibilityIdentifier(TestIds.formResult)
                        .id("result")
                    }
                }
                .foregroundStyle(Color(Palette.onSurface))
                .padding(16)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: joined) { if joined != nil { withAnimation { scroller.scrollTo("result") } } }
        }
        .screenBackground()
        .container(TestIds.formScreen)
        .topBar("Join the club", back: true)
        .sheet(isPresented: $dateOpen) { datePicker }
    }

    private func join() {
        submitted = true
        joined = FormRules.welcome(form)
        if joined != nil { model.showSnack(Texts.joined) }
    }

    // MARK: Fields

    private func textField(_ label: String, text: Binding<String>, field: Field, id: String, error: String?, errorId: String,
                           keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            OutlinedField(label: label, isError: error != nil, focus: { focus = field }) {
                TextField(label, text: text)
                    .keyboardType(keyboard)
                    .textInputAutocapitalization(keyboard == .default ? .words : .never)
                    .autocorrectionDisabled()
                    .focused($focus, equals: field)
                    .accessibilityIdentifier(id)
            }
            ErrorLine(error: error, id: errorId)
        }
    }

    private func passwordField(error: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            OutlinedField(label: "Password", isError: error != nil, focus: { passwordFocus += 1 }) {
                HStack {
                    PasswordField(placeholder: "Password", text: $form.password, shown: showPassword, contentType: .newPassword,
                                  id: TestIds.formPassword, focusRequest: passwordFocus)
                    Button { showPassword.toggle() } label: { Art.icon(showPassword ? "eye-off" : "eye").frame(width: 44, height: 44) }
                        .foregroundStyle(Color(Palette.onSurfaceVariant))
                        .accessibilityLabel(showPassword ? Texts.hidePassword : Texts.showPassword)
                        .accessibilityIdentifier(TestIds.formPasswordToggle)
                }
            }
            ErrorLine(error: error, id: TestIds.formPasswordError)
        }
    }

    /// The dropdown: a field that opens its four options right below it. Each option is its own button with its id,
    /// which a system menu's items could not carry.
    private func aislePicker(error: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            OutlinedField(label: "Favourite aisle", isError: error != nil) {
                Button { aisleOpen.toggle() } label: {
                    HStack {
                        Text(form.aisle?.label ?? "Choose an aisle")
                            .foregroundStyle(form.aisle == nil ? Color(Palette.onSurfaceVariant) : Color(Palette.onSurface))
                        Spacer()
                        Image(systemName: aisleOpen ? "chevron.up" : "chevron.down").foregroundStyle(Color(Palette.onSurfaceVariant))
                    }
                    .frame(minHeight: 48)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Favourite aisle")
                .accessibilityValue(form.aisle?.label ?? "")
                .accessibilityIdentifier(TestIds.formCategory)
            }
            if aisleOpen {
                VStack(spacing: 0) {
                    ForEach(Aisle.allCases, id: \.self) { aisle in
                        Button {
                            form.aisle = aisle
                            aisleOpen = false
                        } label: {
                            HStack {
                                Text(aisle.label).foregroundStyle(Color(Palette.onSurface))
                                Spacer()
                                if form.aisle == aisle { Art.icon("check").foregroundStyle(Color(Palette.primary)) }
                            }
                            .padding(.horizontal, 12)
                            .frame(minHeight: 48)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(form.aisle == aisle ? .isSelected : [])
                        .accessibilityIdentifier(TestIds.formCategoryOption(aisle.key))
                    }
                }
                .background(Color(Palette.surfaceContainerHigh), in: RoundedRectangle(cornerRadius: 4))
            }
            ErrorLine(error: error, id: TestIds.formCategoryError)
        }
    }

    private func dateField(error: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            OutlinedField(label: "Delivery date", isError: error != nil) {
                HStack {
                    Text(form.deliveryDate.map { FormRules.formatDate($0) } ?? "")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityLabel("Delivery date")
                        .accessibilityValue(form.deliveryDate.map { FormRules.formatDate($0) } ?? "None")
                    Button {
                        pickedDate = form.deliveryDate ?? Date()
                        dateOpen = true
                    } label: { Art.icon("calendar").frame(width: 44, height: 44) }
                        .foregroundStyle(Color(Palette.onSurfaceVariant))
                        .accessibilityLabel("Choose a delivery date")
                        .accessibilityIdentifier(TestIds.formDate)
                }
            }
            ErrorLine(error: error, id: TestIds.formDateError)
        }
    }

    /// The date picker opens on the current month. OK keeps the day shown as chosen; Cancel keeps none.
    private var datePicker: some View {
        VStack(spacing: 8) {
            HStack {
                Button(Texts.cancel) { dateOpen = false }
                    .frame(minHeight: 44)
                    .accessibilityIdentifier(TestIds.formDateCancel)
                Spacer()
                Text("Delivery date").font(.headline)
                Spacer()
                Button("OK") {
                    form.deliveryDate = pickedDate
                    dateOpen = false
                }
                .fontWeight(.semibold)
                .frame(minHeight: 44)
                .accessibilityIdentifier(TestIds.formDateConfirm)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            DatePicker("Delivery date", selection: $pickedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
                .padding(.horizontal, 16)
                .container(TestIds.formDatePicker)
            Spacer(minLength: 0)
        }
        .presentationDetents([.large])
    }

    private func checkbox(error: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Button { form.acceptedTerms.toggle() } label: {
                HStack(spacing: 12) {
                    Text("I accept the club terms").foregroundStyle(Color(Palette.onSurface))
                    Spacer()
                    RoundedRectangle(cornerRadius: 4)
                        .fill(form.acceptedTerms ? Color(Palette.primary) : .clear)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(form.acceptedTerms ? Color(Palette.primary) : Color(Palette.outline), lineWidth: 2))
                        .overlay { if form.acceptedTerms { Art.icon("check").resizable().padding(2).foregroundStyle(Color(Palette.onPrimary)) } }
                        .frame(width: 22, height: 22)
                }
                .frame(minHeight: 48)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(form.acceptedTerms ? [.isToggle, .isSelected] : .isToggle)
            .accessibilityValue(form.acceptedTerms ? "Checked" : "Not checked")
            .accessibilityIdentifier(TestIds.formTerms)
            ErrorLine(error: error, id: TestIds.formTermsError)
        }
    }
}

/// A field's error, as a line of its own under the field, with a warning mark.
private struct ErrorLine: View {
    let error: String?
    let id: String

    var body: some View {
        if let error {
            HStack(spacing: 6) {
                Art.icon("warning").resizable().frame(width: 16, height: 16).accessibilityHidden(true)
                Text(error).font(.caption).accessibilityIdentifier(id)
            }
            .foregroundStyle(Color(Palette.error))
            .padding(.leading, 4)
        }
    }
}
