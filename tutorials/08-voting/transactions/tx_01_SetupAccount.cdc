// Setup Account

import FungibleToken from 0xf8d6e0586b0a20c7
import VotingTutorialGovernanceToken from 0xf8d6e0586b0a20c7

/// This transaction configures an account to store and receive tokens defined by
/// the VotingTutorialGovernanceToken contract.
transaction {
  let account: AuthAccount

  prepare(acct: AuthAccount) {

    /// A new empty Vault object
    let vault <- VotingTutorialGovernanceToken.createEmptyVault()

    // Store the vault in the account storage
    acct.save<@FungibleToken.Vault>(<-vault, to: VotingTutorialGovernanceToken.VaultStoragePath)

    log("Empty Vault stored")

    // Link capability reference
    acct.link<&VotingTutorialGovernanceToken.Vault{FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance, VotingTutorialGovernanceToken.VotingWeight}>(VotingTutorialGovernanceToken.VaultPublicPath, target: VotingTutorialGovernanceToken.VaultStoragePath)

    self.account = acct
    log("VotingTutorialGovernanceToken Receiver reference created")
  }

   post {
        // Check that the capability was created correctly
       getAccount(self.account.address).getCapability<&VotingTutorialGovernanceToken.Vault{FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance, VotingTutorialGovernanceToken.VotingWeight}>(VotingTutorialGovernanceToken.VaultPublicPath)
       .check():
         "VotingTutorialGovernanceToken Receiver Reference was not created correctly"
    }
}
