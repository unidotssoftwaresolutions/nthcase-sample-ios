# 09 · Settings, the notification prompt and a confirm dialog

Settings is the screen built with the platform's classic toolkit (XML Views on Android, UIKit on iOS). It holds the
app's one system permission prompt.

1. Open Mossgrove and sign in with tester@mossgrove.test and Mossgrove123.
   Expect: The shop opens and the screen shows "Stoneware Mug".
2. Open the Settings tab.
   Expect: The screen shows "tester@mossgrove.test" and "Not allowed. Turn this on to be asked."
3. Choose "Dark" under Appearance.
   Expect: The Dark option is selected.
4. Choose "Follow the system" under Appearance.
5. Turn on "Order updates".
   Expect: The system asks whether Mossgrove may send notifications.
6. Allow notifications.
   Expect: The screen shows "On: we'll tell you when an order is placed."
7. Tap "Send a test notification".
   Expect: The screen shows "Notification sent".
8. Tap "Empty the cart and orders".
   Expect: A dialog asks "Empty the cart and orders?".
9. Tap Cancel.
10. Tap Sign out.
    Expect: The sign-in screen shows "Test account".

On a device where the permission was already granted or refused, step 5 shows no prompt. Reinstall the app, or reset
its permission, before running this scenario.
