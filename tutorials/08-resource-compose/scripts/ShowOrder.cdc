import BestPizzaPlace from 0xf8d6e0586b0a20c7

// This script reads and displays the order details.
pub fun main(account: Address): BestPizzaPlace.Order {
    let pizzaOrderRef: &AnyResource{BestPizzaPlace.ShowOrder} = getAccount(account).getCapability<&AnyResource{BestPizzaPlace.ShowOrder}>(BestPizzaPlace.PizzaShowOrderPublicPath)
      .borrow()
      ?? panic("Could not borrow a reference to the pizza order, are you sure there is an order for this account?")
    let order = pizzaOrderRef.showOrder()
    log("Order:")
    log(order)
    return order
}