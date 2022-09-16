// SelectAndCastVotes

import Voting from 0xf8d6e0586b0a20c7
import GovernanceToken from 0xf8d6e0586b0a20c7

// This transaction allows a voter to select a proposal via its id and vote for it
transaction (proposalId: Int) {
    prepare(voter: AuthAccount) {
        let ballot <- voter.load<@Voting.Ballot>(from: Voting.ballotStoragePath)
            ?? panic("Could not load the voter's ballot")

        // Vote on the proposal
        ballot.vote(proposalId: proposalId,)

        // destroy resource
        destroy ballot

        log("Vote cast and tallied")
    }
}
