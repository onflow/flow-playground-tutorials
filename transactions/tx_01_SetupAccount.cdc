// Setup Account

import FungibleToken from 0xee82856bf20e2aa6
import GovernanceToken from 0xf8d6e0586b0a20c7

// This transaction configures an account to store and receive tokens defined by
// the ExampleToken contract.
transaction {
  let account: AuthAccount

	prepare(acct: AuthAccount) {

		// Create a new empty Vault object
		let vault <- GovernanceToken.createEmptyVault()

    // Store the vault in the account storage
		acct.save<@FungibleToken.Vault>(<-vault, to: GovernanceToken.VaultStoragePath)

    log("Empty Vault stored")

    // Link capability reference
		acct.link<&GovernanceToken.Vault{FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance, GovernanceToken.VotingWeight}>(GovernanceToken.VaultPublicPath, target: GovernanceToken.VaultStoragePath)

    self.account = acct
    log("GovernanceToken Receiver reference created")
	}

   post {
        // Check that the capabilities were created correctly
       getAccount(self.account.address).getCapability<&GovernanceToken.Vault{FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance, GovernanceToken.VotingWeight}>(GovernanceToken.VaultPublicPath)
       .check():
         "GovernanceToken Receiver Reference was not created correctly"
    }
}
