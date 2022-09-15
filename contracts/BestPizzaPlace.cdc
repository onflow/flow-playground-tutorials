pub contract BestPizzaPlace {

    pub let PizzaStoragePath: StoragePath

    init() {
        self.PizzaStoragePath = /storage/pizza
    }

    pub resource interface Ingredient {
        pub name: String

        pub fun toString(): String
    }

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

        pub fun toString(): String {
            let spicinessPossibilities = {Spiciness.mild : "mild", Spiciness.medium : "medium", Spiciness.hot : "hot"}
            let spicinessString: String = spicinessPossibilities[self.spiciness]!
            return spicinessString.concat(" ").concat(self.name)
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

        pub fun toString(): String {
             return self.name
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

        pub fun toString(): String {
             return self.name
        }
    }

    pub fun createDough(grain: Grain, timeToBake: UInt): @Dough {
        let doughNames = {Grain.wheat: "wheat dough", Grain.rye : "medirye dough", Grain.spelt : "spelt dough"}
        let name: String = doughNames[grain]!
        return <-create Dough(name: name, timeToBake: timeToBake)
    }

    pub resource Pizza {
        pub let name: String
        pub let ingredients: @[AnyResource{Ingredient}]

        init(name: String) {
            self.name = name
            self.ingredients <- []
        }

        pub fun addIngredient(newIngredient: @AnyResource{Ingredient}) {
           self.ingredients.append(<- newIngredient)
        }

        pub fun toString(): String {
            var description: String = "This is a ".concat(self.name).concat(" pizza")
            //iteration is a bit special because of https://github.com/onflow/cadence/issues/704
            var i = 0
            while i < self.ingredients.length {
              if(i == 0) {
                  description = description.concat(" with ")
              } else {
                  description = description.concat(" and ")
              }
              let ingredientRef = &self.ingredients[i] as &AnyResource{Ingredient}
              description = description.concat(ingredientRef.toString())
              i = i + 1
            }
            return description
        }

        destroy() {
            destroy self.ingredients
        }
    }

    pub fun createPizza(name: String): @Pizza {
        return <-create Pizza(name: name)
    }
}