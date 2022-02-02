// SetupAccount1TransactionMinting.cdc

import ExampleToken from 0x01
import ExampleNFT from 0x02

// This transaction mints tokens for both accounts using
// the minter stored on account 0x01.
transaction {

  // Public Vault Receiver References for both accounts
  let acct1Ref: &AnyResource{ExampleToken.Receiver}
  let acct2Ref: &AnyResource{ExampleToken.Receiver}

  // Private minter references for this account to mint tokens
  let minterRef: &ExampleToken.VaultMinter

  prepare(acct: AuthAccount) {
    // Get the public object for account 0x02
    let account2 = getAccount(0x02)

    // Retrieve public Vault Receiver references for both accounts
    self.acct1Ref = acct.getCapability(/public/CadenceFungibleTokenTutorialReceiver)!
                    .borrow<&ExampleToken.Vault{ExampleToken.Receiver}>()
                    ?? panic("Could not borrow owner's vault reference")

    self.acct2Ref = account2.getCapability(/public/CadenceFungibleTokenTutorialReceiver)!
                    .borrow<&ExampleToken.Vault{ExampleToken.Receiver}>()
                    ?? panic("Could not borrow acct2's vault reference")

    // Get the stored Minter reference for account 0x01
    self.minterRef = acct.borrow<&ExampleToken.VaultMinter>(from: /storage/MainMinter)
        ?? panic("Could not borrow owner's vault minter reference")
  }

  execute {
    // Mint tokens for both accounts
    self.minterRef.mintTokens(amount: UFix64(20), recipient: self.acct2Ref)
    self.minterRef.mintTokens(amount: UFix64(10), recipient: self.acct1Ref)

    log("Minted new fungible tokens for account 1 and 2")
  }
}
