// SetupAccount1Transaction.cdc

import ExampleToken from 0x01
import ExampleNFT from 0x02

// This transaction sets up account 0x01 for the marketplace tutorial
// by publishing a Vault reference and creating an empty NFT Collection.
transaction {
  prepare(acct: AuthAccount) {
    // Create a public Receiver capability to the Vault
    acct.link<&ExampleToken.Vault{ExampleToken.Receiver, ExampleToken.Balance}>
             (/public/CadenceFungibleTokenTutorialReceiver, target: /storage/CadenceFungibleTokenTutorialVault)

    log("Created Vault references")

    // store an empty NFT Collection in account storage
    acct.save<@ExampleNFT.Collection>(<-ExampleNFT.createEmptyCollection(), to: /storage/nftTutorialCollection)

    // publish a capability to the Collection in storage
    acct.link<&{ExampleNFT.NFTReceiver}>(ExampleNFT.CollectionPublicPath, target: ExampleNFT.CollectionStoragePath)

    log("Created a new empty collection and published a reference")
  }
}
