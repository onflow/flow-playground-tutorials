// Script1.cdc

import NonFungibleToken from 0x02

// Print the NFTs owned by account 0x02.
pub fun main() {
    // Get the public account object for account 0x02
    let nftOwner = getAccount(0x02)

    // Find the public Receiver capability for their Collection
    let capability = nftOwner.getCapability(/public/NFTReceiver)!

    // borrow a reference from the capability
    let receiverRef = capability.borrow<&{NonFungibleToken.NFTReceiver}>()
        ?? panic("Could not borrow the receiver reference")

    // Log the NFTs that they own as an array of IDs
    log("Account 2 NFTs")
    log(receiverRef.getIDs())
}
