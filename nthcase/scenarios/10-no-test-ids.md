# 10 · Gift cards: a screen with no test ids

Nothing on this screen has a test id. NthCase must find each control by its visible text, its label, and its
position: two buttons both say "Choose".

1. Open Mossgrove and sign in with tester@mossgrove.test and Mossgrove123.
2. Open the Lab tab and tap "Gift cards".
   Expect: The screen shows "Check a balance".
3. Type "MOSS-0025" in the Card code field.
4. Tap Check balance.
   Expect: The screen shows "Balance: $25.00".
5. Type "MOSS-9999" in the Card code field instead, and tap Check balance.
   Expect: The screen shows "We don't recognise that code".
6. Tap the "$50" chip.
7. Tap the "Choose" button on the right-hand card, Stone.
   Expect: The screen shows "A $50 card with the Stone design".
8. Tap the "Choose" button on the left-hand card, Fern.
   Expect: The screen shows "A $50 card with the Fern design".
