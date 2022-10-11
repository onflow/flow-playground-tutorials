/*
*   To run a vote, the Admin deploys the smart contract,
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

    /// Dictionary of proposals to be approved
    pub var proposals: {Int : ProposalData}

    /// Paths
    pub let adminStoragePath: StoragePath
    pub let ballotStoragePath: StoragePath

    /// ProposalData contains all the data concering a proposal,
    /// including the votes and a voter registry
    pub struct ProposalData {
        /// The name of the proposal
        pub let name: String
        /// Possible options
        pub let options: [String]
        /// When the proposal was created
        pub let blockTs: UFix64
        /// The total votes per option, as represented by the accumulated balances of voters
        pub(set) var votes: {Int : UFix64}
        /// Used to record if a voter as represented by the vault id has already voted
        pub(set) var voters: {UInt64: Bool}

        init(name: String, options: [String], blockTs: UFix64) {
            self.name = name
            self.options = options
            self.blockTs = blockTs
            self.votes = {}
            for index, option in options {
                /// Needed because we force unwrap later
                self.votes[index] = 0.0
            }
            self.voters = {}
        }
    }

    /// Votable
    ///
    /// Interface which keeps track of voting weight history and allows to cast a vote
    ///
    pub resource interface Votable {
        pub vaultId: UInt64
        pub votingWeightDataSnapshot: [VotingTutorialGovernanceToken.VotingWeightData]

        /// Here only some checks are done, the execution code is in the implementing resource
        pub fun vote(proposalId: Int, optionId: Int){
            pre {
                VotingTutorialAdministration.proposals[proposalId] != nil: "Cannot vote for a proposal that doesn't exist"
                VotingTutorialAdministration.proposals[proposalId]!.voters[self.vaultId] == nil: "Cannot cast vote again using same Governance Token Vault"
                optionId < VotingTutorialAdministration.proposals[proposalId]!.options.length: "This option does not exist"
                self.votingWeightDataSnapshot.length > 0: "Can only vote if balance exists"
                self.votingWeightDataSnapshot[0].blockTs < VotingTutorialAdministration.proposals[proposalId]!.blockTs: "Can only vote if balance was recorded before proposal was created"
            }
        }
    }

    /// Ballot
    ///
    /// This is the resource that is issued to users.
    /// When a user gets a Ballot resource, they call the `vote` function
    /// to include their vote.
    ///
    pub resource Ballot: Votable {
        /// Id of VotingTutorialGovernanceToken Vault
        pub let vaultId: UInt64
        /// Array of VotingTutorialGovernanceToken Vault's votingWeightData
        pub let votingWeightDataSnapshot: [VotingTutorialGovernanceToken.VotingWeightData]

        /// Borrows the Vault capability in order to set both the vault id and the VotingWeightData history
        init(recipientCap: Capability<&VotingTutorialGovernanceToken.Vault{VotingTutorialGovernanceToken.VotingWeight}>) {
            let recipientRef = recipientCap.borrow() ?? panic("Could not borrow VotingWeight reference from the Capability")

            self.vaultId = recipientRef.vaultId
            self.votingWeightDataSnapshot = recipientRef.votingWeightDataSnapshot
        }

        /// Adds the last recorded voter balance before proposal creation 
        /// to the chosen proposal and option
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

    /// Administrator
    ///
    // The Administrator resource allows to add proposals
    pub resource Administrator {

        /// addProposals initializes all the proposals for the voting
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

    /// issueBallot creates a new Ballot
    pub fun issueBallot(recipientCap: Capability<&VotingTutorialGovernanceToken.Vault{VotingTutorialGovernanceToken.VotingWeight}>): @Ballot {
        return <-create Ballot(recipientCap: recipientCap)
    }

    /// Initializes the contract by setting empty proposals,
    /// assigning the paths and creating a new Admin resource and saving it in account storage
    init() {
        self.proposals = {}

        self.ballotStoragePath = /storage/CadenceVotingTutorialBallotStoragePath
        self.adminStoragePath = /storage/CadenceVotingTutorialAdminStoragePath

        self.account.save<@Administrator>(<-create Administrator(), to: self.adminStoragePath)
    }
}
