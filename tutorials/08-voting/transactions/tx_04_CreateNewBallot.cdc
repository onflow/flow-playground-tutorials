// CreateNewBallot

import VotingTutorialAdministration from 0xf8d6e0586b0a20c7
import VotingTutorialGovernanceToken from 0xf8d6e0586b0a20c7


// This transaction allows the voter with goverance token vault
// to create a new ballot and store it in a voter's account
transaction () {
    prepare(voter: AuthAccount) {

        // borrow a reference from the voter's VotingTutorialGovernanceToken Vault
        let vaultRef = voter.getCapability<&VotingTutorialGovernanceToken.Vault{VotingTutorialGovernanceToken.VotingWeight}>(VotingTutorialGovernanceToken.VaultPublicPath)

        // create a new Ballot by calling the issueBallot function
        let ballot <- VotingTutorialAdministration.issueBallot(recipientCap: vaultRef)

        // store that ballot in the voter's account storage
        voter.save<@VotingTutorialAdministration.Ballot>(<-ballot, to: VotingTutorialAdministration.ballotStoragePath)

        log("Ballot transferred to voter")
    }
}
