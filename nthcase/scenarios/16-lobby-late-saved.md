# 16 · Saved comes late (the reproduction)

The Lobby's bar (lobby_bar) adds its Saved item only after a delay. With the delay at 12 seconds, the tap on Saved has
to wait longer than the half of its budget at which NthCase starts reaching for a missing control. The step must still
end on the Saved screen with nothing else touched on the way.

1. Open Mossgrove and sign in with tester@mossgrove.test and Mossgrove123.
   Expect: The shop opens and the screen shows "Stoneware Mug".
2. Open the Lab tab and tap "Lobby" (lab_lobby).
   Expect: The touch log (lobby_touch_log) shows "Nothing touched", and the bar shows "Saved".
3. Under "Saved appears after", tap "12 s" (lobby_saved_delay_12).
   Expect: Saved (lobby_bar_saved) is not in the bar, and the touch log (lobby_touch_log) still shows "Nothing touched".
4. Tap Saved in the bottom bar (lobby_bar_saved).
   Expect: The Saved screen (lobby_saved_screen) shows "Saved: nothing yet", the touch log (lobby_touch_log) shows "Tapped: Saved (bar)" and does not mention a banner, a row or a chip, and the touch count (lobby_touch_count) shows "Touches: 1".

**On today's NthCase this scenario is expected to fail on some platforms, in the way run `00ec77f5` failed.** Step 4
does not say Saved is late, as the run's step did not: a step marked slow gets a longer budget, and that moves the
moment NthCase reaches for the control. With the default 10 s budget, step 4 looks for Saved from a second or more
after the choice, polls, and at 5 s into its look scrolls once toward it. Saved is not there yet: it comes 12 s after
the choice.

On Android that scroll is `new UiScrollable(new UiSelector().scrollable(true)).scrollIntoView(…)`. It takes the first
scrollable in the tree, the promo pager, and swipes it up, then down, through the middle of banner 1. Nothing on the
pager scrolls that way. What follows is the failure this scenario looks for:
- If banner 1 takes the swipe as a long press, the quick sheet opens with its own "Saved" button. The bar is now under
  a window of its own and out of reach, so the step ends "not found", and a heal that looks at the screen finds the
  sheet's Saved (lobby_sheet_saved). In Assisted it would tap it, and the log would say "Tapped: Saved (quick sheet,
  New in the Kitchen aisle)".
- If banner 1 takes it as a tap, the promo opens. Saved may still come in time and be tapped, but the touch log names
  the banner and the count says 2, so the check fails.

A platform whose reach never swipes the first scrollable, or never touches what it swipes, passes. Each platform's
round records what happened. Do not change the delay to make this pass: the delay is the point.
