import VotingTutorialAdministration from "./../contracts/VotingTutorialAdministration.cdc"

pub fun main(): {Int : VotingTutorialAdministration.ProposalData} {
    return VotingTutorialAdministration.proposals
}