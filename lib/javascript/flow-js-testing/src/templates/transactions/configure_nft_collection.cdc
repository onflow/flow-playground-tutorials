import NonFungibleToken from 0x02

// This transaction configures a user's account
// to use the NFT contract by creating a new empty collection,
// storing it in their account storage, and publishing a capability
transaction {
    prepare(acct: AuthAccount) {

        // Create a new empty collection
        let collection <- NonFungibleToken.createEmptyCollection()

        // store the empty NFT Collection in account storage
        acct.save<@NonFungibleToken.Collection>(<-collection, to: /storage/{{collectionName}})

        log("Collection created")

        // create a public capability for the Collection
        acct.link<&{NonFungibleToken.NFTReceiver}>(/public/NFTReceiver, target: /storage/{{collectionName}})

        log("Capability created")
    }
}
