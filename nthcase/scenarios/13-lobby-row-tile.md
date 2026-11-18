# 13 · A tile deep in row 3

Scroll the page to the third tile row, scroll that row sideways to its tile 15, and tap it, then long-press it. The
touch log (lobby_touch_log) must stay empty through both scrolls, and then name exactly what was touched.

1. Open Mossgrove and sign in with tester@mossgrove.test and Mossgrove123.
   Expect: The shop opens and the screen shows "Stoneware Mug".
2. Open the Lab tab and tap "Lobby" (lab_lobby).
   Expect: The touch log (lobby_touch_log) shows "Nothing touched".
3. Scroll the Lobby's page (lobby_page) down until row 3 (lobby_row_3) is visible.
   Expect: The screen shows "Row 3", and the touch log (lobby_touch_log) still shows "Nothing touched".
4. Scroll row 3 (lobby_row_3) toward its end until tile 15 (lobby_row_3_tile_15), "Bedside Lamp", is visible.
   Expect: The screen shows "Bedside Lamp", and the touch log (lobby_touch_log) still shows "Nothing touched".
5. Tap tile 15 of row 3 (lobby_row_3_tile_15).
   Expect: The detail (lobby_detail) shows "Bedside Lamp" and "Row 3, tile 15", and the touch log (lobby_touch_log) shows "Tapped: Bedside Lamp (row 3, tile 15)".
6. Tap "Back to the lobby".
   Expect: The screen shows "Bedside Lamp" again: row 3 kept its place.
7. Long-press tile 15 of row 3 (lobby_row_3_tile_15).
   Expect: The quick sheet (lobby_sheet) shows "Open", "Preview", "Saved" and "Rate".
8. Press Back.
   Expect: The quick sheet is gone, the touch log (lobby_touch_log) shows "Long-pressed: Bedside Lamp (row 3, tile 15)", and the touch count (lobby_touch_count) shows "Touches: 2".

The quick sheet is a window of its own, so while it is open the touch log under it may not be in the tree Appium
reads. That is why step 7 checks the sheet and step 8 checks the log.
