# 05 · Every gesture on the Gestures screen

The status line at the top of the screen (gestures_status) names the last gesture, in the same words on every app.

1. Open Mossgrove and sign in with tester@mossgrove.test and Mossgrove123.
2. Open the Lab tab and tap "Gestures".
   Expect: The status (gestures_status) shows "Ready".
3. Tap the Tap pad.
   Expect: The status shows "Tapped" and the pad shows "Taps: 1".
4. Double-tap the Double tap pad.
   Expect: The status shows "Double-tapped".
5. Long-press the Long press pad.
   Expect: The status shows "Long-pressed".
6. Swipe left on the Swipe pad.
   Expect: The status shows "Swiped left".
7. Swipe right on the Swipe pad.
   Expect: The status shows "Swiped right".
8. Swipe up on the Swipe pad.
   Expect: The status shows "Swiped up".
9. Swipe down on the Swipe pad.
   Expect: The status shows "Swiped down".
10. Drag the "No. 007" label onto the Drawer.
    Expect: The status shows "Dropped on the drawer".
11. Pinch out (zoom in) on the Pinch pad.
    Expect: The status shows "Pinched out".
12. Scroll down to "Open the bottom drawer" and tap it.
    Expect: The status shows "Found the bottom drawer".

Not in this file: the two-finger rotation on the Rotate pad. NthCase has no verb that plays a two-finger rotation
yet (its `rotate` turns the device), so a step for it would compile to `unsupported`. The pad is there for the day it
does: the status then says "Rotated clockwise" or "Rotated counter-clockwise".
