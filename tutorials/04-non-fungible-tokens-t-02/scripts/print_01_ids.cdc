// Print 0x01 NFTs

import ExampleNFT from 0x01

// Print the NFTs owned by account 0x01.
pub fun main() {
    // Get the public account object for account 0x01
    let nftOwner = getAccount(0x01)

    // Find the public Receiver capability for their Collection
    let capability = nftOwner.getCapability<&{ExampleNFT.NFTReceiver}>(ExampleNFT.CollectionPublicPath)

    // borrow a reference from the capability
    let receiverRef = capability.borrow()
            ?? panic("Could not borrow receiver reference")

    // Log the NFTs that they own as an array of IDs
    log("Account 1 NFTs")
    log(receiverRef.getIDs())
}
