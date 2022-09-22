---
title: 10. Composable Resources
---

In this tutorial, we're going to walk through how resources can own other resources.
It also shows how to use a struct in order to show the resource content without moving the resource, and how to use a private capability in order to restrict access.

---

Resources owning other resources is a powerful feature in the world of blockchain and smart contracts. 
To showcase how this feature works on Flow, this tutorial will take you through these steps with a pizza resource composed of ingredient resources:

1. Deploy the project, which will add the Pizza, Dough, Sauce and Topping resource definitions to the emulator-account
2. Create an account for the customer
3. Create a Pizza with Sauce and store it in the emulator-account
4. Add multiple Toppings to the Pizza
5. Get the Pizza ingredient description without moving the resource

## Preparation

Run the emulator
```console
flow emulator
```

Deploy the project in another window
```console
flow project deploy
```

This will deploy the BestPizzaPlace contract:
```cadence:BestPizzaPlace.cdc
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
    /// A capability which will allow to add toppings will be linked under this path
    pub let PizzaAddToppingPrivatePath: PrivatePath
    /// A capability which will allow to show the order will be linked under this path
    pub let PizzaShowOrderPublicPath: PublicPath

    /// Ingredient
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

    /// AddTopping
    ///
    /// This resource interface signifies that you can add a topping
    pub resource interface AddTopping {
        pub fun addTopping(topping: @Topping)
    }

    /// ShowOrder
    ///
    /// This resource interface signifies that you can show the order
    pub resource interface ShowOrder {
        pub fun showOrder(): Order
    }

    /// Pizza
    ///
    /// The Pizza resource has a name and is made of one dough and one sauce, and possibly multiple toppings
    pub resource Pizza: AddTopping, ShowOrder {
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
        self.PizzaAddToppingPrivatePath = /private/CadenceResourceComposeTutorialPizzaPrivatePath
        self.PizzaShowOrderPublicPath = /public/CadenceResourceComposeTutorialPizzaPrivatePath
    }
}
```

Some important things to notice in the BestPizzaPlace contract:

1. The `destroy()` function of the Pizza resource calls `destroy()` on all contained resources
2. The `Order` struct which will be used to display the Pizza ingredients
3. We're creating a public and a private capability path, the latter can only be accessed by the cook who created the pizza with the first transaction

But let's go on with the next step.

## Create a customer account

```console
flow accounts create
```

In this tutorial, the name 'customer' is used.
When asked, choose the local blockchain.

## Prepare the Pizza

This will create a Pizza with Sauce and store it in the emulator-account.
Also, the aforementioned public and private capability paths are published.
This is the content of the transaction:

```cadence:title=tx01_PreparePizza.cdc
import BestPizzaPlace from 0xf8d6e0586b0a20c7

// This transaction creates a pizza resource and moves it to the account storage.
// It also creates a private capability that allows to add toppings and a public capability
// which allows to check the order later.
transaction {
    let account: AuthAccount

    prepare(acct: AuthAccount) {
        let dough <- BestPizzaPlace.createDough(grain: BestPizzaPlace.Grain.wheat, timeToBake: 20)
        let sauce <- BestPizzaPlace.createSauce(name: "Tomato sauce", spiciness: BestPizzaPlace.Spiciness.hot)

        let pizza <- BestPizzaPlace.createPizza(name: "Bufalina", dough: <-dough, sauce: <-sauce)

        // Store the pizza
        acct.save<@BestPizzaPlace.Pizza>(<-pizza, to: BestPizzaPlace.PizzaStoragePath)
        // Link capability references
        acct.link<&AnyResource{BestPizzaPlace.AddTopping}>(BestPizzaPlace.PizzaAddToppingPrivatePath, target: BestPizzaPlace.PizzaStoragePath)
        acct.link<&AnyResource{BestPizzaPlace.ShowOrder}>(BestPizzaPlace.PizzaShowOrderPublicPath, target: BestPizzaPlace.PizzaStoragePath)

        self.account = acct
        log("Pizza will be prepared!")
    }

    post {
        // TODO: results in failure
        // Check that the capabilities were created correctly
       /*getAccount(self.account.address).getCapability<&AnyResource{BestPizzaPlace.AddTopping}(BestPizzaPlace.PizzaAddToppingPrivatePath)
       .check():
         "Pizza AddTopping Reference was not created correctly"
        
        getAccount(self.account.address).getCapability<&AnyResource{BestPizzaPlace.ShowOrder}(BestPizzaPlace.PizzaShowOrderPublicPath)
       .check():
         "Pizza ShowOrder Reference was not created correctly"*/
    }
}
````

In order to execute it, run:

```console
flow transactions send transactions/tx01_PreparePizza.cdc --signer emulator-account
```

## Add Toppings

Notice that only the emulator-account can add toppings, as he is the one who executed the previous transaction.
If the customer tries to add toppings, the transaction will fail.

This is the transaction content:
```cadence:title=tx02_AddToppings.cdc
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
```

Try to execute this transaction by calling:

```console
flow transactions send transactions/tx02_AddToppings.cdc --signer customer
```

As you can see in the emulator window, this will result in the following error log :

```console
"Could not borrow reference for adding toppings, only the cook can add toppings."
```

So make sure to call it with the same account you were using for the first transaction:

```console
flow transactions send transactions/tx02_AddToppings.cdc --signer emulator-account
```

## Check the order

Finally, the order can be inspected by everyone, as a public capability was created in the first transaction:

```console
flow scripts execute scripts/ShowOrder.cdc
```
---

The above is a simple example of composable resources. We saw that we need to take care of calling `destroy()` on all contained resources, and that structs can be used to hand over the content of a resource without moving the resource itself.
We also saw how a private capability restricts access to a resource whereas a public capability allows access for everyone.