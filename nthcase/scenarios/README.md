# Mossgrove scenarios (spec 1.1)

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
| [12-lobby-scroll-touches-nothing.md](12-lobby-scroll-touches-nothing.md) | The Lobby scrolls to its end and back with nothing touched | scroll, assert |
| [13-lobby-row-tile.md](13-lobby-row-tile.md) | A tile deep in a sideways row: scroll to it, tap it, long-press it | scroll, tap, longpress, back, assert |
| [14-lobby-board.md](14-lobby-board.md) | A board that scrolls both ways: pan to M18, tap, double-tap | scroll, tap, doubletap, assert |
| [15-lobby-pager.md](15-lobby-pager.md) | The promo pager, swiped to banner 4, then tapped | swipe, tap, assert |
| [16-lobby-late-saved.md](16-lobby-late-saved.md) | A bar item that comes late (12 s): **the reproduction**, expected to fail today on some platforms | tap, waitFor, assert |
| [17-lobby-saved-waits.md](17-lobby-saved-waits.md) | The same with 3 s: waiting is enough | tap, waitFor, assert |
| [18-lobby-late-saved-views.md](18-lobby-late-saved-views.md) | 16 on the classic-views Lobby (Android Views, iOS UIKit) | tap, waitFor, assert |
| [19-lobby-late-saved-no-pager.md](19-lobby-late-saved-no-pager.md) | 16 with the pager off, so a row of tiles is the first scrollable: **the run's own case**, expected to fail today on some platforms | tap, waitFor, assert |
| [20-lobby-late-saved-no-pager-views.md](20-lobby-late-saved-no-pager-views.md) | 19 on the classic-views Lobby (Android Views, iOS UIKit) | tap, waitFor, assert |

12–20 are the Lobby's (spec 1.1). They check the Lobby's touch log (lobby_touch_log) after every scroll, swipe and tap:
a scroll that touches something shows there. 16, 18, 19 and 20 say what today's NthCase is expected to do with them: in
16 and 18 a banner of the pager is under the swipe, in 19 and 20 a tile of the Top 10 row. Any Lobby scenario runs on
the classic-views Lobby too, by tapping `lab_lobby_views` instead of `lab_lobby` in step 2.
