# 19 · Saved comes late, with the pager off

Scenario 16 with the promo pager turned off. Then the first scrollable on the Lobby is the Top 10 row, a row of tiles
that no vertical scroller encloses, as in the app where the fault was first seen. The step must still end on the Saved
screen with nothing else touched on the way.

1. Open Mossgrove and sign in with tester@mossgrove.test and Mossgrove123.
   Expect: The shop opens and the screen shows "Stoneware Mug".
2. Open the Lab tab and tap "Lobby" (lab_lobby).
   Expect: The touch log (lobby_touch_log) shows "Nothing touched", and the bar shows "Saved".
3. Turn off "Show the pager" (lobby_pager_shown).
   Expect: The promo pager (lobby_pager) is not on the screen, the Top 10 row (lobby_top_row) is, and the touch log (lobby_touch_log) still shows "Nothing touched".
4. Under "Saved appears after", tap "12 s" (lobby_saved_delay_12).
   Expect: Saved (lobby_bar_saved) is not in the bar, and the touch log (lobby_touch_log) still shows "Nothing touched".
5. Tap Saved in the bottom bar (lobby_bar_saved).
   Expect: The Saved screen (lobby_saved_screen) shows "Saved: nothing yet", the touch log (lobby_touch_log) shows "Tapped: Saved (bar)" and does not mention a tile, a banner or a chip, and the touch count (lobby_touch_count) shows "Touches: 1".

**On today's NthCase this scenario is expected to fail on some platforms, in Jalla's own way.** Step 5 is step 4 of
scenario 16, with the same timing: the look for Saved scrolls once at 5 s, before Saved exists. On Android that scroll
is `new UiScrollable(new UiSelector().scrollable(true)).scrollIntoView(…)`, and with the pager gone the first scrollable
is the Top 10 row. The swipe goes up, then down, through the middle of the row, over a tile (tile 2, Pocket Notebook,
on a phone 360 dp wide). Nothing on the row scrolls that way, and nothing above it claims the swipe. What follows is
the failure this scenario looks for:
- If the tile takes the swipe as a long press, its quick sheet opens with its own "Saved" button. The bar is now under
  a window of its own and out of reach, so the step ends "not found", and a heal that looks at the screen finds the
  sheet's Saved (lobby_sheet_saved). In Assisted it would tap it, and the log would say "Tapped: Saved (quick sheet,
  Pocket Notebook)". This is what run `00ec77f5` did.
- If the tile takes it as a tap, its detail opens in place of the page. Saved may still come in time and be tapped,
  but the touch log names the tile, "(top row, tile 2)", and the count says 2, so the check fails.

A platform whose reach never swipes the first scrollable, or never touches what it swipes, passes. Each platform's
round records what happened. Do not change the delay or turn the pager back on to make this pass: the delay and the
row are the point.
