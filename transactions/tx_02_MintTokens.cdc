// Mint Tokens

import VotingToken from 0xf8d6e0586b0a20c7

// This transaction mints tokens and deposits them into the receiver account's vault
transaction {

    // Local variable for storing the reference to the minter resource
    let mintingRef: &VotingToken.VaultMinter

    // Local variable for storing the reference to the Vault of
    // the account that will receive the newly minted tokens
    var receiver1: Capability<&VotingToken.Vault{VotingToken.Receiver}>
    var receiver2: Capability<&VotingToken.Vault{VotingToken.Receiver}>

    prepare(acct: AuthAccount) {
        // Borrow a reference to the stored, private minter resource
        self.mintingRef = acct.borrow<&VotingToken.VaultMinter>(from: VotingToken.MinterStoragePath)
            ?? panic("Could not borrow a reference to the minter")
        
        // Get the public account object for account 0x03
        let recipient1 = getAccount(0x01cf0e2f2f715450)
        let recipient2 = getAccount(0x179b6b1cb6755e31)

        // Get their public receiver capability
        self.receiver1 = recipient1.getCapability<&VotingToken.Vault{VotingToken.Receiver}>(VotingToken.VaultPublicPath)
        self.receiver2 = recipient2.getCapability<&VotingToken.Vault{VotingToken.Receiver}>(VotingToken.VaultPublicPath)
    }

    execute {
        // Mint 30 tokens and deposit them into the recipient's Vault
        self.mintingRef.mintTokens(amount: 30.0, recipient: self.receiver1)
        log("30 tokens minted and deposited to account 0x01cf0e2f2f715450")
        self.mintingRef.mintTokens(amount: 150.0, recipient: self.receiver2)
        log("15 tokens minted and deposited to account 0x179b6b1cb6755e31")
    }
}