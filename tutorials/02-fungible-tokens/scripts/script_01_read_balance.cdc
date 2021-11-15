// Get Balances

import ExampleToken from 0x02

// This script reads the Vault balances of two accounts.
pub fun main() {
    // Get the accounts' public account objects
    let acct2 = getAccount(0x02)
    let acct3 = getAccount(0x03)

    // Get references to the account's receivers
    // by getting their public capability
    // and borrowing a reference from the capability
    let acct2ReceiverRef = acct2.getCapability(/public/CadenceFungibleTokenTutorialReceiver)
                            .borrow<&ExampleToken.Vault{ExampleToken.Balance}>()
                            ?? panic("Could not borrow a reference to the acct2 receiver")
    let acct3ReceiverRef = acct3.getCapability(/public/CadenceFungibleTokenTutorialReceiver)
                            .borrow<&ExampleToken.Vault{ExampleToken.Balance}>()
                            ?? panic("Could not borrow a reference to the acct3 receiver")

    // Use optional chaining to read and log balance fields
    log("Account 2 Balance")
	log(acct2ReceiverRef.balance)
    log("Account 3 Balance")
    log(acct3ReceiverRef.balance)
}
