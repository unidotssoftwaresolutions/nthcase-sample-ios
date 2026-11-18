# 17 · Saved comes soon (waiting is enough)

The same as 16 with a 3-second delay. Saved arrives before NthCase would reach for it, so a step that waits finds it
with no scroll at all, as the passing runs of the same real-world step did.

1. Open Mossgrove and sign in with tester@mossgrove.test and Mossgrove123.
   Expect: The shop opens and the screen shows "Stoneware Mug".
2. Open the Lab tab and tap "Lobby" (lab_lobby).
   Expect: The touch log (lobby_touch_log) shows "Nothing touched", and the bar shows "Saved".
3. Under "Saved appears after", tap "3 s" (lobby_saved_delay_3).
   Expect: The touch log (lobby_touch_log) still shows "Nothing touched".
4. Tap Saved in the bottom bar (lobby_bar_saved).
   Expect: The Saved screen (lobby_saved_screen) shows "Saved: nothing yet", the touch log (lobby_touch_log) shows "Tapped: Saved (bar)", and the touch count (lobby_touch_count) shows "Touches: 1".

Saved arrives at most 3 s into step 4's look, and NthCase scrolls toward a missing control only after 5 s (half of
the default 10 s budget). This scenario should pass on today's NthCase on every platform. Step 3 does not check that
Saved has gone: it is back 3 s after the choice, which may be before that check runs. If step 3 takes longer than 3 s,
Saved is already there when step 4 starts, and the step passes without waiting.
