# Mossgrove scenarios (spec 1.0)

Plain-language NthCase scenarios. The same files run against every Mossgrove app: Android, iOS, Flutter, React Native
and Ionic. Each is what `create_scenario` takes: a name, a description, and ordered steps. A step is one numbered line,
the `instruction`. An indented `Expect:` line under it is that step's `expected`, the check NthCase makes after it.

- A step names an element by what a person sees ("the Sign in button"). Where a check reads a number or a price, it
  also names the element's test id in brackets: quoted words of four letters or more are found anywhere on the
  screen, but a bare "$28.00" needs its element.
- Every scenario starts from a fresh launch: signed out, empty cart, no orders, Settings at their defaults.
- The test account is `tester@mossgrove.test` / `Mossgrove123`.

| File | What it proves | Verbs |
| --- | --- | --- |
| [01-sign-in.md](01-sign-in.md) | Sign-in refuses a wrong password, then signs in | launch, type, tap, assert |
| [02-search-and-scroll.md](02-search-and-scroll.md) | Search narrows the list; scroll and pull to refresh | type, tap, scroll, assert |
| [03-cart-and-order.md](03-cart-and-order.md) | Stepper, cart total, modal, snackbar, order history | tap, extract, assert |
| [04-form.md](04-form.md) | Every form control and every validation error | type, select, slide, tap, scroll, assert |
| [05-gestures.md](05-gestures.md) | Double tap, long press, four swipes, drag and drop, pinch, scroll to an element | doubletap, longpress, scroll, dragdrop, pinch, assert |
| [06-device.md](06-device.md) | Rotation, lock and unlock, home and back to the app, Back, shake | rotate, lock, unlock, home, launch, back, shake |
| [07-web-view.md](07-web-view.md) | A bundled web page: type, select, check, tap, read | type, select, tap, assert |
| [08-slow-and-states.md](08-slow-and-states.md) | A 3 s load, an error with retry, empty states | waitFor, tap, assert |
| [09-settings-and-permission.md](09-settings-and-permission.md) | The XML / UIKit settings screen, the notification prompt, a dialog | tap, select, assert |
| [10-no-test-ids.md](10-no-test-ids.md) | A screen with no ids: by text and by position | type, tap, assert |
| [11-deep-link.md](11-deep-link.md) | `nthcase-sample://item/7` after sign-in | (no NthCase verb yet; see the file) |
