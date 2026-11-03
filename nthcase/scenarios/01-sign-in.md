# 01 · Sign in with the test account

A wrong password is refused with a message; the test account signs in and the shop opens.

1. Open Mossgrove.
   Expect: The screen shows "Mossgrove" and "Home and desk goods".
2. Type "tester@mossgrove.test" in the Email field.
3. Type "letmein1" in the Password field.
4. Tap Sign in.
   Expect: The screen shows "Wrong email or password".
5. Tap the show-password button next to the Password field.
   Expect: The Password field (signin_password) shows "letmein1".
6. Clear the Password field and type "Mossgrove123".
7. Tap Sign in.
   Expect: The shop opens: the screen shows "Stoneware Mug" and the count line (shop_count) says "40 drawers".
