# 02 · Search, scroll and refresh the shop

Search narrows the long list by name or by number; the list scrolls to its last item; pull to refresh says the
catalogue is up to date.

1. Open Mossgrove and sign in with tester@mossgrove.test and Mossgrove123.
   Expect: The shop opens and the screen shows "Stoneware Mug".
2. Type "lamp" in the search field.
   Expect: The count line (shop_count) shows "4 of 40 drawers" and the screen shows "Floor Lamp".
3. Tap the clear-search button.
   Expect: The count line (shop_count) shows "40 drawers".
4. Type "velvet" in the search field.
   Expect: The screen shows "No drawers match" and a "Clear search" button.
5. Tap Clear search.
6. Scroll down the list until "Fruit Bowl" is visible.
   Expect: The screen shows "Fruit Bowl" and "No. 040".
7. Scroll back up to the top of the list.
8. Pull the list down to refresh it.
   Expect: A snackbar says "Catalogue is up to date".
9. Type "7" in the search field.
   Expect: Only one item is listed, "Wall Clock".
