// SetupAccount1TransactionMinting.cdc

import ExampleToken from 0x01
import ExampleNFT from 0x02

// This transaction mints tokens for both accounts using
// the minter stored on account 0x01.
transaction {

  // Public Vault Receiver References for both accounts
  let acct1Capability: Capability<&AnyResource{ExampleToken.Receiver}>
  let acct2Capability: Capability<&AnyResource{ExampleToken.Receiver}>

  // Private minter references for this account to mint tokens
  let minterRef: &ExampleToken.VaultMinter

  prepare(acct: AuthAccount) {
    // Get the public object for account 0x02
    let account2 = getAccount(0x02)

    // Retrieve public Vault Receiver references for both accounts
    self.acct1Capability = acct.getCapability<&AnyResource{ExampleToken.Receiver}>(/public/CadenceFungibleTokenTutorialReceiver)

    self.acct2Capability = account2.getCapability<&AnyResource{ExampleToken.Receiver}>(/public/CadenceFungibleTokenTutorialReceiver)

    // Get the stored Minter reference for account 0x01
    self.minterRef = acct.borrow<&ExampleToken.VaultMinter>(from: /storage/CadenceFungibleTokenTutorialMinter)
        ?? panic("Could not borrow owner's vault minter reference")
  }

  execute {
    // Mint tokens for both accounts
    self.minterRef.mintTokens(amount: 20.0, recipient: self.acct2Capability)
    self.minterRef.mintTokens(amount: 10.0, recipient: self.acct1Capability)

    log("Minted new fungible tokens for account 1 and 2")
  }
}
