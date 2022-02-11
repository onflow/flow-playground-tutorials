// SetupAccount2Transaction.cdc

import ExampleToken from 0x01
import ExampleNFT from 0x02

// This transaction adds an empty Vault to account 0x02
// and mints an NFT with id=1 that is deposited into
// the NFT collection on account 0x01.
transaction {

  // Private reference to this account's minter resource
  let minterRef: &ExampleNFT.NFTMinter

  prepare(acct: AuthAccount) {
    // create a new vault instance with an initial balance of 30
    let vaultA <- ExampleToken.createEmptyVault()

    // Store the vault in the account storage
    acct.save<@ExampleToken.Vault>(<-vaultA, to: /storage/CadenceFungibleTokenTutorialVault)

    // Create a public Receiver capability to the Vault
    let ReceiverRef = acct.link<&ExampleToken.Vault{ExampleToken.Receiver, ExampleToken.Balance}>(/public/CadenceFungibleTokenTutorialReceiver, target: /storage/CadenceFungibleTokenTutorialVault)

    log("Created a Vault and published a reference")

    // Borrow a reference for the NFTMinter in storage
    self.minterRef = acct.borrow<&ExampleNFT.NFTMinter>(from: ExampleNFT.MinterStoragePath)
        ?? panic("Could not borrow owner's NFT minter reference")
  }
  execute {
    // Get the recipient's public account object
    let recipient = getAccount(0x01)

    // Get the Collection reference for the receiver
    // getting the public capability and borrowing a reference from it
    let receiverRef = recipient.getCapability(ExampleNFT.CollectionPublicPath)
                               .borrow<&{ExampleNFT.NFTReceiver}>()
                               ?? panic("Could not borrow nft receiver reference")

    // Mint an NFT and deposit it into account 0x01's collection
    receiverRef.deposit(token: <-self.minterRef.mintNFT())

    log("New NFT minted for account 1")
  }
}
