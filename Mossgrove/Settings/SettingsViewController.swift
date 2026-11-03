import MossgroveKit
import UIKit

/// Settings, in UIKit: a UITableView of static cells and UIKit controls, and a UIAlertController for its dialog.
/// Every control has an `accessibilityIdentifier`, so Appium sees `settings_slow_loading` and so on. It holds the
/// app's one system permission prompt (notifications).
final class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let model: AppModel
    private let table = UITableView(frame: .zero, style: .insetGrouped)

    private enum Section: Int, CaseIterable { case account, appearance, notifications, testing, data }

    // Account
    private let emailCell = UITableViewCell(style: .default, reuseIdentifier: nil)
    private let ordersCell = UITableViewCell(style: .default, reuseIdentifier: nil)
    private let signOutCell = UITableViewCell(style: .default, reuseIdentifier: nil)
    // Appearance: one cell holding the three radio rows, so the group itself has an id
    private let themeCell = UITableViewCell(style: .default, reuseIdentifier: nil)
    private var themeRows: [(mode: ThemeMode, row: RadioRow)] = []
    // Notifications
    private let notificationsSwitch = UISwitch()
    private let notificationsCell = UITableViewCell(style: .default, reuseIdentifier: nil)
    private let statusCell = UITableViewCell(style: .default, reuseIdentifier: nil)
    private let sendCell = UITableViewCell(style: .default, reuseIdentifier: nil)
    // Testing
    private let testingHelpCell = UITableViewCell(style: .default, reuseIdentifier: nil)
    private let slowSwitch = UISwitch()
    private let slowCell = UITableViewCell(style: .default, reuseIdentifier: nil)
    private let failSwitch = UISwitch()
    private let failCell = UITableViewCell(style: .default, reuseIdentifier: nil)
    // Data
    private let resetCell = UITableViewCell(style: .default, reuseIdentifier: nil)
    private let versionLabel = UILabel()

    private var notificationsAllowed = false

    init(model: AppModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("not from a storyboard") }

    private var rows: [Section: [UITableViewCell]] {
        [
            .account: [emailCell, ordersCell, signOutCell],
            .appearance: [themeCell],
            .notifications: [notificationsCell, statusCell, sendCell],
            .testing: [testingHelpCell, slowCell, failCell],
            .data: [resetCell],
        ]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        table.translatesAutoresizingMaskIntoConstraints = false
        table.dataSource = self
        table.delegate = self
        table.backgroundColor = Palette.surface
        table.accessibilityIdentifier = TestIds.settingsScreen
        view.addSubview(table)
        NSLayoutConstraint.activate([
            table.topAnchor.constraint(equalTo: view.topAnchor),
            table.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            table.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            table.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        emailCell.textLabel?.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .monospacedSystemFont(ofSize: 15, weight: .regular))
        emailCell.textLabel?.adjustsFontForContentSizeCategory = true
        emailCell.selectionStyle = .none
        emailCell.textLabel?.accessibilityIdentifier = TestIds.settingsAccountEmail
        button(ordersCell, Texts.orderHistory, id: TestIds.settingsOrders)
        ordersCell.accessoryType = .disclosureIndicator
        button(signOutCell, Texts.signOut, id: TestIds.settingsSignOut)

        buildTheme()

        switchRow(notificationsCell, Texts.orderUpdates, notificationsSwitch, id: TestIds.settingsNotifications, action: #selector(notificationsChanged))
        statusCell.textLabel?.numberOfLines = 0
        statusCell.textLabel?.font = .preferredFont(forTextStyle: .subheadline)
        statusCell.textLabel?.textColor = Palette.onSurfaceVariant
        statusCell.textLabel?.accessibilityIdentifier = TestIds.settingsNotificationsStatus
        statusCell.selectionStyle = .none
        button(sendCell, Texts.sendTestNotification, id: TestIds.settingsSendNotification)

        testingHelpCell.textLabel?.text = Texts.testingHelp
        testingHelpCell.textLabel?.numberOfLines = 0
        testingHelpCell.textLabel?.font = .preferredFont(forTextStyle: .subheadline)
        testingHelpCell.textLabel?.textColor = Palette.onSurfaceVariant
        testingHelpCell.selectionStyle = .none
        switchRow(slowCell, Texts.slowLoading, slowSwitch, id: TestIds.settingsSlowLoading, action: #selector(slowChanged))
        switchRow(failCell, Texts.failFirstLoad, failSwitch, id: TestIds.settingsFailLoading, action: #selector(failChanged))

        button(resetCell, Texts.resetData, id: TestIds.settingsReset)
        resetCell.textLabel?.textColor = Palette.error

        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        versionLabel.text = Texts.version(version)
        versionLabel.font = .preferredFont(forTextStyle: .footnote)
        versionLabel.adjustsFontForContentSizeCategory = true
        versionLabel.textColor = Palette.onSurfaceVariant
        versionLabel.textAlignment = .center
        versionLabel.numberOfLines = 0
        versionLabel.accessibilityIdentifier = TestIds.settingsVersion
        let footer = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 72))
        versionLabel.translatesAutoresizingMaskIntoConstraints = false
        footer.addSubview(versionLabel)
        NSLayoutConstraint.activate([
            versionLabel.leadingAnchor.constraint(equalTo: footer.leadingAnchor, constant: 16),
            versionLabel.trailingAnchor.constraint(equalTo: footer.trailingAnchor, constant: -16),
            versionLabel.centerYAnchor.constraint(equalTo: footer.centerYAnchor),
        ])
        table.tableFooterView = footer

        NotificationCenter.default.addObserver(self, selector: #selector(refreshPermission), name: UIApplication.didBecomeActiveNotification, object: nil)
        render()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshPermission()
    }

    // MARK: Building

    private func button(_ cell: UITableViewCell, _ title: String, id: String) {
        cell.textLabel?.text = title
        cell.textLabel?.textColor = Palette.primary
        cell.textLabel?.font = .preferredFont(forTextStyle: .body)
        cell.accessibilityTraits = .button
        cell.accessibilityIdentifier = id
    }

    private func switchRow(_ cell: UITableViewCell, _ title: String, _ toggle: UISwitch, id: String, action: Selector) {
        cell.textLabel?.text = title
        cell.textLabel?.numberOfLines = 0
        cell.selectionStyle = .none
        toggle.onTintColor = Palette.primary
        toggle.accessibilityLabel = title
        toggle.accessibilityIdentifier = id
        toggle.addTarget(self, action: action, for: .valueChanged)
        cell.accessoryView = toggle
    }

    private func buildTheme() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.translatesAutoresizingMaskIntoConstraints = false
        for (mode, title, id) in [(ThemeMode.system, Texts.themeSystem, TestIds.settingsThemeSystem),
                                  (.light, Texts.themeLight, TestIds.settingsThemeLight),
                                  (.dark, Texts.themeDark, TestIds.settingsThemeDark)] {
            let row = RadioRow(title: title)
            row.accessibilityIdentifier = id
            row.addAction(UIAction { [weak self] _ in self?.model.themeMode = mode; self?.render() }, for: .touchUpInside)
            stack.addArrangedSubview(row)
            themeRows.append((mode, row))
        }
        themeCell.selectionStyle = .none
        themeCell.contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: themeCell.contentView.topAnchor),
            stack.bottomAnchor.constraint(equalTo: themeCell.contentView.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: themeCell.contentView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: themeCell.contentView.trailingAnchor),
        ])
        // the radio group: a container that keeps its three options as elements of their own
        themeCell.isAccessibilityElement = false
        themeCell.accessibilityLabel = Texts.theme
        themeCell.accessibilityElements = themeRows.map(\.row)
        themeCell.accessibilityIdentifier = TestIds.settingsTheme
    }

    // MARK: State

    /// Puts the model on the controls.
    func render() {
        guard isViewLoaded else { return }
        emailCell.textLabel?.text = model.signedInEmail ?? Texts.notSignedIn
        for (mode, row) in themeRows { row.isSelected = model.themeMode == mode }
        slowSwitch.isOn = model.slowLoading
        failSwitch.isOn = model.failFirstLoad
        if !notificationsAllowed { model.orderUpdates = false }
        notificationsSwitch.isOn = model.orderUpdates
        statusCell.textLabel?.text = Texts.notificationStatus(allowed: notificationsAllowed, on: model.orderUpdates)
        let canSend = notificationsAllowed && model.orderUpdates
        sendCell.isUserInteractionEnabled = canSend
        sendCell.textLabel?.textColor = canSend ? Palette.primary : Palette.onSurfaceVariant.withAlphaComponent(0.5)
        sendCell.accessibilityTraits = canSend ? .button : [.button, .notEnabled]
        table.beginUpdates()
        table.endUpdates()
    }

    @objc private func refreshPermission() {
        Task {
            notificationsAllowed = await model.notifications.allowed()
            render()
        }
    }

    @objc private func notificationsChanged() {
        let wantsOn = notificationsSwitch.isOn
        guard wantsOn, !notificationsAllowed else {
            model.orderUpdates = wantsOn
            render()
            return
        }
        // Not allowed yet: the system asks (the app's one permission prompt), and the switch follows the answer.
        notificationsSwitch.setOn(false, animated: false)
        Task {
            let granted = await model.notifications.request()
            notificationsAllowed = await model.notifications.allowed()
            model.orderUpdates = granted && notificationsAllowed
            render()
        }
    }

    @objc private func slowChanged() { model.slowLoading = slowSwitch.isOn }

    @objc private func failChanged() { model.failFirstLoad = failSwitch.isOn }

    // MARK: Table

    func numberOfSections(in tableView: UITableView) -> Int { Section.allCases.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { rows[Section(rawValue: section)!]!.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        rows[Section(rawValue: indexPath.section)!]![indexPath.row]
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .account: Texts.account
        case .appearance: Texts.appearance
        case .notifications: Texts.notifications
        case .testing: Texts.testing
        case .data: Texts.data
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch tableView.cellForRow(at: indexPath) {
        case ordersCell: model.navigation.push(.orders)
        case signOutCell: model.signOut()
        case sendCell:
            model.notifications.post(title: Texts.testNotificationTitle, body: Texts.testNotificationBody)
            model.showSnack(Texts.notificationSent)
        case resetCell: confirmReset()
        default: break
        }
    }

    /// The UIKit screen's own dialog. A UIAlertAction has no identifier of its own, so once the alert is on screen
    /// its two buttons are named `settings_reset_cancel` and `settings_reset_confirm` (AlertIds).
    private func confirmReset() {
        let alert = UIAlertController(title: Texts.resetTitle, message: Texts.resetBody, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Texts.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: Texts.resetConfirm, style: .destructive) { [weak self] _ in
            self?.model.resetData()
            self?.model.showSnack(Texts.resetDone)
        })
        let ids = [Texts.cancel: TestIds.settingsResetCancel, Texts.resetConfirm: TestIds.settingsResetConfirm]
        present(alert, animated: true) { AlertIds.name(alert, ids) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { AlertIds.name(alert, ids) }
    }
}

/// One radio option: a 48-point row with a title and, when chosen, a check. Selected is a mark as well as a word
/// ("Selected"), never a colour alone.
private final class RadioRow: UIControl {
    private let label = UILabel()
    private let check = UIImageView(image: Art.uiIcon("check"))

    init(title: String) {
        super.init(frame: .zero)
        label.text = title
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        check.tintColor = Palette.primary
        for view in [label, check] as [UIView] {
            view.translatesAutoresizingMaskIntoConstraints = false
            view.isUserInteractionEnabled = false
            addSubview(view)
        }
        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: 48),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 12),
            check.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            check.centerYAnchor.constraint(equalTo: centerYAnchor),
            check.leadingAnchor.constraint(greaterThanOrEqualTo: label.trailingAnchor, constant: 8),
        ])
        isAccessibilityElement = true
        accessibilityLabel = title
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("not from a storyboard") }

    override var isSelected: Bool {
        didSet { check.isHidden = !isSelected }
    }

    override var accessibilityTraits: UIAccessibilityTraits {
        get { isSelected ? [.button, .selected] : .button }
        set {}
    }
}

/// Names a UIAlertController's buttons. UIKit draws each action as a view whose accessibility label is the action's
/// title; that view gets the identifier.
enum AlertIds {
    static func name(_ alert: UIAlertController, _ ids: [String: String]) {
        guard alert.viewIfLoaded?.window != nil else { return }
        for (title, id) in ids { tag(alert.view, title: title, id: id) }
    }

    private static func tag(_ root: UIView, title: String, id: String) {
        var tagged = false
        func walk(_ view: UIView) {
            if view.isAccessibilityElement, view.accessibilityLabel == title, !(view is UILabel) {
                view.accessibilityIdentifier = id
                tagged = true
            }
            view.subviews.forEach(walk)
        }
        walk(root)
        if tagged { return }
        // otherwise: the label with the title, and the nearest element above it
        func label(in view: UIView) -> UILabel? {
            if let label = view as? UILabel, label.text == title { return label }
            for sub in view.subviews { if let found = label(in: sub) { return found } }
            return nil
        }
        guard let found = label(in: root) else { return }
        var element: UIView? = found.superview
        while let candidate = element, !candidate.isAccessibilityElement { element = candidate.superview }
        (element ?? found).accessibilityIdentifier = id
    }
}
