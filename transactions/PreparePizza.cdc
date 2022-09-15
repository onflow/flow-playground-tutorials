import BestPizzaPlace from 0xf8d6e0586b0a20c7

transaction {
    let account: AuthAccount

    prepare(acct: AuthAccount) {
        let dough <- BestPizzaPlace.createDough(grain: BestPizzaPlace.Grain.wheat, timeToBake: 20)
        let sauce <- BestPizzaPlace.createSauce(name: "Tomato sauce", spiciness: BestPizzaPlace.Spiciness.hot)

        let pizza <- BestPizzaPlace.createPizza(name: "Bufalina", dough: <-dough, sauce: <-sauce)

        let topping1 <- BestPizzaPlace.createTopping(name: "Buffalo Mozzarella", addBeforeBaking: true)
        let topping2 <- BestPizzaPlace.createTopping(name: "Basil", addBeforeBaking: false)

        pizza.addTopping(topping: <-topping1)
        pizza.addTopping(topping: <-topping2)

        acct.save<@BestPizzaPlace.Pizza>(<-pizza, to: BestPizzaPlace.PizzaStoragePath)
        acct.link<&BestPizzaPlace.Pizza>(BestPizzaPlace.PizzaPublicPath, target: BestPizzaPlace.PizzaStoragePath)

        self.account = acct
        log("Pizza will be prepared!")
    }

    post {
        // Check that the capability was created correctly
       getAccount(self.account.address).getCapability<&BestPizzaPlace.Pizza>(BestPizzaPlace.PizzaPublicPath)
       .check():
         "Pizza Reference was not created correctly"
    }
}