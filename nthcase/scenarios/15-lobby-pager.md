# 15 · The promo pager

The promo pager (lobby_pager) shows one banner at a time, five in all. Swipe it to the fourth banner, one banner at a
time, then tap that banner. A swipe is not a touch.

1. Open Mossgrove and sign in with tester@mossgrove.test and Mossgrove123.
   Expect: The shop opens and the screen shows "Stoneware Mug".
2. Open the Lab tab and tap "Lobby" (lab_lobby).
   Expect: The pager's position (lobby_pager_position) shows "Banner 1 of 5", and the touch log (lobby_touch_log) shows "Nothing touched".
3. Swipe left on the promo pager (lobby_pager).
   Expect: The pager's position (lobby_pager_position) shows "Banner 2 of 5", and the touch log (lobby_touch_log) still shows "Nothing touched".
4. Swipe left on the promo pager (lobby_pager) again.
   Expect: The pager's position (lobby_pager_position) shows "Banner 3 of 5", and the touch log (lobby_touch_log) still shows "Nothing touched".
5. Swipe left on the promo pager (lobby_pager) once more.
   Expect: The pager's position (lobby_pager_position) shows "Banner 4 of 5", the screen shows "Candles for long evenings", and the touch log (lobby_touch_log) still shows "Nothing touched".
6. Tap the banner (lobby_banner_4).
   Expect: The promo (lobby_promo) shows "Candles for long evenings" and "Banner 4 of 5", and the touch log (lobby_touch_log) shows "Tapped: Candles for long evenings (banner 4)".
