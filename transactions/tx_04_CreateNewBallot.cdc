import Voting from 0xf8d6e0586b0a20c7

// Transaction2.cdc
//
// This transaction allows the administrator of the Voting contract
// to create a new ballot and store it in a voter's account
// The voter and the administrator have to both sign the transaction
// so it can access their storage

transaction () {
    prepare(admin: AuthAccount, voter: AuthAccount) {

        // borrow a reference to the admin Resource
        let adminRef = admin.borrow<&Voting.Administrator>(from: Voting.adminStoragePath)!

        // create a new Ballot by calling the issueBallot
        // function of the admin Reference
        let ballot <- adminRef.issueBallot()

        // store that ballot in the voter's account storage
        voter.save(<-ballot, to: Voting.ballotStoragePath)

        log("Ballot transferred to voter")
    }
}
