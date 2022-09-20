/*
*   This is an example on how to compose resources.
*   It shows the need for implementing the 'destroy' method and for calling it.
*   It also allows to get information about the pizza ingredients without moving the resource.
*/
pub contract BestPizzaPlace {

    // paths
    pub let PizzaStoragePath: StoragePath
    pub let PizzaPublicPath: PublicPath

    pub resource interface Ingredient {
        pub name: String
    }

    // used for the sauce
    pub enum Spiciness: UInt8 {
      pub case mild
      pub case medium
      pub case hot
    }

    pub resource Sauce: Ingredient {
        pub let name: String
        pub let spiciness: Spiciness

        init(name: String, spiciness: Spiciness) {
            self.name = name
            self.spiciness = spiciness
        }

        pub fun getSpiciness(): String {
            let spicinessPossibilities = {Spiciness.mild : "mild", Spiciness.medium : "medium", Spiciness.hot : "hot"}
            let spicinessString: String = spicinessPossibilities[self.spiciness]!
            return spicinessString
        }
    }

    pub fun createSauce(name: String, spiciness: Spiciness): @Sauce {
        return <-create Sauce(name: name, spiciness: spiciness)
    }

    pub resource Topping: Ingredient {
        pub let name: String
        pub let addBeforeBaking: Bool

        init(name: String, addBeforeBaking: Bool) {
            self.name = name
            self.addBeforeBaking = addBeforeBaking
        }
    }

    pub fun createTopping(name: String, addBeforeBaking: Bool): @Topping {
        return <-create Topping(name: name, addBeforeBaking: addBeforeBaking)
    }

    pub enum Grain: UInt8 {
      pub case wheat
      pub case rye
      pub case spelt
    }

    pub resource Dough: Ingredient {
        pub let name: String
        pub let timeToBake: UInt

        init(name: String, timeToBake: UInt) {
            self.name = name
            self.timeToBake = timeToBake
        }
    }

    pub fun createDough(grain: Grain, timeToBake: UInt): @Dough {
        let doughNames = {Grain.wheat: "wheat dough", Grain.rye : "rye dough", Grain.spelt : "spelt dough"}
        let name: String = doughNames[grain]!
        return <-create Dough(name: name, timeToBake: timeToBake)
    }

    pub resource Pizza {
        pub let name: String
        pub let dough: @Dough
        pub let sauce: @Sauce
        pub let toppings: @[Topping]

        init(name: String, dough: @Dough, sauce: @Sauce) {
            self.name = name
            self.dough <- dough
            self.sauce <- sauce
            self.toppings <- []
        }

        pub fun addTopping(topping: @Topping) {
           self.toppings.append(<- topping)
        }

        pub fun showOrder(): Order {
            let toppingNames: [String] = []
            //iteration is a bit special because of https://github.com/onflow/cadence/issues/704
            var i = 0
            while i < self.toppings.length {
              let toppingRef = &self.toppings[i] as &Topping
              toppingNames.append(toppingRef.name)
              i = i + 1
            }
            return Order(pizzaName: self.name, dough: self.dough.name, timeToBake: self.dough.timeToBake, sauceType: self.sauce.name, spiciness: self.sauce.getSpiciness(), toppings: toppingNames)
        }

        destroy() {
            destroy self.dough
            destroy self.sauce
            destroy self.toppings
        }
    }

    pub fun createPizza(name: String, dough: @Dough, sauce: @Sauce): @Pizza {
        return <-create Pizza(name: name, dough: <-dough, sauce: <-sauce)
    }

    // used to inform about the pizza ingredients
    pub struct Order {
        pub var pizzaName: String
        pub var dough: String
        pub var timeToBake: UInt
        pub var sauceType: String
        pub var spiciness: String
        pub var toppings: [String]

        init(pizzaName: String, dough: String, timeToBake: UInt, sauceType: String, spiciness: String, toppings: [String]) {
            self.pizzaName = pizzaName
            self.dough = dough
            self.timeToBake = timeToBake
            self.sauceType = sauceType
            self.spiciness = spiciness
            self.toppings = toppings
        }
    }

    init() {
        self.PizzaStoragePath = /storage/CadenceResourceComposeTutorialPizzaStoragePath
        self.PizzaPublicPath = /public/CadenceResourceComposeTutorialPizzaPublicPath
    }
}