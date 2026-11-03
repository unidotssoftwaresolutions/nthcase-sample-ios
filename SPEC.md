# Mossgrove: the NthCase sample apps (spec 1.0)

**Spec version 1.0 · 2026-11-03.** This one document defines all five NthCase sample apps. Each repository carries
a copy of it, and the version line says which spec that repository builds.

| Repository | Framework | Status |
| --- | --- | --- |
| `nthcase-sample-android` | Kotlin + Jetpack Compose, settings in classic XML Views | built against spec 1.0 |
| `nthcase-sample-ios` | SwiftUI, settings in UIKit | to build |
| `nthcase-sample-flutter` | Flutter (Android + iOS) | to build |
| `nthcase-sample-react-native` | React Native with Expo (Android + iOS) | to build |
| `nthcase-sample-ionic` | Ionic React + Capacitor (Android + iOS), a WebView app | to build |

The apps have two jobs. They are a **showcase**: a developer evaluating NthCase clones one, builds it, and tests it in
minutes. And they are NthCase's **regression lab**: every verb NthCase records and replays, and the hard cases real
apps have, exist in every app, and the nightly schedule runs the same scenarios against all five.

The words **must**, **must not** and **should** are used as in RFC 2119. Anything this spec fixes (a text, an id, a
number, an order) is the same in all five apps. Anything it leaves open is each platform's native choice.

## Contents

1. [The app](#1-the-app)
2. [Rules every app keeps](#2-rules-every-app-keeps)
3. [Data](#3-data)
4. [Navigation](#4-navigation)
5. [Screens](#5-screens)
6. [Texts the scenarios check](#6-texts-the-scenarios-check)
7. [Test ids](#7-test-ids)
8. [Verb coverage](#8-verb-coverage)
9. [Scenarios](#9-scenarios)
10. [Design](#10-design)
11. [Repository layout and CI](#11-repository-layout-and-ci)
12. [Per framework](#12-per-framework)
13. [Known gaps](#13-known-gaps)

## 1. The app

**Mossgrove** is a small fictional shop for home and desk goods. The name is invented: it is not a real company,
person, brand or product, and no app may give it a real company's logo or colours. Its idea is a **parts cabinet**:
every product is a labelled drawer with an item number ("No. 007"), and every control carries a label. It feels like
a real shop, except on the **Lab** screens, which say plainly that they are test benches.

| | |
| --- | --- |
| Display name | **Mossgrove** |
| Android `applicationId` / iOS bundle id | **`com.nthcase.sample`**, in every framework |
| Deep link | **`nthcase-sample://item/{id}`** |
| Test account | **`tester@mossgrove.test`** / **`Mossgrove123`** (also printed on the sign-in screen) |
| Gift-card code | **`MOSS-0025`** (balance $25.00) |
| Licence | Apache-2.0 |

Copy is short, plain and a little dry, in US English: "Your cart is empty", "Orders didn't load". It never jokes about
errors and never blames the user.

## 2. Rules every app keeps

- **No network.** The app asks for no internet permission where the platform has one, makes no request, and loads
  nothing remote: no fonts, images, analytics or crash reporting. The web view's page is bundled, and network loads are
  blocked inside it.
- **No analytics, ads, tracking, accounts or third-party SDKs** beyond the framework's own packages (Jetpack and
  Material Components on Android, Apple frameworks on iOS, Flutter's SDK, Expo's SDK, Ionic and Capacitor).
- **Deterministic.** Every cold start is signed out, with an empty cart, no orders, and Settings at their defaults.
  State lives in memory only. The same input gives the same screen on every run, in every app. Nothing depends on the
  date, except the calendar month the date picker opens on.
- **Original assets only.** All art is the drawings in [`art/`](art) (SVG, drawn for these apps). No stock
  photography, no icon font, no bundled typeface.
- **Accessibility.** Every control has a label. Text follows the system font size (dynamic type on iOS, sp and font
  scale on Android). Touch targets are at least 48 dp / 44 pt. Light and dark themes both work. State is never colour alone: errors are written in words, and selections have a
  mark.
- **Portrait and landscape** both work. The phone is the target; a tablet must not break.

## 3. Data

Forty items, numbered 1–40, in this order. Prices are fixed US dollars, written `$14.00`. The item number is written
`No. 007`, three digits. Aisle keys are what the form's picker stores.

| No. | Name | Aisle (key) | Drawing | Price | Description |
| --- | --- | --- | --- | --- | --- |
| 001 | Stoneware Mug | Kitchen (`kitchen`) | mug | $14.00 | A heavy, speckled mug that keeps tea warm through a long call. |
| 002 | Grid Notebook | Desk (`desk`) | notebook | $9.50 | Ninety-six pages of 5 mm grid, stitched to lie flat. |
| 003 | Desk Fern | Garden (`garden`) | plant | $18.00 | A small fern in a glazed pot. Likes shade and a weekly drink. |
| 004 | Cedar Candle | Home (`home`) | candle | $16.00 | Soy wax with a dry cedar scent. Burns for about forty hours. |
| 005 | Brass Desk Lamp | Desk (`desk`) | lamp | $42.00 | A warm, low lamp with a brass shade and a fabric cable. |
| 006 | Steel Water Bottle | Kitchen (`kitchen`) | bottle | $24.00 | Double-walled steel. Cold for a day, hot for half of one. |
| 007 | Wall Clock | Home (`home`) | clock | $35.00 | A quiet sweep movement behind a plain white face. |
| 008 | Canvas Tote | Home (`home`) | tote | $22.00 | Heavy canvas with long handles and one inside pocket. |
| 009 | Fineliner Pen Set | Desk (`desk`) | pen | $12.00 | Six fineliners in muted inks, 0.4 mm tips. |
| 010 | Serving Bowl | Kitchen (`kitchen`) | bowl | $28.00 | A wide stoneware bowl for salads, fruit or bread. |
| 011 | Espresso Cup Pair | Kitchen (`kitchen`) | mug | $19.00 | Two small cups with thick walls and saucers to match. |
| 012 | Dot Journal | Desk (`desk`) | notebook | $11.00 | Dotted pages, numbered, with two ribbon markers. |
| 013 | Succulent Trio | Garden (`garden`) | plant | $21.00 | Three hardy succulents that forgive a missed watering. |
| 014 | Fig Leaf Candle | Home (`home`) | candle | $17.50 | Green and milky. Smells like a fig tree after rain. |
| 015 | Clip Reading Lamp | Desk (`desk`) | lamp | $29.00 | Clips to a shelf or a bed frame. Three brightness steps. |
| 016 | Glass Carafe | Kitchen (`kitchen`) | bottle | $26.00 | A litre of water on the table, with a cup for a lid. |
| 017 | Alarm Clock | Home (`home`) | clock | $23.00 | A silent tick and a gentle rising alarm. |
| 018 | Market Bag | Home (`home`) | tote | $15.00 | Folds into its own pocket. Holds a week of vegetables. |
| 019 | Fountain Pen | Desk (`desk`) | pen | $38.00 | A steel nib, a converter, and a box of blue cartridges. |
| 020 | Salad Bowl | Kitchen (`kitchen`) | bowl | $32.00 | Oiled wood, turned from one piece. |
| 021 | Travel Mug | Kitchen (`kitchen`) | mug | $18.00 | Leak-proof lid, fits a car's cup holder. |
| 022 | Sketchbook | Desk (`desk`) | notebook | $13.50 | Heavy blank paper that takes ink and light washes. |
| 023 | Herb Planter | Garden (`garden`) | plant | $27.00 | A long planter for a sunny sill. Seeds not included. |
| 024 | Beeswax Taper Set | Home (`home`) | candle | $14.50 | Four hand-dipped tapers that burn clean and slow. |
| 025 | Floor Lamp | Home (`home`) | lamp | $89.00 | A tall arc of steel with a linen shade. |
| 026 | Oil Bottle | Kitchen (`kitchen`) | bottle | $12.50 | A pourer that stops dripping when you stop pouring. |
| 027 | Desk Clock | Desk (`desk`) | clock | $31.00 | A small square clock with a date window. |
| 028 | Laptop Tote | Desk (`desk`) | tote | $36.00 | A padded sleeve with handles for a 14-inch laptop. |
| 029 | Brush Pen | Desk (`desk`) | pen | $7.50 | A soft tip for lettering and quick sketches. |
| 030 | Noodle Bowl | Kitchen (`kitchen`) | bowl | $16.00 | Deep enough for broth, with a rest for chopsticks. |
| 031 | Tea Mug | Kitchen (`kitchen`) | mug | $15.00 | A tall mug with a steel infuser that sits inside. |
| 032 | Pocket Notebook | Desk (`desk`) | notebook | $6.00 | Fits a back pocket. Ruled, sixty-four pages. |
| 033 | Hanging Planter | Garden (`garden`) | plant | $24.50 | A glazed pot on a cotton rope, for trailing plants. |
| 034 | Pine Candle | Home (`home`) | candle | $16.00 | Resin and needles. Best on a cold evening. |
| 035 | Bedside Lamp | Home (`home`) | lamp | $45.00 | A touch dimmer and a shade that does not glare. |
| 036 | Vacuum Flask | Kitchen (`kitchen`) | bottle | $29.50 | Keeps soup hot from breakfast until lunch. |
| 037 | Kitchen Timer | Kitchen (`kitchen`) | clock | $19.50 | A wind-up timer with a bell you can hear upstairs. |
| 038 | Beach Tote | Home (`home`) | tote | $25.00 | Striped cotton that shakes clean of sand. |
| 039 | Pencil Set | Desk (`desk`) | pen | $8.50 | Twelve graphite pencils, 4H to 6B. |
| 040 | Fruit Bowl | Kitchen (`kitchen`) | bowl | $34.00 | A wire bowl that lets fruit breathe. |

**Search** matches a name anywhere, ignoring case ("lamp" finds 4), or a number exactly ("7", "007" and "No. 007"
find item 7). A blank query shows all 40.

**Cart.** One line per item, in the order items were first added. A line's quantity is 1–9: adding more caps at 9,
and the stepper's − is disabled at 1. Remove deletes the line. The total is the sum of the lines.

**Orders.** Placing an order moves the cart into a new order, numbered from 1 in each session, with the newest
first.

**Delivery slots** (the slow screen), in order: `Monday · 8:00–10:00`, `Monday · 18:00–20:00`,
`Wednesday · 12:00–14:00`, `Friday · 8:00–10:00`, `Saturday · 10:00–12:00`.

**Loads.** The shop list and the orders list are loaded each time their screen opens. Normally they are ready at
once. Settings › **Slow loading (3 seconds)** makes each load wait 3 s with a spinner first. Settings › **Fail the
first load** makes the first load of each visit fail; **Try again** then succeeds. The slow screen always waits
**3 s**.

## 4. Navigation

Four tabs, in this order: **Shop**, **Cart**, **Lab**, **Settings**. A bottom bar on phones (Material navigation bar on
Android, tab bar on iOS). Signed out, only the sign-in screen exists, with no tabs.

- **A tab always opens at its first screen.** Tapping a tab never restores a deeper screen from an earlier visit. This
  keeps scenarios identical across frameworks.
- Screens below a tab (item, form, gestures, care guide, delivery slots, orders, gift cards) have a top bar with a
  Back control. They hide the tab bar on Android. iOS may keep the tab bar visible, as is native there.
- System Back (Android) and the edge swipe (iOS) always work, and do the same as the top bar's Back.
- Sign out returns to the sign-in screen and clears the back stack.
- The Cart tab says its item count: a badge, and an accessible label such as "Cart, 2 items".

## 5. Screens

Ids in `code` are test ids (§7). Quoted texts are exact (§6 lists them all).

**Sign in** (`signin_screen`). The mark and "Mossgrove", "Home and desk goods". Email (`signin_email`, email
keyboard) and Password (`signin_password`, with its own show/hide button `signin_password_toggle`, labelled "Show
password" / "Hide password"). **Sign in** (`signin_submit`). Empty fields: "Enter your email and password". Wrong
credentials: "Wrong email or password" (`signin_error`). The email is matched ignoring case and surrounding spaces;
the password is exact. Below them is a card (`signin_test_account`) that prints the test account, with **Use test
account** (`signin_use_test_account`), which fills both fields.

**Shop** (`shop_screen`), the long list. A large "Mossgrove" heading, a search field (`shop_search`, placeholder
"Search by name or number", with a clear button `shop_search_clear` while it has text), and a count line
(`shop_count`): "40 drawers · No. 001–040", or "4 of 40 drawers" while searching. Then the list (`shop_list`): one row
per item (`shop_item_{id}`), with its drawing on its aisle's tint, its name and number in a label holder, and its
price. A row is one accessible element that reads its name, number and price, and tapping it opens the item. **Pull
to refresh** waits 0.8 s (3 s when Slow loading is on), then shows the snackbar "Catalogue is up to date". No match:
the empty state (`shop_empty`): "No drawers match "<query>"", "Try a shorter word, or an item number like 7.", **Clear
search** (`shop_empty_action`). Loading: a spinner, "Opening the drawers…" (`shop_loading`). Failed: "The catalogue
didn't load" (`shop_error`), **Try again** (`shop_retry`).

**Item** (`item_screen`), the detail page. The top bar shows the name. Then the drawing (`item_image`, labelled
"Drawing of the <name>"), the number (`item_number`), the name (`item_name`), the price (`item_price`), the
description (`item_description`), and "<Aisle> aisle". A quantity stepper: − (`item_qty_decrease`), the value
(`item_qty_value`, 1–9, starting at 1), + (`item_qty_increase`). **Add to cart · $28.00** (`item_add_to_cart`; the
price is quantity × price) adds that many and shows the snackbar "Added to cart" with the action **View cart**, which
opens the Cart tab. An unknown or non-numeric id shows the not-found state (`item_not_found`): "No drawer has the
number "<id>"", "Items are numbered 1 to 40.", **Back to the shop** (`item_not_found_action`). The top bar then says
"Not found".

**Cart** (`cart_screen`). Each line (`cart_line_{id}`) shows the drawing, name, number, "$14.00 each", a stepper
(`cart_line_decrease_{id}`, `cart_line_qty_{id}`, `cart_line_increase_{id}`), a remove button
(`cart_line_remove_{id}`, labelled "Remove <name>") and the line total (`cart_line_total_{id}`). Pinned below the
lines are **Total** (`cart_total`) and **Check out** (`cart_checkout`). Check out opens the **modal**: "Place this
order?", "<n> items · $42.00. This is a sample shop: nothing is charged or shipped.", with **Cancel** and **Place
order**. Place order empties the cart, adds the order, and shows the snackbar "Order <n> placed" with the action
**View orders**. Empty: "Your cart is empty" (`cart_empty`), "Open a drawer in the shop and add something.",
**Browse the shop** (`cart_empty_action`).

**Lab** (`lab_screen`). One line: "Screens for testing. Each one exercises verbs that NthCase records and replays."
Then six rows, each a title and one line of what it covers: **Join the club** (`lab_form`), **Gestures**
(`lab_gestures`), **Care guide** (`lab_webview`), **Delivery slots** (`lab_slow`), **Orders** (`lab_orders`),
**Gift cards** (`lab_gift_cards`).

**Join the club** (`form_screen`), the form. "Members hear about new drawers first. Every field is required except the
newsletter." The fields, in order:

| Field | Id | Kind | Rule and error text |
| --- | --- | --- | --- |
| Full name | `form_name` | text | not blank · "Enter your name" |
| Email | `form_email` | email keyboard | `^[^@\s]+@[^@\s]+\.[^@\s]+$` · "Enter a valid email address" |
| Age | `form_age` | number keyboard, digits only, ≤ 3 | 18–120 · "Enter an age from 18 to 120" |
| Password | `form_password` + `form_password_toggle` | password with its own show/hide | ≥ 8 characters with a digit · "Use at least 8 characters, including a number" |
| Favourite aisle | `form_category`, options `form_category_option_{key}` | dropdown / picker: Kitchen, Desk, Garden, Home | chosen · "Choose a favourite aisle" |
| Delivery date | `form_date` opens the picker (`form_date_picker`, OK `form_date_confirm`, Cancel `form_date_cancel`) | date picker, opens on the current month | chosen · "Choose a delivery date"; shown as `15 Nov 2026` |
| Email me about new drawers | `form_newsletter` | switch, off | — |
| Monthly budget | `form_budget`, value `form_budget_value` | slider $0–200, $10 steps, starts at $50 | — |
| I accept the club terms | `form_terms` | checkbox, off | ticked · "Accept the terms to continue" |

**Join** (`form_submit`) shows every error at once, each as its own line under its field (`form_<field>_error`). From
then on errors follow every edit. A valid Join shows a card (`form_result`): "Welcome, <name>. We'll write to <email>
about the <Aisle> aisle and deliver on <date>." It also shows the snackbar "Welcome to the club".

**Gestures** (`gestures_screen`). A status bar pinned at the top: the status (`gestures_status`, starts "Ready") and
the orientation (`gestures_orientation`, "Portrait" / "Landscape"). Below it, in a scrolling column
(`gestures_scroll`):

| Element | Id | Gesture | Status after |
| --- | --- | --- | --- |
| Tap pad, with "Taps: N" | `gestures_tap`, `gestures_tap_count` | tap | "Tapped" |
| Double tap pad | `gestures_double_tap` | double tap | "Double-tapped" |
| Long press pad | `gestures_long_press` | long press (≥ 500 ms) | "Long-pressed" |
| Swipe pad | `gestures_swipe` | swipe ≥ 48 dp; the longest axis wins | "Swiped left" / "Swiped right" / "Swiped up" / "Swiped down" |
| Label "No. 007" → Drawer | `gestures_drag_source` → `gestures_drop_target` | drag and drop | "Dropped on the drawer" (outside: "Dropped outside the drawer") |
| Pinch pad, "Zoom 1.0×" | `gestures_pinch`, `gestures_zoom_value` | two-finger pinch, total change > 5 % | "Pinched out" / "Pinched in" |
| Rotate pad, "Rotation 0°" | `gestures_rotate`, `gestures_rotation_value` | two-finger rotation > 10° | "Rotated clockwise" / "Rotated counter-clockwise" |
| 12 shelves, then **Open the bottom drawer** | `gestures_scroll_target` | scroll to it, tap | "Found the bottom drawer" |
| The whole screen | — | shake: 3 jolts over 2.5 g within 1 s | "Shaken" |

The tap, double-tap, long-press, swipe and drag elements also offer their gesture as an accessibility action, so a
screen-reader user can do it too.

**Care guide** (`webview_screen`), the web view. A status line (`webview_status`): "Loading the care guide…", then
"Care guide loaded". Below it is the web view (`webview`), showing the bundled page `care-guide.html`, unchanged in every app. The page has a heading, a link **Jump to washing** (`web_more`) to a heading 900 px down
(`web_washing`), and a form: **Your name** (`web_name`), **Remind me** (`web_frequency`: Every week, Every month
(selected), Never), **Email me the guide** (`web_agree`) and **Save** (`web_submit`). Save writes "Saved, <name>. We will
remind you <frequency, lowercase>." into `web_result`, or "Enter your name first." when the name is empty. Every
element has the same `id` and `data-testid`. The page's Content-Security-Policy allows nothing remote. Links leaving
the page are refused. Debug builds allow inspecting the web view (Appium's WEBVIEW context); release builds do not.

**Delivery slots** (`slow_screen`), the slow screen. Always "Finding delivery slots…" with a spinner
(`slow_loading`) for 3 s, then (`slow_content`) "Choose when we bring your order." and the five slots
(`slow_slot_1` … `slow_slot_5`), and **Reload** (`slow_reload`), which waits 3 s again.

**Orders** (`orders_screen`), the empty and error states. Loading: "Fetching your orders…" (`orders_loading`). Failed:
"Orders didn't load" (`orders_error`), "Something went wrong on our side. Try again in a moment.", **Try again**
(`orders_retry`). Empty: "No orders yet" (`orders_empty`), "Orders you place appear here.", **Start shopping**
(`orders_empty_action`, opens the Shop tab). Otherwise a list (`orders_list`): "Order <n>", "<k> items · <names>",
and the total (`orders_row_{n}`).

**Gift cards**, the screen with **no test ids at all**. No element on it, including its top bar, carries an id. "Check
a balance", a **Card code** field (it upper-cases what is typed), **Check balance**, then the result line:
"Balance: $25.00" for `MOSS-0025`, otherwise "We don't recognise that code". "Buy a card": chips **$10**, **$25**
(selected) and **$50**. Two cards side by side, **Fern** ("Green leaves") on the left and **Stone** ("Grey pebbles")
on the right, each with a button that says **Choose**. Only position tells them apart. Below them: "Choose a design",
then "A $25 card with the Stone design".

**Settings** (`settings_screen`), built with the platform's classic toolkit: **XML Views in a Fragment** on Android,
**UIKit** on iOS. Flutter, React Native and Ionic build it like their other screens; §12 says how. In order:

- **Account:** the signed-in email (`settings_account_email`), **Order history** (`settings_orders`, opens Orders),
  **Sign out** (`settings_sign_out`).
- **Appearance:** a radio group (`settings_theme`): **Follow the system** (`settings_theme_system`, selected),
  **Light** (`settings_theme_light`), **Dark** (`settings_theme_dark`). The choice applies to the whole app at once.
- **Notifications:** a switch **Order updates** (`settings_notifications`). Turning it on when notifications are not
  allowed shows the system's notification permission prompt. This is the app's one permission prompt: Android 13+
  POST_NOTIFICATIONS, iOS UNUserNotificationCenter authorization. The status line (`settings_notifications_status`)
  reads "Not allowed. Turn this on to be asked.", "Off", or "On: we'll tell you when an order is placed." **Send a test
  notification** (`settings_send_notification`) is enabled only when on; it posts a local notification "Your order is
  packed" and shows the snackbar "Notification sent". With updates on, placing an order also posts "Order <n> placed".
- **Testing:** "These change how the shop's lists load. Nothing goes over the network." Two switches: **Slow loading
  (3 seconds)** (`settings_slow_loading`) and **Fail the first load** (`settings_fail_loading`).
- **Data:** **Empty the cart and orders** (`settings_reset`) opens a dialog, "Empty the cart and orders?" / "You stay
  signed in. This can't be undone.", whose buttons are **Cancel** (`settings_reset_cancel`) and **Empty**
  (`settings_reset_confirm`). Its own buttons carry the ids: a stock dialog's buttons would not. Empty then shows the
  snackbar "Cart and orders emptied".
- The version line (`settings_version`): "Mossgrove 1.0.0 · spec 1.0 · a sample app for NthCase".

**Modal and snackbar.** The checkout dialog (`dialog`, `dialog_title`, `dialog_text`, `dialog_confirm`,
`dialog_dismiss`) is the app's modal; the reset dialog is the classic toolkit's. Snackbars (`snackbar`,
`snackbar_text`, `snackbar_action`) stay **10 s** so a step after the action still finds them. On iOS, which has no
snackbar, the app shows the same text in a bottom banner with the same ids and the same 10 s. The Android XML screen's
snackbars are Material Components' own, whose views are already named `snackbar_text` and `snackbar_action`
(`com.nthcase.sample:id/snackbar_text`).

**Deep link.** `nthcase-sample://item/{id}` opens the item page. Signed out, it shows sign-in first and opens the
item right after. Back from a deep-linked item lands on the Shop tab. An id that is not 1–40 shows the item's
not-found state. Any other host or path is ignored.

## 6. Texts the scenarios check

These texts are fixed. An app may not reword them, because the scenarios' checks quote them.

| Where | Text |
| --- | --- |
| Sign in | "Mossgrove", "Home and desk goods", "Test account", "Use test account", "Enter your email and password", "Wrong email or password" |
| Shop | "Search by name or number", "40 drawers · No. 001–040", "<n> of 40 drawers", "No drawers match "<q>"", "Clear search", "Catalogue is up to date", "Opening the drawers…", "The catalogue didn't load", "Try again" |
| Item | "Add to cart · <price>", "Added to cart", "View cart", "No drawer has the number "<id>"", "Back to the shop" |
| Cart | "Your cart is empty", "Browse the shop", "Total", "Check out", "Place this order?", "Cancel", "Place order", "Order <n> placed", "View orders" |
| Form | the seven error texts in §5, "Join", "Welcome to the club", "Welcome, <name>. We'll write to <email> about the <Aisle> aisle and deliver on <d MMM yyyy>." |
| Gestures | "Ready", "Tapped", "Taps: <n>", "Double-tapped", "Long-pressed", "Swiped left/right/up/down", "Dropped on the drawer", "Dropped outside the drawer", "Pinched out", "Pinched in", "Zoom <x.x>×", "Rotated clockwise", "Rotated counter-clockwise", "Rotation <n>°", "Found the bottom drawer", "Shaken", "Portrait", "Landscape" |
| Care guide | "Loading the care guide…", "Care guide loaded", and the page's texts |
| Slow | "Finding delivery slots…", "Choose when we bring your order.", the five slots, "Reload" |
| Orders | "Fetching your orders…", "Orders didn't load", "No orders yet", "Start shopping", "Order <n>" |
| Gift cards | "Check a balance", "Card code", "Check balance", "Balance: $25.00", "We don't recognise that code", "Choose", "Choose a design", "A $<n> card with the <Fern/Stone> design" |
| Settings | every label in §5, "Notification sent", "Cart and orders emptied" |

## 7. Test ids

**One list for all five apps:** [`nthcase/test-ids.json`](nthcase/test-ids.json). It is machine-readable, and each
repository's tests check their app against it. Ids are `snake_case`, `^[a-z][a-z0-9_]*$`, and start with their
screen's name. `{id}` is an item number (1–40), `{n}` a slot or order number, `{key}` an aisle key. `web_*` ids are
HTML `id` and `data-testid` attributes in the bundled page.

**An id must sit on an element that is its own accessibility node.** Platforms fold children into a parent's node: a
clickable row, a Material navigation item, a text field's supporting text, a SwiftUI `.accessibilityElement(children:
.combine)`. An id inside a folded child is invisible to Appium. The Android app hit this three times, with the tab
badge, the tap count and the form's error lines, and the fix is in §5: errors are lines of their own, and the cart
count is in the tab's label. Every app's tests must check ids in the tree Appium reads, not in a debug tree.

### How each framework shows an id to Appium

| Framework | In code | Appium (Android, UiAutomator2) | Appium (iOS, XCUITest) |
| --- | --- | --- | --- |
| Jetpack Compose | `Modifier.testTag("shop_search")`, with `semantics { testTagsAsResourceId = true }` at the root **and inside every Dialog / Popup** (each is its own window) | `resource-id="shop_search"` (no package prefix) | — |
| Android Views (XML) | `android:id="@+id/settings_reset"` | `resource-id="com.nthcase.sample:id/settings_reset"` | — |
| SwiftUI | `.accessibilityIdentifier("shop_search")` | — | `name` = identifier; `accessibility id` locator |
| UIKit | `view.accessibilityIdentifier = "settings_reset"` | — | as SwiftUI |
| Flutter | `Semantics(identifier: 'shop_search', …)` (Flutter ≥ 3.19). A `Key` is for Flutter's own tests and is **not** seen by Appium. | `resource-id="shop_search"` | `name` = identifier |
| React Native | `testID="shop_search"` | `resource-id="shop_search"` | `name` = identifier |
| Ionic / Capacitor | `id="shop_search" data-testid="shop_search"` on the HTML element | WEBVIEW context: `#shop_search` or `[data-testid=…]`. NATIVE context: Chrome's web view usually exposes the HTML `id` as `resource-id`; check it on your WebView version | WEBVIEW context only; the NATIVE tree has labels, not ids |
| Any web view page | the same `id` and `data-testid` | WEBVIEW context (debug builds) | WEBVIEW context (debug builds) |

On Android the web view itself is `resource-id="com.nthcase.sample:id/webview"` in the native app (a view id). In
Flutter and React Native it is the framework's id, `webview`.

### The list

147 ids. The gift-cards screen has none, by design.

| Id | Screen | Element | On screen when |
| --- | --- | --- | --- |
| `nav_shop` | chrome | Bottom bar: Shop tab | tabs |
| `nav_cart` | chrome | Bottom bar: Cart tab. Its accessible label says the count: "Cart, 2 items" | tabs |
| `nav_lab` | chrome | Bottom bar: Lab tab | tabs |
| `nav_settings` | chrome | Bottom bar: Settings tab | tabs |
| `top_bar_title` | chrome | Top app bar: screen title | screens with a top bar |
| `top_bar_back` | chrome | Top app bar: Back | screens below a tab |
| `snackbar` | chrome | Snackbar | after Add to cart, Place order, Join, refresh |
| `snackbar_text` | chrome | Snackbar: message | snackbar |
| `snackbar_action` | chrome | Snackbar: action (View cart, View orders) | snackbar with an action |
| `dialog` | chrome | Modal dialog | checkout confirmation |
| `dialog_title` | chrome | Dialog: title | dialog |
| `dialog_text` | chrome | Dialog: body | dialog |
| `dialog_confirm` | chrome | Dialog: confirm (Place order) | dialog |
| `dialog_dismiss` | chrome | Dialog: Cancel | dialog |
| `signin_screen` | signin | Screen root | shown |
| `signin_email` | signin | Email field | shown |
| `signin_password` | signin | Password field | shown |
| `signin_password_toggle` | signin | Show / hide password | shown |
| `signin_submit` | signin | Sign in button | shown |
| `signin_error` | signin | Error message | after a refused sign-in |
| `signin_test_account` | signin | Test account card | shown |
| `signin_use_test_account` | signin | Use test account (fills both fields) | shown |
| `shop_screen` | shop | Screen root | shown |
| `shop_search` | shop | Search field | shown |
| `shop_search_clear` | shop | Clear search | search has text |
| `shop_count` | shop | Count line (40 drawers · No. 001–040 / 3 of 40 drawers) | loaded |
| `shop_list` | shop | The list (scrolls; pull to refresh) | loaded |
| `shop_item_{id}` | shop | One row per item, id 1–40 | loaded |
| `shop_loading` | shop | Spinner | Slow loading on |
| `shop_error` | shop | Error state | Fail the first load on, first load |
| `shop_retry` | shop | Error state: Try again | shop error |
| `shop_empty` | shop | Empty state (no match) | search matches nothing |
| `shop_empty_action` | shop | Empty state: Clear search | shop empty |
| `item_screen` | item | Screen root | shown |
| `item_image` | item | The item's drawing | known item |
| `item_number` | item | No. 007 | known item |
| `item_name` | item | Name | known item |
| `item_price` | item | Price | known item |
| `item_description` | item | Description | known item |
| `item_qty_decrease` | item | Stepper: − | known item |
| `item_qty_value` | item | Stepper: value (1–9) | known item |
| `item_qty_increase` | item | Stepper: + | known item |
| `item_add_to_cart` | item | Add to cart | known item |
| `item_not_found` | item | Not-found state | unknown id (deep link) |
| `item_not_found_action` | item | Not-found: Back to the shop | unknown id |
| `cart_screen` | cart | Screen root | shown |
| `cart_list` | cart | The lines | cart has items |
| `cart_line_{id}` | cart | One line per item | cart has items |
| `cart_line_decrease_{id}` | cart | Line stepper: − | cart has items |
| `cart_line_qty_{id}` | cart | Line stepper: value | cart has items |
| `cart_line_increase_{id}` | cart | Line stepper: + | cart has items |
| `cart_line_remove_{id}` | cart | Remove the line | cart has items |
| `cart_line_total_{id}` | cart | Line total | cart has items |
| `cart_total` | cart | Total | cart has items |
| `cart_checkout` | cart | Check out (opens the dialog) | cart has items |
| `cart_empty` | cart | Empty state | cart empty |
| `cart_empty_action` | cart | Empty state: Browse the shop | cart empty |
| `lab_screen` | lab | Screen root | shown |
| `lab_form` | lab | Opens Join the club (form) | shown |
| `lab_gestures` | lab | Opens Gestures | shown |
| `lab_webview` | lab | Opens Care guide (web view) | shown |
| `lab_slow` | lab | Opens Delivery slots (slow screen) | shown |
| `lab_orders` | lab | Opens Orders (empty and error states) | shown |
| `lab_gift_cards` | lab | Opens Gift cards (no ids) | shown |
| `form_screen` | form | Screen root | shown |
| `form_name` | form | Full name (text) | shown |
| `form_name_error` | form | Name error | after Join, invalid |
| `form_email` | form | Email | shown |
| `form_email_error` | form | Email error | after Join, invalid |
| `form_age` | form | Age (number) | shown |
| `form_age_error` | form | Age error | after Join, invalid |
| `form_password` | form | Password | shown |
| `form_password_toggle` | form | Show / hide password | shown |
| `form_password_error` | form | Password error | after Join, invalid |
| `form_category` | form | Favourite aisle (dropdown) | shown |
| `form_category_error` | form | Aisle error | after Join, invalid |
| `form_category_option_{key}` | form | Dropdown option: kitchen, desk, garden, home | dropdown open |
| `form_date` | form | Opens the date picker | shown |
| `form_date_error` | form | Date error | after Join, invalid |
| `form_date_picker` | form | The date picker | date picker open |
| `form_date_confirm` | form | Date picker: OK | date picker open |
| `form_date_cancel` | form | Date picker: Cancel | date picker open |
| `form_newsletter` | form | Newsletter (switch) | shown |
| `form_budget` | form | Monthly budget (slider, $0–200, $10 steps) | shown |
| `form_budget_value` | form | Budget value ($50) | shown |
| `form_terms` | form | Accept the terms (checkbox) | shown |
| `form_terms_error` | form | Terms error | after Join, invalid |
| `form_submit` | form | Join | shown |
| `form_result` | form | Welcome card | after a valid Join |
| `gestures_screen` | gestures | Screen root | shown |
| `gestures_status` | gestures | Status line: the last gesture | shown |
| `gestures_orientation` | gestures | Portrait / Landscape | shown |
| `gestures_tap` | gestures | Tap pad | shown |
| `gestures_tap_count` | gestures | Taps: N | shown |
| `gestures_double_tap` | gestures | Double-tap pad | shown |
| `gestures_long_press` | gestures | Long-press pad | shown |
| `gestures_swipe` | gestures | Swipe pad (four directions) | shown |
| `gestures_drag_source` | gestures | Draggable label No. 007 | shown |
| `gestures_drop_target` | gestures | The drawer to drop it on | shown |
| `gestures_pinch` | gestures | Pinch pad | shown |
| `gestures_zoom_value` | gestures | Zoom 1.0× | shown |
| `gestures_rotate` | gestures | Two-finger rotate pad | shown |
| `gestures_rotation_value` | gestures | Rotation 0° | shown |
| `gestures_scroll` | gestures | The scrolling column | shown |
| `gestures_scroll_target` | gestures | Open the bottom drawer (below the fold) | after scrolling |
| `webview_screen` | webview | Screen root | shown |
| `webview` | webview | The WebView | shown |
| `webview_status` | webview | Loading / Care guide loaded | shown |
| `web_title` | webview | Page: heading (HTML id + data-testid) | page loaded |
| `web_more` | webview | Page: Jump to washing link | page loaded |
| `web_form` | webview | Page: the form | page loaded |
| `web_name` | webview | Page: Your name | page loaded |
| `web_frequency` | webview | Page: Remind me (select) | page loaded |
| `web_agree` | webview | Page: Email me the guide (checkbox) | page loaded |
| `web_submit` | webview | Page: Save | page loaded |
| `web_result` | webview | Page: result line | page loaded |
| `web_washing` | webview | Page: Washing heading (far below) | page loaded |
| `slow_screen` | slow | Screen root | shown |
| `slow_loading` | slow | Spinner, 3 s | first 3 s |
| `slow_content` | slow | The slots | after 3 s |
| `slow_slot_{n}` | slow | Slot 1–5 | after 3 s |
| `slow_reload` | slow | Reload (3 s again) | after 3 s |
| `orders_screen` | orders | Screen root | shown |
| `orders_loading` | orders | Spinner | Slow loading on |
| `orders_empty` | orders | Empty state: No orders yet | no orders |
| `orders_empty_action` | orders | Empty state: Start shopping | no orders |
| `orders_error` | orders | Error state | Fail the first load on, first load |
| `orders_retry` | orders | Error state: Try again | orders error |
| `orders_list` | orders | The orders | after an order |
| `orders_row_{n}` | orders | Order N | after an order |
| `settings_screen` | settings | Screen root (XML) | shown |
| `settings_account_email` | settings | Signed-in email | shown |
| `settings_orders` | settings | Order history | shown |
| `settings_sign_out` | settings | Sign out | shown |
| `settings_theme` | settings | Theme (radio group) | shown |
| `settings_theme_system` | settings | Theme: Follow the system | shown |
| `settings_theme_light` | settings | Theme: Light | shown |
| `settings_theme_dark` | settings | Theme: Dark | shown |
| `settings_notifications` | settings | Order updates (switch; asks for the notification permission) | shown |
| `settings_notifications_status` | settings | Notification status line | shown |
| `settings_send_notification` | settings | Send a test notification | shown |
| `settings_slow_loading` | settings | Slow loading (switch) | shown |
| `settings_fail_loading` | settings | Fail the first load (switch) | shown |
| `settings_reset` | settings | Empty the cart and orders (opens a dialog) | shown |
| `settings_reset_confirm` | settings | Reset dialog: Empty | reset dialog |
| `settings_reset_cancel` | settings | Reset dialog: Cancel | reset dialog |
| `settings_version` | settings | Version line | shown |

## 8. Verb coverage

Every verb NthCase records or replays on a phone, and where each app exercises it. The verbs are GuruAI's mobile plan
actions and recorder kinds (`RecordedKinds.Canonical`, `RecorderModes.Phone`, the mobile replay engine). The
scenario column names the file in `nthcase/scenarios/`.

| Verb | Screen and element | Scenario |
| --- | --- | --- |
| `launch` | the app, from cold and after Home | 01, 06 |
| `tap` | everywhere: Sign in, rows, tabs, buttons, chips | all |
| `type` | sign-in fields, search, form fields, gift-card code, the web page's name field | 01, 02, 04, 07, 10 |
| `scroll` (to an element) | shop list to "Fruit Bowl"; form to Join; gestures to "Open the bottom drawer" | 02, 04, 05 |
| `scroll` / `swipe` (a direction) | Swipe pad, four directions; pull to refresh | 02, 05 |
| `back` | top bar Back and system Back on every screen below a tab | 06, 08, 11 |
| `doubletap` | `gestures_double_tap` | 05 |
| `longpress` | `gestures_long_press` | 05 |
| `pinch` | `gestures_pinch` | 05 |
| `dragdrop` | `gestures_drag_source` → `gestures_drop_target` | 05 |
| `slide` | `form_budget` | 04 |
| `select` | `form_category` dropdown; the web page's `web_frequency`; Settings › Appearance radios | 04, 07, 09 |
| `rotate` (device) | any screen; `gestures_orientation` says which | 06 |
| `lock` / `unlock` | any screen | 06 |
| `home` | any screen, then `launch` | 06 |
| `shake` | Gestures screen, status "Shaken" | 06 (emulator / iOS only; see §13) |
| `extract` | the cart total, read into a variable and checked on the order | 03 |
| `startif` / `else` / `endif` | "if the screen shows Sign in, sign in" after Home | 06 |
| `assert` · `visible` / `exists` | every Expect line naming a screen or element | all |
| `assert` · `hidden` / `notExists` | the dialog is gone; a removed line is gone | 03 |
| `assert` · `textContains` / `notTextContains` | every quoted text | all |
| `assert` · `valueEquals` | `form_budget_value` "$120"; `item_qty_value` "2"; a password shown as text | 01, 03, 04 |
| `assert` · `matchesBaseline` / `visual` | any screen; Mossgrove is deterministic enough for a pixel baseline | — (set up per account) |
| `assert` · `activity` (Android) | `com.nthcase.sample.MainActivity`, the one activity | — |
| `waitFor` | the slow screen's slots; the shop under Slow loading | 08 |
| `location` | **not exercised**: it would need a location permission, and the spec allows one prompt (§13) | — |
| two-finger rotation | `gestures_rotate`: there for the day NthCase plays it (§13) | — |
| open a deep link | `nthcase-sample://item/{id}`: no NthCase verb yet (§13) | 11 |

The **hard cases** are covered as follows. The slow load and the failed load with retry are covered in 08. The modal
(03) and the system permission prompt (09) each have a scenario. The web view is 07, and the screen with no ids, found
by text and position, is 10. The long list sits behind a search (02), and the classic-toolkit screen with its own
dialog is 09. Two controls share one text on the gift-cards screen.

## 9. Scenarios

Eleven plain-language scenarios live in [`nthcase/scenarios/`](nthcase/scenarios), the same files in every repository.
Each file is one `create_scenario`: its title is the name, its first paragraph the description, and each numbered line
a step's `instruction`. An indented `Expect:` line is that step's `expected`. Checks quote texts of four letters or
more, which NthCase finds anywhere on the screen. A number or a price names its element's id, because a bare "$28.00"
needs one. Scenarios 01–10 are for the nightly schedule. 11 waits for a deep-link verb.

## 10. Design

The design direction was set with the **impeccable** design skill (direction roll `0bb88391`, mode *Operate*) and is
shared by all five apps. Each app expresses it through its platform's own components: Material 3 on Android, the iOS
conventions on iOS.

**The idea: a parts cabinet.** Every product is a labelled drawer, and its item number ("No. 007") is its identity
mark on every screen. The app refuses the default storefront: no hero banners, no photo cards, no sale badges. The
Lab is a second cabinet of labelled test benches. Four disciplines were kept from the challengers the roll weighed:
- state is never colour alone;
- brass is reserved for the item number, Add to cart and the cart count, never decoration;
- the item number is an identity mark;
- a card exists only where a drawer front is real.

**Colour.** Restrained: one enamel green, cool card-stock neutrals, one brass accent. Brass is the item number,
the **Add to cart** button and the cart badge, and nothing else. No dynamic colour or wallpaper
theming, so all five apps and every screenshot look the same.

| Role | Light | Dark |
| --- | --- | --- |
| primary / on-primary | `#2E5E55` / `#FFFFFF` | `#95D1C2` / `#003730` |
| primary container / on | `#CBE7DF` / `#0B2B25` | `#15493F` / `#B0EEDD` |
| secondary / on | `#4F615C` / `#FFFFFF` | `#B6CBC4` / `#21352F` |
| secondary container / on | `#D2E5DF` / `#0C1F1B` | `#374B45` / `#D2E7E0` |
| tertiary (brass) / on | `#7A5A1C` / `#FFFFFF` | `#EEC06E` / `#412D00` |
| tertiary container / on | `#FCDFA6` / `#271900` | `#5D4200` / `#FFDEA5` |
| error / on | `#BA1A1A` / `#FFFFFF` | `#FFB4AB` / `#690005` |
| error container / on | `#FFDAD6` / `#410002` | `#93000A` / `#FFDAD6` |
| surface (background) / on | `#F7F9F7` / `#181C1B` | `#101413` / `#E0E3E1` |
| surface variant / on | `#DBE5E1` / `#3F4946` | `#3F4946` / `#BFC9C5` |
| outline / outline variant | `#6F7976` / `#BFC9C5` | `#899390` / `#3F4946` |
| surface containers: lowest, low, default, high, highest | `#FFFFFF` `#F1F4F2` `#EBEFEC` `#E5E9E6` `#E0E3E1` | `#0B0F0E` `#181C1B` `#1C2120` `#272B2A` `#313635` |

Aisle tints (an item's tile, and the ink of its drawing): Kitchen `#DDEBE5`/`#2E5E55` (dark `#23332E`/`#95D1C2`),
Desk `#E2E7EE`/`#3F5466` (dark `#222A33`/`#B4C5D8`), Garden `#DCEBD3`/`#3E6A2E` (dark `#263322`/`#A8D493`),
Home `#E8E4DE`/`#5B5148` (dark `#302D29`/`#D3C7BA`).

**Type.** The system face in the platform's type scale: Roboto in Material's roles on Android, SF Pro in the iOS
text styles. No bundled font. Item numbers and the test account use the system **monospace** face. Every size
follows the system font scale.

**Shape and space.** Corners are 4 for label holders and text fields, 8 for chips and drawing tiles, 12 for drawer fronts
and pads, and 28 for dialogs and sheets (dp or pt). Spacing is on a 4 grid: 8 between related items, 12 inside rows,
16 for screen margins, 24 between sections. Buttons are full height (48 dp / 44 pt minimum).

**Icons and art.** Seventeen interface icons and ten product drawings, drawn for these apps as single stroked paths:
[`art/icons/*.svg`](art/icons) (24 units, 2-unit stroke) and [`art/glyphs/*.svg`](art/glyphs) (48 units, 2.5-unit
stroke). The launcher mark is [`art/launcher.svg`](art/launcher.svg), a drawer front with a brass label holder.
Glyphs take their aisle's ink colour. iOS may use SF Symbols for system chrome (the tab bar, Back), as is native, but
uses the Mossgrove drawings for products.

**Motion.** Each platform's own navigation transitions. Nothing decorative, and nothing animates that a check reads.
"Remove animations" / "Reduce Motion" is honoured.

## 11. Repository layout and CI

Every repository has:

| Path | What |
| --- | --- |
| `README.md` | what it is, how to build, how to test with NthCase, the test account, the coverage table, screenshots |
| `SPEC.md` | this document, unchanged, with its version |
| `LICENSE`, `NOTICE` | Apache-2.0, as nth-agent; NOTICE says Mossgrove is fictional and names the NthCase trademark |
| `nthcase/test-ids.json` | §7's list, unchanged |
| `nthcase/scenarios/` | §9's scenarios, unchanged |
| `art/` | §10's drawings, unchanged |
| `care-guide.html` | the bundled page, unchanged, where the platform bundles assets from (Android: `app/src/main/assets/web/`) |
| `docs/screenshots/` | every screen, light and dark, rendered without a device where the platform allows |
| `.github/workflows/` | build on pull request, push to main and manual run; on a `v*` tag, a GitHub Release with the artifacts |
| `CONTRIBUTING.md`, `SECURITY.md` | short |

**CI rules.** Every action is pinned to a commit SHA, with its version in a comment. No secrets: Android ships a
**debug-signed `.apk`**, and iOS ships a **simulator `.app`, zipped**. No `.ipa`, because that needs signing. Jobs
declare `permissions: contents: read`, and only the release step gets `contents: write`, using the run's own token.
Every job has a timeout. Public repositories get Actions minutes free, macOS included.

## 12. Per framework

- **Android (Compose):** one activity. Settings is an XML layout inside a `Fragment`, hosted in the Compose navigation.
  minSdk 26, targetSdk the latest stable. Material 3. `testTagsAsResourceId` at the root and inside every dialog and
  popup window. Tests run on the JVM (Robolectric).
- **iOS (SwiftUI):** a `TabView` with a `NavigationStack` per tab (each reset to its root on reselect, per §4).
  Settings is a `UIViewController` with a `UITableView`, in `UIViewControllerRepresentable`. Snackbar: a bottom banner
  (§5). Web view: `WKWebView` loading the bundled file. Permission: `UNUserNotificationCenter`. Deep link:
  `CFBundleURLTypes` with scheme `nthcase-sample`. Shake: `motionEnded`. Ship the simulator `.app` zipped. Tests:
  XCTest unit tests, and XCUITest tests that run on a CI simulator (never on the operator's machine).
- **Flutter:** `Semantics(identifier:)` for every id (not just `Key`). Settings: build it with plain Material widgets
  and say so in the README: Flutter has no second toolkit. Web view: `webview_flutter` (Flutter's own plugin). Shake:
  `sensors_plus` is third-party, so use a platform channel to the accelerometer instead.
- **React Native (Expo):** `testID` everywhere, and check it with `accessible` grouping in mind (§7). Web view:
  `react-native-webview` is a community package, so name it in the README as the one exception. Notifications:
  `expo-notifications`. Deep link: Expo's `scheme`.
- **Ionic + Capacitor:** the whole app is a web view, so ids are HTML. Use Ionic components (they render native-looking
  controls). The "web view screen" is an `<iframe>` of the bundled page. Notifications: `@capacitor/local-notifications`.
  Deep link: Capacitor's App URL listener.

Any framework that cannot meet a rule writes why in its README, and the next spec version decides.

## 13. Known gaps

What NthCase cannot do yet, as read from GuruAI's code on 2026-11-03. The apps are ready for each:

- **No deep-link step.** No mobile plan action opens a URL. Scenario 11 opens the link from outside, and is not in the
  nightly schedule.
- **No two-finger rotation.** NthCase's `rotate` turns the device. The Rotate pad exists for the day a two-finger
  rotation verb does.
- **`location`** sets a mock position, but Mossgrove asks for no location permission: the spec allows one system
  prompt, and that is notifications. A later spec may add a "Find a shop near you" screen.
- **`shake`** is played on Android emulators only, so it is not in the nightly scenarios.
- **Spinners** last 3 s, which is shorter than a step on a real device, so checks name the content after the wait, not
  the spinner itself.
- **No hide-keyboard step.** The form scrolls its fields above the keyboard, and Join is reachable by scrolling.
