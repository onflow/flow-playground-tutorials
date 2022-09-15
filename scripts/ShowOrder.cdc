import BestPizzaPlace from 0xf8d6e0586b0a20c7

pub fun main(account: Address) {
    let pizzaRef: &BestPizzaPlace.Pizza = getAccount(account).getCapability(BestPizzaPlace.PizzaPublicPath)
      .borrow<&BestPizzaPlace.Pizza>()
      ?? panic("Could not borrow a reference to the pizza")
    let order = pizzaRef.showOrder()
    log("Order:")
    log(order)
}