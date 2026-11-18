# 14 · The board, both ways

The board (lobby_board) is a small window onto 26 × 26 labelled cells that scrolls both sideways and up and down. Pan
it to cell M18, tap it, then double-tap it. Panning is not a touch.

1. Open Mossgrove and sign in with tester@mossgrove.test and Mossgrove123.
   Expect: The shop opens and the screen shows "Stoneware Mug".
2. Open the Lab tab and tap "Lobby" (lab_lobby).
   Expect: The touch log (lobby_touch_log) shows "Nothing touched".
3. Scroll the Lobby's page (lobby_page) down until the board (lobby_board) is visible.
   Expect: The screen shows "Board: top-left A1", and the touch log (lobby_touch_log) still shows "Nothing touched".
4. Scroll the board (lobby_board) toward its right and toward its bottom until cell M18 (lobby_board_cell_m18) is visible.
   Expect: Cell M18 (lobby_board_cell_m18) is visible, and the touch log (lobby_touch_log) still shows "Nothing touched".
5. Tap cell M18 (lobby_board_cell_m18).
   Expect: The touch log (lobby_touch_log) shows "Tapped: M18 (board)".
6. Double-tap cell M18 (lobby_board_cell_m18).
   Expect: The touch log (lobby_touch_log) shows "Double-tapped: M18 (board)", and the touch count (lobby_touch_count) shows "Touches: 2".
