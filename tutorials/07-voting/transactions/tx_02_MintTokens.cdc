import FungibleToken from "../contracts/FungibleToken.cdc"
import VotingTutorialGovernanceToken from "../contracts/VotingTutorialGovernance.cdc"

// This transaction mints tokens and deposits them into the receivers account's vault
transaction (recipient1: Address, recipient2: Address, amountRecipient1: UFix64, amountRecipient2: UFix64) {

    // Local variable for storing the reference to the minter resource
    let mintingRef: &VotingTutorialGovernanceToken.VaultMinter

    // Local variables for storing the references to the Vaults of
    // the accounts that will receive the newly minted tokens
    var receiver1: Capability<&AnyResource{FungibleToken.Receiver}>
    var receiver2: Capability<&AnyResource{FungibleToken.Receiver}>

    prepare(acct: AuthAccount) {
        // Borrow a reference to the stored, private minter resource
        self.mintingRef = acct.borrow<&VotingTutorialGovernanceToken.VaultMinter>
            (from: VotingTutorialGovernanceToken.MinterStoragePath) ?? 
            panic("Could not borrow a reference to the minter")

        // Get the account objects
        let recipient1Account = getAccount(recipient1)
        let recipient2Account = getAccount(recipient2)

        // Get their public receiver capabilities
        self.receiver1 = recipient1Account.getCapability<&AnyResource{FungibleToken.Receiver}>
            (VotingTutorialGovernanceToken.VaultPublicPath)
        self.receiver2 = recipient2Account.getCapability<&AnyResource{FungibleToken.Receiver}>
            (VotingTutorialGovernanceToken.VaultPublicPath)
    }

    execute {
        // Mint tokens and deposit them into recipient1's Vault
        self.mintingRef.mintTokens(amount: amountRecipient1, recipient: self.receiver1)
        log("tokens minted and deposited to the vault of recipient1")
        // Mint tokens and deposit them into recipient2's Vault
        self.mintingRef.mintTokens(amount: amountRecipient2, recipient: self.receiver2)
        log("tokens minted and deposited to the vault of recipient2")
    }
}