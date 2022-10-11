import BestPizzaPlace from 0xf8d6e0586b0a20c7

/// This transaction borrows a reference to the pizza resource and adds toppings to the pizza.
transaction {
    let addToppingRef: &AnyResource{BestPizzaPlace.AddTopping}

    prepare(acct: AuthAccount) {
        self.addToppingRef = acct.getCapability<&AnyResource{BestPizzaPlace.AddTopping}>(BestPizzaPlace.PizzaAddToppingPrivatePath)
            .borrow()
            ?? panic("Could not borrow reference for adding toppings, only the cook can add toppings.")
    }

    execute {
        let topping1 <- BestPizzaPlace.createTopping(name: "Buffalo Mozzarella", addBeforeBaking: true)
        let topping2 <- BestPizzaPlace.createTopping(name: "Basil", addBeforeBaking: false)

        self.addToppingRef.addTopping(topping: <-topping1)
        /// Baking happening in between ;-)
        self.addToppingRef.addTopping(topping: <-topping2)

        log("Toppings added!")
    }
}