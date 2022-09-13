/*
*
*   In this example, we want to create a simple approval voting contract
*   where a polling place issues ballots to addresses.
*
*   The run a vote, the Admin deploys the smart contract,
*   then initializes the proposals
*   using the initialize_proposals.cdc transaction.
*   The array of proposals cannot be modified after it has been initialized.
*
*   Then they will give ballots to users by
*   using the issue_ballot.cdc transaction.
*
*   Every user with a ballot is allowed to approve any number of proposals.
*   A user can choose their votes and cast them
*   with the cast_vote.cdc transaction.
*
*/

import VotingToken from "./VotingToken.cdc"

pub contract Voting {

    //list of proposals to be approved
    pub var proposals: [ProposalData]

    // sum weight of votes per proposal
    pub let votes: {Int: UFix64}

    pub let adminStoragePath: StoragePath
    pub let ballotStoragePath: StoragePath

    pub struct ProposalData {
        pub let name: String
        pub let blockTs: UFix64

        init(name: String, blockTs: UFix64) {
            self.name = name
            self.blockTs = blockTs
        }
    }

    // This is the resource that is issued to users.
    // When a user gets a Ballot object, they call the `vote` function
    // to include their votes, and then cast it in the smart contract
    // using the `cast` function to have their vote included in the polling
    pub resource Ballot {

        // array of all the proposals
        pub let proposals: [ProposalData]

        // corresponds to an array index in proposals after a vote
        pub var choices: {Int: Bool}

        // corresponds to an array index in proposals after a vote
        pub var choices2votingPower: {Int: UFix64}

        init() {
            self.proposals = Voting.proposals
            self.choices = {}
            self.choices2votingPower = {}

            // Set each choice to false
            var i = 0
            while i < self.proposals.length {
                self.choices[i] = nil
                self.choices2votingPower[i] = 0.0
                i = i + 1
            }
        }

        // modifies the ballot
        // to indicate which proposals it is voting for
        pub fun vote(proposal: Int, votingPowerDataSnapshot: [VotingToken.VotingPowerData]) {
            pre {
                self.proposals[proposal] != nil: "Cannot vote for a proposal that doesn't exist"
                votingPowerDataSnapshot != nil && votingPowerDataSnapshot.length > 0: "Can only vote if balance exists"
                votingPowerDataSnapshot[0].blockTs < self.proposals[proposal].blockTs: "Can only vote if balance was recorded before proposal was created"
            }
            var votingPower: VotingToken.VotingPowerData = votingPowerDataSnapshot[0]
            var i = 0
            while i < votingPowerDataSnapshot.length &&
                votingPowerDataSnapshot[i].blockTs < self.proposals[proposal].blockTs {
                votingPower = votingPowerDataSnapshot[i]
                i = i + 1
            }
            self.choices[proposal] = true
            self.choices2votingPower[proposal] = votingPower.vaultBalance
        }
    }

    // Resource that the Administrator of the vote controls to
    // initialize the proposals and to pass out ballot resources to voters
    pub resource Administrator {

        // function to initialize all the proposals for the voting
        pub fun initializeProposals(_ proposals: [ProposalData]) {
            pre {
                Voting.proposals.length == 0: "Proposals can only be initialized once"
                proposals.length > 0: "Cannot initialize with no proposals"
            }
            Voting.proposals = proposals

            // Set each tally of votes to zero
            var i = 0
            while i < proposals.length {
                Voting.votes[i] = 0.0
                i = i + 1
            }
        }

        // The admin calls this function to create a new Ballot
        // that can be transferred to another user
        pub fun issueBallot(): @Ballot {
            return <-create Ballot()
        }
    }

    // A user moves their ballot to this function in the contract where
    // its votes are tallied and the ballot is destroyed
    pub fun cast(ballot: @Ballot) {
        var index = 0
        // look through the ballot
        while index < self.proposals.length {
            if ballot.choices[index]! {
                // tally the vote if it is approved
                self.votes[index] = self.votes[index]! + ballot.choices2votingPower[index]!
            }
            index = index + 1;
        }
        // Destroy the ballot because it has been tallied
        destroy ballot
    }

    // initializes the contract by setting the proposals and votes to empty
    // and creating a new Admin resource to put in storage
    init() {
        self.proposals = []
        self.votes = {}
        self.adminStoragePath = /storage/VotingAdmin
        self.account.save<@Administrator>(<-create Administrator(), to: self.adminStoragePath)
        self.ballotStoragePath = /storage/Ballot
    }
}
