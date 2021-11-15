// Basic Transfer

import BasicToken from 0x01

// This transaction is used to withdraw and deposit tokens with a Vault

transaction {

  prepare(acct: AuthAccount) {
    // withdraw tokens from your vault by borrowing a reference to it
    // and calling the withdraw function with that reference
    let vaultRef = acct.borrow<&BasicToken.Vault>(from: /storage/CadenceFungibleTokenTutorialVault)
        ?? panic("Could not borrow a reference to the owner's vault")

    let temporaryVault <- vaultRef.withdraw(amount: 10.0)

    // deposit your tokens to the Vault
    vaultRef.deposit(from: <-temporaryVault)

    log("Withdraw/Deposit succeeded!")
  }
}
