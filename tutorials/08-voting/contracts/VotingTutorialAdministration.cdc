/*
*
*   In this example, we want to create a simple voting contract
*   where a polling place issues ballots to addresses.
*
*   The run a vote, the Admin deploys the smart contract,
*   then adds the proposals. Further proposals can be added later.
*
*   Users can create ballots and vote only with their 
*   VotingTutorialGovernanceToken balance prior to when a proposal was created.
*
*   Every user with a ballot is allowed to approve their chosen proposals.
*   A user can choose their votes and cast them
*   with the tx_05_SelectAndCastVotes.cdc transaction.
*/

import VotingTutorialGovernanceToken from "./VotingTutorialGovernanceToken.cdc"

pub contract VotingTutorialAdministration {

    // dictionary of proposals to be approved
    pub var proposals: {Int : ProposalData}

    // paths
    pub let adminStoragePath: StoragePath
    pub let ballotStoragePath: StoragePath

    pub struct ProposalData {
        // the name of the proposal
        pub let name: String
        // possible options
        pub let options: [String]
        // when the proposal was created
        pub let blockTs: UFix64
        // the total votes per option, as represented by the accumulated balances of voters
        pub(set) var votes: {Int : UFix64}
        // used to record if a voter as represented by the vault id has already voted
        pub(set) var voters: {UInt64: Bool}

        init(name: String, options: [String], blockTs: UFix64) {
            self.name = name
            self.options = options
            self.blockTs = blockTs
            self.votes = {}
            for index, option in options {
                self.votes[index] = 0.0
            }
            self.voters = {}
        }
    }

    pub resource interface Votable {
        pub vaultId: UInt64
        pub votingWeightDataSnapshot: [VotingTutorialGovernanceToken.VotingWeightData]

        pub fun vote(proposalId: Int, optionId: Int){
            pre {
                VotingTutorialAdministration.proposals[proposalId] != nil: "Cannot vote for a proposal that doesn't exist"
                VotingTutorialAdministration.proposals[proposalId]!.voters[self.vaultId] == nil: "Cannot cast vote again using same Governance Token Vault"
                optionId < VotingTutorialAdministration.proposals[proposalId]!.options.length: "This option does not exist"
                self.votingWeightDataSnapshot != nil && self.votingWeightDataSnapshot.length > 0: "Can only vote if balance exists"
                self.votingWeightDataSnapshot[0].blockTs < VotingTutorialAdministration.proposals[proposalId]!.blockTs: "Can only vote if balance was recorded before proposal was created"
            }
        }
    }

    // This is the resource that is issued to users.
    // When a user gets a Ballot resource, they call the `vote` function
    // to include their votes
    pub resource Ballot: Votable {
        // id of VotingTutorialGovernanceToken Vault
        pub let vaultId: UInt64
        // array of VotingTutorialGovernanceToken Vault's votingWeightDataSnapshot
        pub let votingWeightDataSnapshot: [VotingTutorialGovernanceToken.VotingWeightData]


        init(recipientCap: Capability<&VotingTutorialGovernanceToken.Vault{VotingTutorialGovernanceToken.VotingWeight}>) {
            let recipientRef = recipientCap.borrow() ?? panic("Could not borrow VotingWeight reference from the Capability")

            self.vaultId = recipientRef.vaultId
            self.votingWeightDataSnapshot = recipientRef.votingWeightDataSnapshot
        }

        // Tallies the vote to indicate which proposal the vote is for
        pub fun vote(proposalId: Int, optionId: Int) {
            var votingWeight: VotingTutorialGovernanceToken.VotingWeightData = self.votingWeightDataSnapshot[0]

            for votingWeightData in self.votingWeightDataSnapshot {
                if votingWeightData.blockTs <= VotingTutorialAdministration.proposals[proposalId]!.blockTs {
                    votingWeight = votingWeightData
                } else {
                    break
                }
            }

            let proposalData = VotingTutorialAdministration.proposals[proposalId]!
            proposalData.votes[optionId] = proposalData.votes[optionId]! + votingWeight.vaultBalance
            proposalData.voters[self.vaultId] = true
            VotingTutorialAdministration.proposals.insert(key: proposalId, proposalData)
        }
    }

    // Resource that the Administrator of the vote controls to
    // initialize the proposals and to pass out ballot resources to voters
    pub resource Administrator {

        // function to initialize all the proposals for the voting
        pub fun addProposals(_ proposals: {Int : ProposalData}) {
            pre {
                proposals.length > 0: "Cannot add empty proposals data"
            }
            for key in proposals.keys {
                if (VotingTutorialAdministration.proposals[key] != nil) {
                    panic("Proposal with this key already exists")
                }
                VotingTutorialAdministration.proposals[key] = proposals[key]
            }
        }

    }

    // Creates a new Ballot
    pub fun issueBallot(recipientCap: Capability<&VotingTutorialGovernanceToken.Vault{VotingTutorialGovernanceToken.VotingWeight}>): @Ballot {
        return <-create Ballot(recipientCap: recipientCap)
    }

    // initializes the contract by setting the proposals and votes to empty
    // and creating a new Admin resource to put in storage
    init() {
        self.proposals = {}

        self.ballotStoragePath = /storage/CadenceVotingTutorialBallotStoragePath
        self.adminStoragePath = /storage/CadenceVotingTutorialAdminStoragePath

        self.account.save<@Administrator>(<-create Administrator(), to: self.adminStoragePath)
    }
}
