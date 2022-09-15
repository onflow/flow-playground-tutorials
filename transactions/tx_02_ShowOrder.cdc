import BestPizzaPlace from 0xf8d6e0586b0a20c7

transaction {
    prepare(acct: AuthAccount) {
        let pizza <- acct.load<@BestPizzaPlace.Pizza>(from: BestPizzaPlace.PizzaStoragePath)
            ?? panic("Pizza doesn't exist!")

        log("This pizza was ordered:")
        log(pizza.toString())

        acct.save(<-pizza, to: BestPizzaPlace.PizzaStoragePath)
    }
}