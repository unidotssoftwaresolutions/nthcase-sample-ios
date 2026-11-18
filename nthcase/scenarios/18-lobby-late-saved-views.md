# 18 · Saved comes late, on the classic-views Lobby

Scenario 16 on the Lobby built with the platform's classic view toolkit: Android Views, or UIKit on iOS. The app that
showed the fault first was built with Android Views, and Views decide which parent claims a drag differently from
Compose. Android and iOS only: the other apps have one Lobby.

1. Open Mossgrove and sign in with tester@mossgrove.test and Mossgrove123.
   Expect: The shop opens and the screen shows "Stoneware Mug".
2. Open the Lab tab and tap the second Lobby row (lab_lobby_views).
   Expect: The touch log (lobby_touch_log) shows "Nothing touched", and the bar shows "Saved".
3. Under "Saved appears after", tap "12 s" (lobby_saved_delay_12).
   Expect: Saved (lobby_bar_saved) is not in the bar, and the touch log (lobby_touch_log) still shows "Nothing touched".
4. Tap Saved in the bottom bar (lobby_bar_saved).
   Expect: The Saved screen (lobby_saved_screen) shows "Saved: nothing yet", the touch log (lobby_touch_log) shows "Tapped: Saved (bar)" and does not mention a banner, a row or a chip, and the touch count (lobby_touch_count) shows "Touches: 1".

As with 16, this is expected to fail on today's NthCase on Android, for the reasons 16 gives. On Android the ids here
are view ids, so Appium reads them as `com.nthcase.sample:id/lobby_bar_saved`.
