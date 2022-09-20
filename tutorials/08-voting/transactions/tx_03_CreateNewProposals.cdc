// CreateNewProposals

import Voting from 0xf8d6e0586b0a20c7

// This transaction allows the administrator of the Voting contract
// to create new proposals for voting and save them to the smart contract
transaction {
    prepare(admin: AuthAccount) {

        // borrow a reference to the admin Resource
        let adminRef = admin.borrow<&Voting.Administrator>(from: Voting.adminStoragePath)!

        let ts = getCurrentBlock().timestamp
        let food = ["Pizza", "Spaghetti", "Pancake"]
        let proposal1 = Voting.ProposalData(name: "What's up for dinner?", options: food, blockTs: ts)
        let oneChoice = ["Yes", "No"]
        let proposal2 = Voting.ProposalData(name: "Let's throw a party!", options: oneChoice, blockTs: ts)
        let proposals = {0 : proposal1, 1 : proposal2}

        // Call the initializeProposals function
        // to create the proposals array as an array of ProposolData
        adminRef.initializeProposals(proposals)

        log("Proposals Initialized!")
    }

    post {
        Voting.proposals.length == 2
    }

}