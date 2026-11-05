# 03 · Fill the cart and place an order

The quantity stepper, the snackbar's action, the cart's arithmetic, a modal dialog, and the order history.

1. Open Mossgrove and sign in with tester@mossgrove.test and Mossgrove123.
   Expect: The shop opens and the screen shows "Stoneware Mug".
2. Tap "Stoneware Mug".
   Expect: The item number (item_number) shows "No. 001" and the price (item_price) shows "$14.00".
3. Tap the increase-quantity button once.
   Expect: The quantity (item_qty_value) shows "2".
4. Tap Add to cart.
   Expect: A snackbar says "Added to cart".
5. Tap View cart on the snackbar.
   Expect: The cart total (cart_total) shows "$28.00".
6. Go back to the shop with the Shop tab, open "Brass Desk Lamp" and tap Add to cart.
7. Open the Cart tab.
   Expect: The cart total (cart_total) shows "$70.00".
8. Tap the remove button on the Stoneware Mug line.
   Expect: The screen no longer shows "Stoneware Mug", and the cart total (cart_total) shows "$42.00".
9. Read the cart total and remember it as orderTotal.
10. Tap Check out.
    Expect: A dialog asks "Place this order?".
11. Tap Cancel.
    Expect: The dialog is gone and the cart still shows "Brass Desk Lamp".
12. Tap Check out, then Place order.
    Expect: A snackbar says "Order 1 placed" and the screen shows "Your cart is empty".
13. Tap View orders on the snackbar.
    Expect: The first order (orders_row_1) shows "Order 1" and the remembered orderTotal.
