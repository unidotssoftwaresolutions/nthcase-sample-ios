# 04 · Join the club: every form control

Text, email, number and password fields, a dropdown, a date picker, a switch, a slider and a checkbox, with their
validation errors. Opened from the Lab tab.

1. Open Mossgrove and sign in with tester@mossgrove.test and Mossgrove123.
   Expect: The shop opens and the screen shows "Stoneware Mug".
2. Open the Lab tab and tap "Join the club".
3. Scroll down and tap Join without filling anything in.
   Expect: The screen shows "Enter your name", "Enter a valid email address", "Enter an age from 18 to 120" and
   "Accept the terms to continue".
4. Type "Sam Rivera" in Full name.
5. Type "sam@example" in Email.
   Expect: The screen still shows "Enter a valid email address".
6. Add ".test" to the end of the Email field.
   Expect: The screen no longer shows "Enter a valid email address".
7. Type "34" in Age.
8. Type "garden42x" in Password, then tap its show-password button.
   Expect: The Password field (form_password) shows "garden42x".
9. Choose "Garden" in the Favourite aisle dropdown.
10. Tap the calendar button of Delivery date, pick the 15th of the month shown, and tap OK.
    Expect: The Delivery date field shows "15".
11. Turn on "Email me about new drawers".
12. Drag the Monthly budget slider to about 60 percent.
    Expect: The budget value (form_budget_value) shows "$120".
13. Tick "I accept the club terms".
14. Tap Join.
    Expect: The screen shows "Welcome, Sam Rivera" and "Garden aisle", and a snackbar says "Welcome to the club".
