# 20 · Saved comes late, with the pager off, on the classic-views Lobby

Scenario 19 on the Lobby built with the platform's classic view toolkit: Lobby (Views) on Android, Lobby (UIKit) on
iOS. The app that showed the fault was built with Android Views, and its first scrollable was a row of tiles, which is
what this scenario sets up. Android and iOS only: the other apps have one Lobby.

1. Open Mossgrove and sign in with tester@mossgrove.test and Mossgrove123.
   Expect: The shop opens and the screen shows "Stoneware Mug".
2. Open the Lab tab and tap the second Lobby row (lab_lobby_views).
   Expect: The touch log (lobby_touch_log) shows "Nothing touched", and the bar shows "Saved".
3. Turn off "Show the pager" (lobby_pager_shown).
   Expect: The promo pager (lobby_pager) is not on the screen, the Top 10 row (lobby_top_row) is, and the touch log (lobby_touch_log) still shows "Nothing touched".
4. Under "Saved appears after", tap "12 s" (lobby_saved_delay_12).
   Expect: Saved (lobby_bar_saved) is not in the bar, and the touch log (lobby_touch_log) still shows "Nothing touched".
5. Tap Saved in the bottom bar (lobby_bar_saved).
   Expect: The Saved screen (lobby_saved_screen) shows "Saved: nothing yet", the touch log (lobby_touch_log) shows "Tapped: Saved (bar)" and does not mention a tile, a banner or a chip, and the touch count (lobby_touch_count) shows "Touches: 1".

As with 19, this is expected to fail on today's NthCase on Android, for the reasons 19 gives: a Top 10 tile is
long-pressed (or tapped), its sheet opens, and a heal finds the sheet's "Saved". On Android the ids here are view ids,
so Appium reads them as `com.nthcase.sample:id/lobby_bar_saved`.
