/*
*   This is an example on how to compose resources.
*   It shows the need for implementing the 'destroy' method and for calling it.
*   It also allows to get information about the pizza ingredients without moving the resource.
*/
pub contract BestPizzaPlace {

    /// Paths
    ///
    /// The pizza will be stored here via a transaction
    pub let PizzaStoragePath: StoragePath
    /// A capability which will allow to show the order will be linked under this path
    pub let PizzaPublicPath: PublicPath

    ///Ingredient
    ///
    /// This resource interface simply says that something is an ingredient with a name
    pub resource interface Ingredient {
        pub name: String
    }

    /// Used for the sauce
    pub enum Spiciness: UInt8 {
      pub case mild
      pub case medium
      pub case hot
    }

    /// Sauce
    ///
    /// The Sauce has a name and one of three spiciness levels
    pub resource Sauce: Ingredient {
        pub let name: String
        pub let spiciness: Spiciness

        /// Initializes the fields to the given arguments
        init(name: String, spiciness: Spiciness) {
            self.name = name
            self.spiciness = spiciness
        }

        /// getSpiciness informs about the level of spiciness
        pub fun getSpiciness(): String {
            let spicinessPossibilities = {Spiciness.mild : "mild", Spiciness.medium : "medium", Spiciness.hot : "hot"}
            let spicinessString: String = spicinessPossibilities[self.spiciness]!
            return spicinessString
        }
    }

    /// createSauce creates a Sauce resource with the given arguments
    pub fun createSauce(name: String, spiciness: Spiciness): @Sauce {
        return <-create Sauce(name: name, spiciness: spiciness)
    }

    /// Topping
    ///
    /// The Topping resource has a name and a flag which signifies if it should be added before or after baking
    pub resource Topping: Ingredient {
        pub let name: String
        pub let addBeforeBaking: Bool

        /// Initializes the fields to the given arguments
        init(name: String, addBeforeBaking: Bool) {
            self.name = name
            self.addBeforeBaking = addBeforeBaking
        }
    }

    /// createTopping creates a new Topping with the given arguments
    pub fun createTopping(name: String, addBeforeBaking: Bool): @Topping {
        return <-create Topping(name: name, addBeforeBaking: addBeforeBaking)
    }

    /// Used for the Dough
    pub enum Grain: UInt8 {
      pub case wheat
      pub case rye
      pub case spelt
    }

    /// Dough
    ///
    /// The Dough resource has a name and a number which signifies how many minutes it should bake
    pub resource Dough: Ingredient {
        pub let name: String
        pub let timeToBake: UInt

        /// Initializes the fields to the given arguments
        init(name: String, timeToBake: UInt) {
            self.name = name
            self.timeToBake = timeToBake
        }
    }

    /// createDough creates a new Dough with the given arguments
    pub fun createDough(grain: Grain, timeToBake: UInt): @Dough {
        let doughNames = {Grain.wheat: "wheat dough", Grain.rye : "rye dough", Grain.spelt : "spelt dough"}
        let name: String = doughNames[grain]!
        return <-create Dough(name: name, timeToBake: timeToBake)
    }

    /// Pizza
    ///
    /// The Pizza resource has a name and is made of one dough and one sauce, and possibly multiple toppings
    pub resource Pizza {
        pub let name: String
        pub let dough: @Dough
        pub let sauce: @Sauce
        pub let toppings: @[Topping]

        /// Initializes the fields to the given arguments
        init(name: String, dough: @Dough, sauce: @Sauce) {
            self.name = name
            self.dough <- dough
            self.sauce <- sauce
            self.toppings <- []
        }

        /// addTopping allows to add one topping at a time
        pub fun addTopping(topping: @Topping) {
           self.toppings.append(<- topping)
        }

        /// showOrder allows to view the order by returning an Order struct,
        /// thereby obviation the need for moving the Pizza resource
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

        /// destroy calls the destroy function on all contained resources
        destroy() {
            destroy self.dough
            destroy self.sauce
            destroy self.toppings
        }
    }

    /// createPizza creates a new Pizza with the given arguments
    pub fun createPizza(name: String, dough: @Dough, sauce: @Sauce): @Pizza {
        return <-create Pizza(name: name, dough: <-dough, sauce: <-sauce)
    }

    /// Order
    ///
    // A struct used to inform about the pizza ingredients
    pub struct Order {
        pub var pizzaName: String
        pub var dough: String
        pub var timeToBake: UInt
        pub var sauceType: String
        pub var spiciness: String
        pub var toppings: [String]

        /// Initializes the fields to the given arguments
        init(pizzaName: String, dough: String, timeToBake: UInt, sauceType: String, spiciness: String, toppings: [String]) {
            self.pizzaName = pizzaName
            self.dough = dough
            self.timeToBake = timeToBake
            self.sauceType = sauceType
            self.spiciness = spiciness
            self.toppings = toppings
        }
    }

    /// init assigns the contract paths
    init() {
        self.PizzaStoragePath = /storage/CadenceResourceComposeTutorialPizzaStoragePath
        self.PizzaPublicPath = /public/CadenceResourceComposeTutorialPizzaPublicPath
    }
}