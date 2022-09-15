import BestPizzaPlace from 0xf8d6e0586b0a20c7

transaction {
    prepare(acct: AuthAccount) {
        let dough <- BestPizzaPlace.createDough(grain: BestPizzaPlace.Grain.wheat, timeToBake: 20)
        let sauce <- BestPizzaPlace.createSauce(name: "Tomato sauce", spiciness: BestPizzaPlace.Spiciness.hot)

        let topping1 <- BestPizzaPlace.createTopping(name: "Buffalo Mozzarella", addBeforeBaking: true)
        let topping2 <- BestPizzaPlace.createTopping(name: "Basil", addBeforeBaking: false)

        let pizza <- BestPizzaPlace.createPizza(name: "Bufalina")

        pizza.addIngredient(newIngredient: <-dough)
        pizza.addIngredient(newIngredient: <-sauce)
        pizza.addIngredient(newIngredient: <-topping1)
        pizza.addIngredient(newIngredient: <-topping2)

        acct.save(<-pizza, to: BestPizzaPlace.PizzaStoragePath)

        log("Pizza will be prepared!")
    }
}