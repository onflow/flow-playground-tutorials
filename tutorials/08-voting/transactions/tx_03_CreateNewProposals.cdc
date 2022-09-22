// CreateNewProposals

import VotingTutorialAdministration from 0xf8d6e0586b0a20c7

/// This transaction allows the administrator of the VotingTutorialAdministration contract
/// to create new proposals for voting and save them to the smart contract
transaction {
    prepare(admin: AuthAccount) {

        /// A reference to the admin Resource
        let adminRef = admin.borrow<&VotingTutorialAdministration.Administrator>(from: VotingTutorialAdministration.adminStoragePath)!

        let ts = getCurrentBlock().timestamp
        let food = ["Pizza", "Spaghetti", "Pancake"]
        let proposal1 = VotingTutorialAdministration.ProposalData(name: "What's up for dinner?", options: food, blockTs: ts)
        let oneChoice = ["Yes", "No"]
        let proposal2 = VotingTutorialAdministration.ProposalData(name: "Let's throw a party!", options: oneChoice, blockTs: ts)
        let proposals = {0 : proposal1, 1 : proposal2}

        // Call the addProposals function to create the dictionary of ProposolData
        adminRef.addProposals(proposals)

        log("Proposals added!")
    }

    post {
        VotingTutorialAdministration.proposals.length == 2
    }

}