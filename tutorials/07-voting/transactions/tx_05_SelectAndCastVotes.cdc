import VotingTutorialAdministration from "./../contracts/VotingTutorialAdministration.cdc"

// This transaction allows a voter to select a proposal via it's id and vote for it
transaction (proposalId: Int, optionId: Int) {
    prepare(voter: AuthAccount) {
        /// The Ballot of the voter
        let ballot <- voter.load<@VotingTutorialAdministration.Ballot>(from: VotingTutorialAdministration.ballotStoragePath)
            ?? panic("Could not load the voter's ballot")

        // Vote on the proposal and the option
        ballot.vote(proposalId: proposalId, optionId: optionId)

        // Destroy casted ballot
        destroy ballot

        log("Vote cast and tallied")
    }
}
 