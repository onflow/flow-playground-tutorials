import BestPizzaPlace from 0xf8d6e0586b0a20c7

/// This transaction creates a pizza resource and moves it to the account storage.
/// It also creates a private capability that allows to add toppings and a public capability
/// which allows to check the order later.
transaction {
    let account: AuthAccount

    prepare(acct: AuthAccount) {
        let dough <- BestPizzaPlace.createDough(grain: BestPizzaPlace.Grain.wheat, timeToBake: 20)
        let sauce <- BestPizzaPlace.createSauce(name: "Tomato sauce", spiciness: BestPizzaPlace.Spiciness.hot)

        let pizza <- BestPizzaPlace.createPizza(name: "Bufalina", dough: <-dough, sauce: <-sauce)

        /// Store the pizza
        acct.save<@BestPizzaPlace.Pizza>(<-pizza, to: BestPizzaPlace.PizzaStoragePath)
        /// Link capability references
        acct.link<&AnyResource{BestPizzaPlace.AddTopping}>(BestPizzaPlace.PizzaAddToppingPrivatePath, target: BestPizzaPlace.PizzaStoragePath)
        acct.link<&AnyResource{BestPizzaPlace.ShowOrder}>(BestPizzaPlace.PizzaShowOrderPublicPath, target: BestPizzaPlace.PizzaStoragePath)

        self.account = acct
        log("Pizza will be prepared!")
    }
}
