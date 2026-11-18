# 12 · Scroll the Lobby and touch nothing

The Lobby is a screen of many scrollers with a touch log at the top (lobby_touch_log). Scrolling is not a touch, so after
scrolling the whole page down and back up the log must still say "Nothing touched".

1. Open Mossgrove and sign in with tester@mossgrove.test and Mossgrove123.
   Expect: The shop opens and the screen shows "Stoneware Mug".
2. Open the Lab tab and tap "Lobby" (lab_lobby).
   Expect: The touch log (lobby_touch_log) shows "Nothing touched".
3. Scroll the Lobby's page (lobby_page) down until "End of the lobby" is visible.
   Expect: The screen shows "End of the lobby", and the touch log (lobby_touch_log) still shows "Nothing touched".
4. Scroll the page (lobby_page) back up until "Row 1" is visible.
   Expect: The touch log (lobby_touch_log) still shows "Nothing touched" and the touch count (lobby_touch_count) shows "Touches: 0".

The first scrollable element on this screen is the promo pager, which scrolls sideways; the page is the second. On
Android, today's NthCase scrolls to an element with `UiScrollable(new UiSelector().scrollable(true))`, which swipes the
first scrollable up and down, not the page. If a step here is played that way, the page may not move and the swipe may
reach a banner: the touch log then names it. That is the fault scenario 16 reproduces, seen from a scroll step.
