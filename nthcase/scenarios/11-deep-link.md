# 11 · Deep link to an item

`nthcase-sample://item/{id}` opens an item's page. From a cold start it asks for sign-in first, then opens the item.
An unknown id opens the page's not-found state.

NthCase has no step that opens a URL on a phone yet, so this scenario is not in the nightly schedule. Until it has
one, open the link from outside before the run:

- Android, one emulator or device named by its serial: `adb -s <serial> shell am start -W -a android.intent.action.VIEW -d "nthcase-sample://item/7"`
- iOS Simulator, named by its UDID (never `booted`, which means every booted simulator): `xcrun simctl openurl <udid> "nthcase-sample://item/7"`

Then:

1. Sign in with tester@mossgrove.test and Mossgrove123.
   Expect: The item page opens: the name (item_name) shows "Wall Clock" and the number (item_number) shows "No. 007".
2. Press Back.
   Expect: The shop opens: the screen shows "Stoneware Mug".

With `nthcase-sample://item/999` instead, step 1 expects "No drawer has the number".
