// CreateSale.cdc

import ExampleToken from 0x01
import ExampleNFT from 0x02
import ExampleMarketplace from 0x03

// This transaction creates a new Sale Collection object,
// lists an NFT for sale, puts it in account storage,
// and creates a public capability to the sale so that others can buy the token.
transaction {

    prepare(acct: AuthAccount) {

        // Borrow a reference to the stored Vault
        let receiver = acct.getCapability<&{ExampleToken.Receiver}>(/public/CadenceFungibleTokenTutorialReceiver)

        // borrow a reference to the nftTutorialCollection in storage
        let collectionCapability = acct.link<&ExampleNFT.Collection>(/private/nftTutorialCollection, target: ExampleNFT.CollectionStoragePath)
          ?? panic("Unable to create private link to NFT Collection")

        // Create a new Sale object,
        // initializing it with the reference to the owner's vault
        let sale <- ExampleMarketplace.createSaleCollection(ownerCollection: collectionCapability, ownerVault: receiver)

        // List the token for sale by moving it into the sale object
        sale.listForSale(tokenID: 1, price: 10.0)

        // Store the sale object in the account storage
        acct.save(<-sale, to: /storage/NFTSale)

        // Create a public capability to the sale so that others can call its methods
        acct.link<&ExampleMarketplace.SaleCollection{ExampleMarketplace.SalePublic}>(/public/NFTSale, target: /storage/NFTSale)

        log("Sale Created for account 1. Selling NFT 1 for 10 tokens")
    }
}

