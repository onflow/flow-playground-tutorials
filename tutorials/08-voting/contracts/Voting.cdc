/*
*
*   In this example, we want to create a simple voting contract
*   where a polling place issues ballots to addresses.
*
*   The run a vote, the Admin deploys the smart contract,
*   then initializes the proposals.
*   The array of proposals cannot be modified after it has been initialized.
*
*   Users can create ballots and vote only with their GovernanceToken balance prior to when
*   proposal was created.
*
*   Every user with a ballot is allowed to approve their chosen proposals.
*   A user can choose their votes and cast them
*   with the tx_05_SelectAndCastVotes.cdc transaction.
*
*/

import GovernanceToken from "./GovernanceToken.cdc"

pub contract Voting {

    // list of proposals to be approved
    pub var proposals: [ProposalData]

    // paths
    pub let adminStoragePath: StoragePath
    pub let ballotStoragePath: StoragePath
    pub let ballotPublicPath: PublicPath

    pub struct ProposalData {
        pub let name: String
        pub let checkpoint: UInt16
        pub(set) var votes: UFix64
        pub(set) var voters: {UInt64: Bool}

        init(name: String) {
            self.name = name
            self.checkpoint = GovernanceToken.checkpointCounter
            self.votes = 0.0
            self.voters = {}
        }
    }

    pub resource interface Votable {
        pub vaultId: UInt64
        pub votingWeightDataSnapshot: [GovernanceToken.VotingWeightData]

        pub fun vote(proposalId: Int){
            pre {
                Voting.proposals[proposalId] != nil: "Cannot vote for a proposal that doesn't exist"
                Voting.proposals[proposalId].voters[self.vaultId] == nil: "Cannot cast vote again using same Governance Token Vault"
                self.votingWeightDataSnapshot != nil && self.votingWeightDataSnapshot.length > 0: "Can only vote if balance exists"
                self.votingWeightDataSnapshot[0].checkpoint < Voting.proposals[proposalId].checkpoint: "Can only vote if balance was recorded before proposal was created"
            }
        }
    }

    // This is the resource that is issued to users.
    // When a user gets a Ballot resource, they call the `vote` function
    // to include their votes
    pub resource Ballot: Votable {
        // id of GovernanceToken Vault
        pub let vaultId: UInt64
        // array of GovernanceToken Vault's votingWeightDataSnapshot
        pub let votingWeightDataSnapshot: [GovernanceToken.VotingWeightData]


        init(recipientCap: Capability<&GovernanceToken.Vault{GovernanceToken.VotingWeight}>) {
            let recipientRef = recipientCap.borrow() ?? panic("Could not borrow VotingWeight reference from the Capability")

            self.vaultId = recipientRef.vaultId
            self.votingWeightDataSnapshot = recipientRef.votingWeightDataSnapshot
        }

        // Tallies the vote to indicate which proposal the vote is for
        pub fun vote(proposalId: Int) {
            var votingWeight: GovernanceToken.VotingWeightData = self.votingWeightDataSnapshot[0]

            for votingWeightData in self.votingWeightDataSnapshot {
                if votingWeightData.checkpoint <= Voting.proposals[proposalId].checkpoint {
                    votingWeight = votingWeightData
                } else {
                    break
                }
            }

            Voting.proposals[proposalId].votes = Voting.proposals[proposalId].votes + votingWeight.vaultBalance
            Voting.proposals[proposalId].voters[self.vaultId] = true
        }
    }

    // Resource that the Administrator of the vote controls to
    // initialize the proposals and to pass out ballot resources to voters
    pub resource Administrator {

        // function to initialize all the proposals for the voting
        // TODO: allow to create proposals more than once
        pub fun initializeProposals(proposals: [String]) {
            pre {
                Voting.proposals.length == 0: "Proposals can only be initialized once"
                proposals.length > 0: "Cannot initialize with no proposals"
            }
            GovernanceToken.checkpointCounter = GovernanceToken.checkpointCounter + 1
            let newProposals: [ProposalData] = []
            for proposal in proposals {
                newProposals.append(ProposalData(name: proposal))
            }
            Voting.proposals = newProposals
        }
    }

    // Creates a new Ballot
    pub fun issueBallot(recipientCap: Capability<&GovernanceToken.Vault{GovernanceToken.VotingWeight}>): @Ballot {
        return <-create Ballot(recipientCap: recipientCap)
    }

    // initializes the contract by setting the proposals and votes to empty
    // and creating a new Admin resource to put in storage
    init() {
        self.proposals = []

        self.ballotStoragePath = /storage/Ballot
        self.adminStoragePath = /storage/VotingAdmin
        self.ballotPublicPath = /public/Ballot

        self.account.save<@Administrator>(<-create Administrator(), to: self.adminStoragePath)

        // Create a public capability to Voting.Ballot
        self.account.link<&Voting.Ballot>(self.ballotPublicPath, target: self.ballotStoragePath)
    }
}
