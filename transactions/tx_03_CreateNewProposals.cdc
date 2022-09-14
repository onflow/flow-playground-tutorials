// CreateNewProposals

import Voting from 0xf8d6e0586b0a20c7

// This transaction allows the administrator of the Voting contract
// to create new proposals for voting and save them to the smart contract
transaction {
    prepare(admin: AuthAccount) {

        // borrow a reference to the admin Resource
        let adminRef = admin.borrow<&Voting.Administrator>(from: Voting.adminStoragePath)!

        let ts = getCurrentBlock().timestamp
        let proposal1 = Voting.ProposalData(name: "Longer Shot Clock", blockTs: ts)
        let proposal2 = Voting.ProposalData(name: "Trampolines instead of hardwood floors", blockTs: ts)
        
        // Call the initializeProposals function
        // to create the proposals array as an array of ProposolData
        adminRef.initializeProposals(
            [proposal1, proposal2]
        )

        log("Proposals Initialized!")
    }

    post {
        Voting.proposals.length == 2
    }

}