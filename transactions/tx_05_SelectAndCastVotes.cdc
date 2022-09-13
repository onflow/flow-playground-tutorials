import Voting from 0xf8d6e0586b0a20c7
import VotingToken from 0xf8d6e0586b0a20c7

// Transaction3.cdc
//
// This transaction allows a voter to select the votes they would like to make
// and cast that vote by using the castVote function
// of the Voting smart contract

transaction {
    prepare(voter: AuthAccount) {

        // take the voter's ballot out of storage
        let vaultRef = voter.borrow<&VotingToken.Vault>(from: VotingToken.VaultStoragePath)
            ?? panic("Could not borrow a reference to the voter's vault")

        let ballot <- voter.load<@Voting.Ballot>(from: Voting.ballotStoragePath)
            ?? panic("Could not load the voter's ballot")

        log("vaultRef.votingPowerDataSnapshot:")
        log(vaultRef.votingPowerDataSnapshot)
        
        // Vote on the proposal
        //ballot.vote(proposal: 0, votingPowerDataSnapshot: vaultRef.votingPowerDataSnapshot)
        ballot.vote(proposal: 1, votingPowerDataSnapshot: vaultRef.votingPowerDataSnapshot)
        log("ballot choices:")
        log(ballot.choices)

        // Cast the vote by submitting it to the smart contract
        Voting.cast(ballot: <-ballot)

        log("Vote cast and tallied")
    }
}
