---
title: 10. Composable Resources
---

In this tutorial, we're going to demonstrate how resources can own other resources
and how this unique feature of Cadence opens up powerful possibilities for
how smart contracts and their ecosystems can be structured.

We will also see how a struct can be used in order to show the content of a resource without moving the resource itself, and how a private capability allows for restricted access.

---

The fact that resources can be nested (owned) into other resources is one of the cornerstones of the
composability which the Flow blockchain provides.

{TODO: More general examples of why resources owning resources is powerful, including mentioning
ones that we've already talked about in the tutorials like collections holding NFTs,
and any potential examples from the voting tutorials}

To illustrate how this feature works on Flow, we are going to work with a simple example, 
a pizza that is modeled as a resource and contains ingredients, which are also resources.

Here are the steps we will go through in order to build a great pizza with our resources:  

1. Learn about and deploy the `BestPizzaPlace` contract, which defines the Pizza, Dough,
Sauce and Topping resources.
2. Create an account for the customer.
3. Create a Pizza with Sauce and store it in the emulator-account.
4. Add multiple Toppings to the Pizza.
5. Get the Pizza ingredient description without moving the resource.

If you haven't yet followed the [Voting Tutorial](https://developers.flow.com/cadence/tutorial/09-voting), 
please do that now.
That tutorial gives an introduction to the `CLI` and shows how to install it and run simple
commands for smart contract development, so it's better to finish it before starting with this tutorial.

{TODO: If we decide to use the NFT standard, also remind them to get familiar with that standard}

You will also need a local copy of the tutorials code, which you should have downloaded 
in the voting tutorial.  
If not, please download the project in the terminal by executing 
`git clone git@github.com:onflow/flow-playground-tutorials.git`, and then go to the 
project folder: `cd flow-playground-tutorials/tutorials/08-resource-compose`.  

## What does it mean for a resource to own another resource?

{TODO: Explain this here, a resource can define any type as a field, including another resource,
this means that the resource effectively OWNS and controls the other resource. If the
parent resource is moved, the other resource is also moved. This is better than the alternative
where you would have a separate contract that has a ledger that tracks which resources own other resources
which can easily be hacked, get out of sync, and doesn't provide any nice functionality to
access the owned objects directly through the resources. It further reinforces that representation
of assets on chain should intuitively be similar to how they are in real life. In real life,
a human owns a wallet that has cash in it. If the wallet is moved to another location, the cash
moves with it without the owner needing to do anything else like updating a different ledger
that tracks where the cash is. Expand even more on this and other similar examples.
Get the reader excited about these kind of possibilities and what it can mean for their smart contract}

{TODO: Transition into how this can be used to represent a pizza owning ingredients}

## Pizza Shop Smart Contract

As you can see, all logic is contained in only one contract, `BestPizzaPlace.cdc`. 
Let's break down the content of the contract into pieces: There is a resource interface 
called `Ingredient`:

```cadence
/// Ingredient
///
/// This resource interface simply says that something is an ingredient with a name
pub resource interface Ingredient {
    pub name: String
}
```

It just contains a name, and then three resources implement this interface: 
`Dough`, `Sauce` and `Topping`. They all contain additional data, but the unifying aspect 
is that they each have a name.  

Two [enumerations](https://developers.flow.com/cadence/language/enumerations) are used, 
`Spiciness` for the sauce, and `Grain` for the dough:  

```cadence
/// Used for the sauce
pub enum Spiciness: UInt8 {
    pub case mild
    pub case medium
    pub case hot
}
```

```cadence
/// Used for the Dough
pub enum Grain: UInt8 {
    pub case wheat
    pub case rye
    pub case spelt
}
```

While the `Ingredient` resource interface specified which data implementing resources must 
contain, the other two resource interfaces in the contract, `AddTopping` and `ShowOrder`, 
specify which function must be defined: 

```cadence
/// AddTopping
///
/// This resource interface signifies that you can add a topping
pub resource interface AddTopping {
    pub fun addTopping(topping: @Topping)
}
```

```cadence
/// ShowOrder
///
/// This resource interface signifies that you can show the order
pub resource interface ShowOrder {
    pub fun showOrder(): Order
}
```

As the `Pizza` resource implements them both, 
it defines the functions `addTopping`, which takes a `Topping` resource, and `showOrder`, 
which returns the `Order` struct.  
As only the cook (aka the AuthAccount) should be allowed to add toppings, 
the capability for this action is declared as private by being linked 
in the first transaction to the private path.  
But as the guest and everyone else is allowed to check the order, 
the resource type `ShowOrder` is linked in the same transaction to the public path, 
so that the `Order` struct can be accessed by everyone. This is modeled after the 
[design pattern 'Script-Accessible report'](https://developers.flow.com/cadence/design-patterns#script-accessible-report). 
This is the implementation of the `Order` struct:

```cadence
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
```

There are two participants, the customer and the cook. The customer is only allowed to 
review the order, while the cook can add toppings. This separation is enabled through the 
use of both a public and a private capability and also a struct. Private capabilities can 
only be accessed from authorized accounts, please take a look at the [documentation](https://developers.flow.com/cadence/language/capability-based-access-control).  

## Preparation

<Callout type="info">
This time, the emulator configuration file `flow.json`is already provided, 
so you can run the emulator right ahead: 
```console
flow emulator
```
</Callout>

<Callout type="info">
Then, open another terminal window and deploy the project, 
which is composed of just one contract: 
```console
flow project deploy
```
</Callout>

This will deploy the BestPizzaPlace contract, shown here completely:
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
        /// thereby obviates the need for moving the Pizza resource
        pub fun showOrder(): Order {
            let toppingNames: [String] = []
            //iteration is a bit special because of https://github.com/onflow/cadence/issues/704
            var i = 0
            while i < self.toppings.length {
              let toppingRef = &self.toppings[i] as &Topping
              toppingNames.append(toppingRef.name)
              i = i + 1
            }
            return Order(pizzaName: self.name, dough: self.dough.name, timeToBake: self.dough.timeToBake, 
                sauceType: self.sauce.name, spiciness: self.sauce.getSpiciness(), toppings: toppingNames)
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

Repeating and adding to the remarks above, please take notice of these critical aspects 
of the BestPizzaPlace contract:

1. The `destroy()` function of the Pizza resource calls `destroy()` on all contained resources
2. The `Order` struct which will be used to display the Pizza ingredients
3. We're creating a public and a private capability path, the latter can only be accessed by the cook who created the pizza with the first transaction

But let's go on with the next step.

## Create a customer account

<Callout type="info">
As already practiced in the [Voting Tutorial](https://developers.flow.com/cadence/tutorial/09-voting), 
please enter this command for the creation of a new account:  

```console
flow accounts create
```

Please choose the name 'customer' and then the option *Local Emulator*.
</Callout>

This time, no further action for the account is required, as a normal account without any 
vault in storage suffices.

## Prepare the Pizza

The next transaction will create a Pizza with Sauce and store it in the emulator-account.  
Also, the aforementioned public and private capability paths are published.  
This is the content of the transaction:  

```cadence:title=tx01_PreparePizza.cdc
import BestPizzaPlace from 0xf8d6e0586b0a20c7

// This transaction creates a pizza resource and moves it to the account storage.
// It also creates a private capability that allows to add toppings and a public capability
// which allows to check the order later.
transaction {
    let authAccount: AuthAccount

    prepare(acct: AuthAccount) {
        let dough <- BestPizzaPlace.createDough(grain: BestPizzaPlace.Grain.wheat, timeToBake: 20)
        let sauce <- BestPizzaPlace.createSauce(name: "Tomato sauce", spiciness: BestPizzaPlace.Spiciness.hot)

        let pizza <- BestPizzaPlace.createPizza(name: "Bufalina", dough: <-dough, sauce: <-sauce)

        // Store the pizza
        acct.save<@BestPizzaPlace.Pizza>(<-pizza, to: BestPizzaPlace.PizzaStoragePath)
        // Link capability references
        acct.link<&AnyResource{BestPizzaPlace.AddTopping}>(BestPizzaPlace.PizzaAddToppingPrivatePath, 
            target: BestPizzaPlace.PizzaStoragePath)
        acct.link<&AnyResource{BestPizzaPlace.ShowOrder}>(BestPizzaPlace.PizzaShowOrderPublicPath, 
            target: BestPizzaPlace.PizzaStoragePath)

        self.authAccount = acct
        log("Pizza will be prepared!")
    }

    post {
        // Check that the capabilities were created correctly
       self.authAccount.getCapability<&AnyResource{BestPizzaPlace.AddTopping}>(BestPizzaPlace.PizzaAddToppingPrivatePath)
       .check():
         "Pizza AddTopping Reference was not created correctly"
        
        self.authAccount.getCapability<&AnyResource{BestPizzaPlace.ShowOrder}>(BestPizzaPlace.PizzaShowOrderPublicPath)
       .check():
         "Pizza ShowOrder Reference was not created correctly"
    }
}
````

<Callout type="info">
In order to execute it, please run:  

```console
flow transactions send transactions/tx01_PreparePizza.cdc --signer emulator-account
```
</Callout>

## Add Toppings

Notice that only the emulator-account can add toppings, as he is the one who executed the 
previous transaction. If the customer tries to add toppings, the transaction will fail.  

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
        // Baking happening in between ;-)
        self.addToppingRef.addTopping(topping: <-topping2)

        log("Toppings added!")
    }
}
```

<Callout type="info">
Try to execute this transaction by calling:

```console
flow transactions send transactions/tx02_AddToppings.cdc --signer customer
```

As you can see in the emulator window, this will result in the following error log:

```console
"Could not borrow reference for adding toppings, only the cook can add toppings."
```
</Callout>

<Callout type="info">
So make sure to call it with the same account you were using for the first transaction:

```console
flow transactions send transactions/tx02_AddToppings.cdc --signer emulator-account
```
</Callout>

## Check the order

<Callout type="info">
Finally, the order can be inspected by everyone, 
as a public capability was created in the first transaction:

```console
flow scripts execute scripts/ShowOrder.cdc
```
</Callout>
---

The above is a simple example of composable resources. We saw that we need to take care of 
calling `destroy()` on all contained resources, and that structs can be used to hand over 
the content of a resource without moving the resource itself.  
We also saw how a private capability restricts access to a resource whereas 
a public capability allows access for everyone.
