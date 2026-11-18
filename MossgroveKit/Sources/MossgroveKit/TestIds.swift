// The native test ids of SPEC.md §7, one constant per id in `nthcase/test-ids.json`. The `web_*` ids are not here:
// they are HTML ids in the bundled page. SourceCensusTests checks this file against the JSON, and checks that each
// constant is used on its own screen's source file and nowhere else.
public enum TestIds {
    // chrome
    public static let navShop = "nav_shop"
    public static let navCart = "nav_cart"
    public static let navLab = "nav_lab"
    public static let navSettings = "nav_settings"
    public static let topBarTitle = "top_bar_title"
    public static let topBarBack = "top_bar_back"
    public static let snackbar = "snackbar"
    public static let snackbarText = "snackbar_text"
    public static let snackbarAction = "snackbar_action"
    public static let dialog = "dialog"
    public static let dialogTitle = "dialog_title"
    public static let dialogText = "dialog_text"
    public static let dialogConfirm = "dialog_confirm"
    public static let dialogDismiss = "dialog_dismiss"

    // signin
    public static let signinScreen = "signin_screen"
    public static let signinEmail = "signin_email"
    public static let signinPassword = "signin_password"
    public static let signinPasswordToggle = "signin_password_toggle"
    public static let signinSubmit = "signin_submit"
    public static let signinError = "signin_error"
    public static let signinTestAccount = "signin_test_account"
    public static let signinUseTestAccount = "signin_use_test_account"

    // shop
    public static let shopScreen = "shop_screen"
    public static let shopSearch = "shop_search"
    public static let shopSearchClear = "shop_search_clear"
    public static let shopCount = "shop_count"
    public static let shopList = "shop_list"
    public static func shopItem(_ id: Int) -> String { "shop_item_\(id)" }
    public static let shopLoading = "shop_loading"
    public static let shopError = "shop_error"
    public static let shopRetry = "shop_retry"
    public static let shopEmpty = "shop_empty"
    public static let shopEmptyAction = "shop_empty_action"

    // item
    public static let itemScreen = "item_screen"
    public static let itemImage = "item_image"
    public static let itemNumber = "item_number"
    public static let itemName = "item_name"
    public static let itemPrice = "item_price"
    public static let itemDescription = "item_description"
    public static let itemQtyDecrease = "item_qty_decrease"
    public static let itemQtyValue = "item_qty_value"
    public static let itemQtyIncrease = "item_qty_increase"
    public static let itemAddToCart = "item_add_to_cart"
    public static let itemNotFound = "item_not_found"
    public static let itemNotFoundAction = "item_not_found_action"

    // cart
    public static let cartScreen = "cart_screen"
    public static let cartList = "cart_list"
    public static func cartLine(_ id: Int) -> String { "cart_line_\(id)" }
    public static func cartLineDecrease(_ id: Int) -> String { "cart_line_decrease_\(id)" }
    public static func cartLineQty(_ id: Int) -> String { "cart_line_qty_\(id)" }
    public static func cartLineIncrease(_ id: Int) -> String { "cart_line_increase_\(id)" }
    public static func cartLineRemove(_ id: Int) -> String { "cart_line_remove_\(id)" }
    public static func cartLineTotal(_ id: Int) -> String { "cart_line_total_\(id)" }
    public static let cartTotal = "cart_total"
    public static let cartCheckout = "cart_checkout"
    public static let cartEmpty = "cart_empty"
    public static let cartEmptyAction = "cart_empty_action"

    // lab
    public static let labScreen = "lab_screen"
    public static let labForm = "lab_form"
    public static let labGestures = "lab_gestures"
    public static let labWebview = "lab_webview"
    public static let labSlow = "lab_slow"
    public static let labOrders = "lab_orders"
    public static let labGiftCards = "lab_gift_cards"
    public static let labLobby = "lab_lobby"
    public static let labLobbyViews = "lab_lobby_views"

    // lobby (1.1): both builds, SwiftUI and UIKit, carry every one
    public static let lobbyScreen = "lobby_screen"
    public static let lobbyTouchLog = "lobby_touch_log"
    public static let lobbyTouchCount = "lobby_touch_count"
    public static let lobbyTouchReset = "lobby_touch_reset"
    public static let lobbySavedDelay = "lobby_saved_delay"
    public static func lobbySavedDelayChoice(_ s: Int) -> String { "lobby_saved_delay_\(s)" }
    public static let lobbyPagerShown = "lobby_pager_shown"
    public static let lobbyPager = "lobby_pager"
    public static func lobbyBanner(_ n: Int) -> String { "lobby_banner_\(n)" }
    public static let lobbyPagerPosition = "lobby_pager_position"
    public static let lobbyPagerAuto = "lobby_pager_auto"
    public static let lobbyTopRowPosition = "lobby_top_row_position"
    public static let lobbyTopRow = "lobby_top_row"
    public static func lobbyTopRowTile(_ m: Int) -> String { "lobby_top_row_tile_\(m)" }
    public static let lobbyPage = "lobby_page"
    public static let lobbyChips = "lobby_chips"
    public static func lobbyChip(_ n: Int) -> String { "lobby_chip_\(n)" }
    public static func lobbyRow(_ n: Int) -> String { "lobby_row_\(n)" }
    public static func lobbyRowPosition(_ n: Int) -> String { "lobby_row_\(n)_position" }
    public static func lobbyRowTile(_ n: Int, _ m: Int) -> String { "lobby_row_\(n)_tile_\(m)" }
    public static let lobbyGrid = "lobby_grid"
    public static func lobbyGridCell(_ n: Int) -> String { "lobby_grid_cell_\(n)" }
    public static let lobbyInnerList = "lobby_inner_list"
    public static func lobbyInnerRow(_ n: Int) -> String { "lobby_inner_row_\(n)" }
    public static let lobbyBoard = "lobby_board"
    public static let lobbyBoardPosition = "lobby_board_position"
    public static func lobbyBoardCell(_ col: String, _ row: Int) -> String { "lobby_board_cell_\(col)\(row)" }
    public static let lobbyFooter = "lobby_footer"
    public static let lobbyBar = "lobby_bar"
    public static let lobbyBarHome = "lobby_bar_home"
    public static let lobbyBarLive = "lobby_bar_live"
    public static let lobbyBarSaved = "lobby_bar_saved"
    public static let lobbyBarOffers = "lobby_bar_offers"
    public static let lobbySavedScreen = "lobby_saved_screen"
    public static let lobbyDetail = "lobby_detail"
    public static let lobbyDetailBack = "lobby_detail_back"
    public static let lobbyPromo = "lobby_promo"
    public static let lobbyPromoBack = "lobby_promo_back"
    public static let lobbySheet = "lobby_sheet"
    public static let lobbySheetTitle = "lobby_sheet_title"
    public static let lobbySheetOpen = "lobby_sheet_open"
    public static let lobbySheetPreview = "lobby_sheet_preview"
    public static let lobbySheetSaved = "lobby_sheet_saved"
    public static let lobbySheetRate = "lobby_sheet_rate"

    // form
    public static let formScreen = "form_screen"
    public static let formName = "form_name"
    public static let formNameError = "form_name_error"
    public static let formEmail = "form_email"
    public static let formEmailError = "form_email_error"
    public static let formAge = "form_age"
    public static let formAgeError = "form_age_error"
    public static let formPassword = "form_password"
    public static let formPasswordToggle = "form_password_toggle"
    public static let formPasswordError = "form_password_error"
    public static let formCategory = "form_category"
    public static let formCategoryError = "form_category_error"
    public static func formCategoryOption(_ key: String) -> String { "form_category_option_\(key)" }
    public static let formDate = "form_date"
    public static let formDateError = "form_date_error"
    public static let formDatePicker = "form_date_picker"
    public static let formDateConfirm = "form_date_confirm"
    public static let formDateCancel = "form_date_cancel"
    public static let formNewsletter = "form_newsletter"
    public static let formBudget = "form_budget"
    public static let formBudgetValue = "form_budget_value"
    public static let formTerms = "form_terms"
    public static let formTermsError = "form_terms_error"
    public static let formSubmit = "form_submit"
    public static let formResult = "form_result"

    // gestures
    public static let gesturesScreen = "gestures_screen"
    public static let gesturesStatus = "gestures_status"
    public static let gesturesOrientation = "gestures_orientation"
    public static let gesturesTap = "gestures_tap"
    public static let gesturesTapCount = "gestures_tap_count"
    public static let gesturesDoubleTap = "gestures_double_tap"
    public static let gesturesLongPress = "gestures_long_press"
    public static let gesturesSwipe = "gestures_swipe"
    public static let gesturesDragSource = "gestures_drag_source"
    public static let gesturesDropTarget = "gestures_drop_target"
    public static let gesturesPinch = "gestures_pinch"
    public static let gesturesZoomValue = "gestures_zoom_value"
    public static let gesturesRotate = "gestures_rotate"
    public static let gesturesRotationValue = "gestures_rotation_value"
    public static let gesturesScroll = "gestures_scroll"
    public static let gesturesScrollTarget = "gestures_scroll_target"

    // webview
    public static let webviewScreen = "webview_screen"
    public static let webview = "webview"
    public static let webviewStatus = "webview_status"

    // slow
    public static let slowScreen = "slow_screen"
    public static let slowLoading = "slow_loading"
    public static let slowContent = "slow_content"
    public static func slowSlot(_ n: Int) -> String { "slow_slot_\(n)" }
    public static let slowReload = "slow_reload"

    // orders
    public static let ordersScreen = "orders_screen"
    public static let ordersLoading = "orders_loading"
    public static let ordersEmpty = "orders_empty"
    public static let ordersEmptyAction = "orders_empty_action"
    public static let ordersError = "orders_error"
    public static let ordersRetry = "orders_retry"
    public static let ordersList = "orders_list"
    public static func ordersRow(_ n: Int) -> String { "orders_row_\(n)" }

    // settings
    public static let settingsScreen = "settings_screen"
    public static let settingsAccountEmail = "settings_account_email"
    public static let settingsOrders = "settings_orders"
    public static let settingsSignOut = "settings_sign_out"
    public static let settingsTheme = "settings_theme"
    public static let settingsThemeSystem = "settings_theme_system"
    public static let settingsThemeLight = "settings_theme_light"
    public static let settingsThemeDark = "settings_theme_dark"
    public static let settingsNotifications = "settings_notifications"
    public static let settingsNotificationsStatus = "settings_notifications_status"
    public static let settingsSendNotification = "settings_send_notification"
    public static let settingsSlowLoading = "settings_slow_loading"
    public static let settingsFailLoading = "settings_fail_loading"
    public static let settingsReset = "settings_reset"
    public static let settingsResetConfirm = "settings_reset_confirm"
    public static let settingsResetCancel = "settings_reset_cancel"
    public static let settingsVersion = "settings_version"
}
