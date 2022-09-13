// Setup Account

import VotingToken from 0xf8d6e0586b0a20c7

// This transaction configures an account to store and receive tokens defined by
// the ExampleToken contract.
transaction {
  let account: AuthAccount

	prepare(acct: AuthAccount) {
    
		// Create a new empty Vault object
		let vaultA <- VotingToken.createEmptyVault()
		
    // Store the vault in the account storage
		acct.save<@VotingToken.Vault>(<-vaultA, to: VotingToken.VaultStoragePath)

    log("Empty Vault stored")

    // TODO
		acct.link<&VotingToken.Vault{VotingToken.Receiver, VotingToken.Balance, VotingToken.VotingPower}>(VotingToken.VaultPublicPath, target: VotingToken.VaultStoragePath)

    self.account = acct
    log("Public Vault Receiver reference created")
	}

   post {
        // Check that the capabilities were created correctly
       getAccount(self.account.address).getCapability<&VotingToken.Vault{VotingToken.Receiver, VotingToken.Balance, VotingToken.VotingPower}>(VotingToken.VaultPublicPath)
       .check():
         "Public Vault Receiver Reference was not created correctly"
    }
}
