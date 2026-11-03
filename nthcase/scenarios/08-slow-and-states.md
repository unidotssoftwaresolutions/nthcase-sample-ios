# 08 · A slow screen, an error with retry, and empty states

Loading for 3 seconds, a load that fails once and then succeeds on Try again, and the empty cart and order history.

1. Open Mossgrove and sign in with tester@mossgrove.test and Mossgrove123.
2. Open the Lab tab and tap "Delivery slots".
3. Wait until the delivery slots appear.
   Expect: The screen shows "Monday · 8:00–10:00" and "Saturday · 10:00–12:00".
4. Press Back, and tap "Orders".
   Expect: The screen shows "No orders yet".
5. Press Back, open the Settings tab and turn on "Fail the first load".
6. Open the Lab tab and tap "Orders".
   Expect: The screen shows "Orders didn't load".
7. Tap Try again.
   Expect: The screen shows "No orders yet".
8. Press Back. Open the Settings tab, turn off "Fail the first load" and turn on "Slow loading (3 seconds)".
9. Open the Shop tab, and wait until the list appears.
   Expect: The screen shows "Stoneware Mug".
10. Open the Cart tab.
    Expect: The screen shows "Your cart is empty".

The spinners ("Finding delivery slots…", "Opening the drawers…") last 3 seconds, which is less than a step can take
on a real device, so no check names them: the steps prove the wait, and the JVM tests prove the spinner.
