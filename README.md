10. Composable Resources
In this tutorial, we're going to walk through how resources can own other resources.

Resources owning other resources is a powerful feature in the world of blockchain and smart contracts. To showcase how this feature works on Flow, this tutorial will take you through these steps with a pizza resource composed of ingredient resources:

Deploy the Pizza, Dough, Sauce and Topping definitions to the emulator-account.
Create a Pizza with Sauce and multiple Topping and store it in your account.
Get the Pizza ingredient description without moving the resource.

Take these steps:

Run the emulator

```console
flow emulator
```
Deploy the project in another window
```console
flow project deploy
```

Prepare the pizza:
```console
flow transactions send transactions/PreparePizza.cdc --signer emulator-account
```

Check the order:
```console
flow scripts execute scripts/ShowOrder.cdc
```
