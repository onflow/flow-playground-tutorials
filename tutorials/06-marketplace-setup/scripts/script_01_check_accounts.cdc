// CheckSetupScript.cdc

import ExampleToken from 0x01
import ExampleNFT from 0x02

// This script checks that the accounts are set up correctly for the marketplace tutorial.
//
// Account 0x01: Vault Balance = 40, NFT.id = 1
// Account 0x02: Vault Balance = 20, No NFTs
pub fun main() {
    // Get the accounts' public account objects
    let acct1 = getAccount(0x01)
    let acct2 = getAccount(0x02)

    // Get references to the account's receivers
    // by getting their public capability
    // and borrowing a reference from the capability
    let acct1ReceiverRef = acct1.getCapability(/public/CadenceFungibleTokenTutorialReceiver)
                          .borrow<&ExampleToken.Vault{ExampleToken.Balance}>()
                          ?? panic("Could not borrow acct1 vault reference")

    let acct2ReceiverRef = acct2.getCapability(/public/CadenceFungibleTokenTutorialReceiver)
                          .borrow<&ExampleToken.Vault{ExampleToken.Balance}>()
                          ?? panic("Could not borrow acct2 vault reference")

    // Log the Vault balance of both accounts and ensure they are
    // the correct numbers.
    // Account 0x01 should have 40.
    // Account 0x02 should have 20.
    log("Account 1 Balance")
    log(acct1ReceiverRef.balance)
    log("Account 2 Balance")
    log(acct2ReceiverRef.balance)

    // verify that the balances are correct
    if acct1ReceiverRef.balance != 40.0 || acct2ReceiverRef.balance != 20.0 {
        panic("Wrong balances!")
    }

    // Find the public Receiver capability for their Collections
    let acct1Capability = acct1.getCapability(ExampleNFT.CollectionPublicPath)
    let acct2Capability = acct2.getCapability(ExampleNFT.CollectionPublicPath)

    // borrow references from the capabilities
    let nft1Ref = acct1Capability.borrow<&{ExampleNFT.NFTReceiver}>()
        ?? panic("Could not borrow acct1 nft collection reference")

    let nft2Ref = acct2Capability.borrow<&{ExampleNFT.NFTReceiver}>()
        ?? panic("Could not borrow acct2 nft collection reference")

    // Print both collections as arrays of IDs
    log("Account 1 NFTs")
    log(nft1Ref.getIDs())

    log("Account 2 NFTs")
    log(nft2Ref.getIDs())

    // verify that the collections are correct
    if nft1Ref.getIDs()[0] != 1 || nft2Ref.getIDs().length != 0 {
        panic("Wrong Collections!")
    }
}
