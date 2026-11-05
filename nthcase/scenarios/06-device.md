# 06 · The device: rotate, lock, home, back, shake

Verbs that act on the phone rather than on an element. The cart survives rotation and locking. After Home, the app
may come back as it was or start again (that is the phone's choice), so step 11 signs in only if it has to.

1. Open Mossgrove and sign in with tester@mossgrove.test and Mossgrove123.
   Expect: The shop opens and the screen shows "Stoneware Mug".
2. Open "Stoneware Mug" and tap Add to cart.
3. Open the Lab tab and tap "Gestures".
   Expect: The orientation label (gestures_orientation) shows "Portrait".
4. Turn the device to landscape.
   Expect: The orientation label (gestures_orientation) shows "Landscape".
5. Turn the device back to portrait.
   Expect: The orientation label (gestures_orientation) shows "Portrait".
6. Lock the screen, then unlock it.
   Expect: The screen shows "Gestures".
7. Press Back.
   Expect: The Lab shows "Join the club".
8. Open the Cart tab.
   Expect: The screen shows "Stoneware Mug".
9. Open the Shop tab.
10. Press Home, then open Mossgrove again.
    Expect: The screen shows "Mossgrove".
11. If the screen shows "Sign in", sign in with tester@mossgrove.test and Mossgrove123.
    Expect: The screen shows "Stoneware Mug".

Shake, separately: on an emulator or an iOS phone, open Lab › Gestures and shake the device; the status shows
"Shaken". NthCase plays `shake` on Android emulators only (a physical Android phone needs a real shake), so it is
kept out of the nightly scenario.
