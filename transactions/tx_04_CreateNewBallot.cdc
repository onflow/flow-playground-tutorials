// CreateNewBallot

import Voting from 0xf8d6e0586b0a20c7
import GovernanceToken from 0xf8d6e0586b0a20c7


// This transaction allows the voter with goverance token vault
// to create a new ballot and store it in a voter's account
transaction () {
    prepare(voter: AuthAccount) {

        //getAccount(self.account.address).getCapability<&GovernanceToken.Vault{FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance, //GovernanceToken.VotingWeight}>(GovernanceToken.VaultPublicPath)

        // borrow a reference from the voter's GovernanceToken Vault
        let vaultRef = voter.getCapability<&GovernanceToken.Vault{GovernanceToken.VotingWeight}>(GovernanceToken.VaultPublicPath)

        // create a new Ballot by calling the issueBallot function
        let ballot <- Voting.issueBallot(recipientCap: vaultRef)

        // store that ballot in the voter's account storage
        voter.save<@Voting.Ballot>(<-ballot, to: Voting.ballotStoragePath)

        log("Ballot transferred to voter")
    }
}
