---
title: 9. Voting Contract
---

With the advent of blockchain technology and smart contracts,
it has become popular to try to create decentralized voting mechanisms that allow large groups of users to vote completely on chain.
This tutorial will provide a trivial example for how this might be achieved by using a resource-oriented programming model.
Two contracts will allow users to vote on multiple proposals while their voting power is determined by the balance of certain tokens.
The voting process is controlled by an administrator via the administration contract.

---
We'll take you through these steps to get comfortable with the voting contracts.

1. Deploy the contracts to the local blockchain emulator
2. Create two user accounts
3. Create voter accounts for these users
4. Mint tokens to these accounts
5. Create proposals for users to vote on
6. Create `Ballot` resources for both voters
7. Record and cast votes in the central voting contract
8. Read the results of the vote

## Setup the environment
Navigate in a terminal window to the voting tutorial dictionary and execute:

```console
flow init
```

Then, edit the configuration and add the contracts (also in the section `deployments`), it should look like this afterwards:

```json:title=flow.json
{
    "contracts": {
        "FungibleToken": "./contracts/FungibleToken.cdc",
        "VotingTutorialAdministration": "./contracts/VotingTutorialAdministration.cdc",
        "VotingTutorialGovernanceToken": "./contracts/VotingTutorialGovernanceToken.cdc"
    },
    //...networks, accounts...
    "deployments": {
        "emulator": {
            "emulator-account": [
                "FungibleToken",
                "VotingTutorialGovernanceToken",
                "VotingTutorialAdministration"
            ]
        }
    }
}
```

## Run the emulator

Once the configuration is saved, execute:

```console
flow emulator
```

## Deploy the project

Open another terminal window and execute

```console
flow project deploy
```

All three contracts should be deployed.
FungibleToken is a Cadence standard, while `VotingTutorialGovernanceToken` and `VotingTutorialAdministration` are specific to this tutorial.
`VotingTutorialGovernanceToken` is needed in order to vote, it's balance is determining the weight of vote.
`VotingTutorialAdministration` is used for administration of the whole voting process.

`VotingTutorialGovernanceToken` contains the usual vault functionality of the FungibleToken contract and adds a history of voting weight that is updated on each transfer.

```cadence:title=VotingTutorialGovernanceToken.cdc
/*
* The VotingTutorialGovernanceToken contract is a sample implementation 
* of a fungible token on Flow which can be used for voting.
*/

import FungibleToken from "./FungibleToken.cdc"

pub contract VotingTutorialGovernanceToken: FungibleToken {

    // Total supply of all tokens in existence.
    pub var totalSupply: UFix64

    // Paths
    pub let VaultStoragePath: StoragePath
    pub let MinterStoragePath: StoragePath
    pub let VaultPublicPath: PublicPath

    // Event that is emitted when the contract is created
    pub event TokensInitialized(initialSupply: UFix64)

    // Event that is emitted when tokens are withdrawn from a Vault
    pub event TokensWithdrawn(amount: UFix64, from: Address?)

    // Event that is emitted when tokens are deposited to a Vault
    pub event TokensDeposited(amount: UFix64, to: Address?)

    // Event that is emitted when new tokens are minted
    pub event TokensMinted(amount: UFix64)

    // Records voting weight data at a given block timestamp snapshot.
    // Used to provide voting weight when voting for a proposal.
    //
    pub struct VotingWeightData {
        pub let vaultBalance: UFix64
        pub let blockTs: UFix64

        init(vaultBalance: UFix64, blockTs: UFix64) {
            self.vaultBalance = vaultBalance
            self.blockTs = blockTs
        }
    }

    // VotingWeight
    //
    // Interface to record voting weight
    //
    pub resource interface VotingWeight {
        pub let vaultId: UInt64
        pub let votingWeightDataSnapshot: [VotingWeightData]
    }

    // Vault
    //
    // resource to keep track of Governance Tokens
    //
    pub resource Vault: FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance, VotingWeight {

        // keeps track of the total balance of the account's tokens
        pub var balance: UFix64
        // add an id for the vault for ease in checking whether vote has already been cast
        pub let vaultId: UInt64
        // keeps track of user's voting power
        pub let votingWeightDataSnapshot: [VotingWeightData]

        // initialize the balance at resource creation time
        init(balance: UFix64) {
            self.balance = balance
            self.vaultId = self.uuid
            self.votingWeightDataSnapshot = []
        }

        // withdraw
        //
        // Function that takes an integer amount as an argument
        // and withdraws that amount from the Vault.
        //
        // It creates a new temporary Vault that is used to hold
        // the money that is being transferred. It returns the newly
        // created Vault to the context that called so it can be deposited
        // elsewhere.
        //
        pub fun withdraw(amount: UFix64): @FungibleToken.Vault {
            self.balance = self.balance - amount
            emit TokensWithdrawn(amount: amount, from: self.owner?.address)
            self.recordVotingWeight()
            return <-create Vault(balance: amount)
        }

        // deposit
        //
        // Function that takes a Vault object as an argument and adds
        // its balance to the balance of the owners Vault.
        //
        // It is allowed to destroy the sent Vault because the Vault
        // was a temporary holder of the tokens. The Vault's balance has
        // been consumed and therefore can be destroyed.
        pub fun deposit(from: @FungibleToken.Vault) {
            let vault <- from as! @VotingTutorialGovernanceToken.Vault
            self.balance = self.balance + vault.balance
            emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
            self.recordVotingWeight()
            destroy vault
        }

        // recordVotingWeight
        //
        // private function to record voting weight of vault
        priv fun recordVotingWeight() {
            let ts = getCurrentBlock().timestamp
            self.votingWeightDataSnapshot.append(VotingWeightData(vaultBalance: self.balance, blockTs: ts))
        }

    }

    // createEmptyVault
    //
    // Function that creates a new Vault with a balance of zero
    // and returns it to the calling context. A user must call this function
    // and store the returned Vault in their storage in order to allow their
    // account to be able to receive deposits of this token type.
    //
    pub fun createEmptyVault(): @FungibleToken.Vault {
        return <-create Vault(balance: 0.0)
    }

    // VaultMinter
    //
    // Resource object that an admin can control to mint new tokens
    pub resource VaultMinter {

        // Function that mints new tokens and deposits into an account's vault
        // using their `Receiver` reference.
        // We say `&AnyResource{Receiver}` to say that the recipient can be any resource
        // as long as it implements the Receiver interface
        pub fun mintTokens(amount: UFix64, recipient: Capability<&AnyResource{FungibleToken.Receiver}>) {
            let recipientRef = recipient.borrow()
                ?? panic("Could not borrow a receiver reference to the vault")

            VotingTutorialGovernanceToken.totalSupply = VotingTutorialGovernanceToken.totalSupply + UFix64(amount)
            recipientRef.deposit(from: <-create Vault(balance: amount))

            emit TokensMinted(amount: amount)
        }
    }

    // The init function for the contract. All fields in the contract must
    // be initialized at deployment. This is just an example of what
    // an implementation could do in the init function. The numbers are arbitrary.
    init() {
        self.totalSupply = 0.0

        // assign paths
        self.VaultStoragePath = /storage/CadenceVotingTutorialVotingTutorialGovernanceTokenVaultStoragePath
        self.MinterStoragePath = /storage/CadenceVotingTutorialVotingTutorialGovernanceTokenMinterStoragePath
        self.VaultPublicPath = /public/CadenceVotingTutorialVotingTutorialGovernanceTokenVaultPublicPath

        // create the Vault with the initial balance and put it in storage
        // account.save saves an object to the specified `to` path
        // The path is a literal path that consists of a domain and identifier
        // The domain must be `storage`, `private`, or `public`
        // the identifier can be any name
        let vault <- create Vault(balance: self.totalSupply)
        self.account.save(<-vault, to: self.VaultStoragePath)

        // Create a public capability to the stored Vault that exposes VotingWeight
        //
        self.account.link<&VotingTutorialGovernanceToken.Vault{FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance, VotingTutorialGovernanceToken.VotingWeight}>(VotingTutorialGovernanceToken.VaultPublicPath, target: VotingTutorialGovernanceToken.VaultStoragePath)

        // Create a new MintAndBurn resource and store it in account storage
        self.account.save(<-create VaultMinter(), to: self.MinterStoragePath)

        // Emit initialization event
        emit TokensInitialized(initialSupply: self.totalSupply)
    }
}
```

`VotingTutorialAdministration` contains a struct `ProposalData` which is used to store both the proposal and the total votes.
Then we have two resources, a `Ballot` and an `Administrator` resource.
A user can request a `Ballot`, and then vote for a proposal, effectively tallying the vote weight in this contract.
Using a resource type is logical for this application, because if a user wants to delegate their vote, they can send that `Ballot` to another account.
Access to the `Administrator` resource is needed in order to add proposals.

```cadence:title=VotingTutorialAdministration.cdc
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
```

## Create two extra accounts ('acct2', 'acct3')

```console
flow accounts create
```

When asked, choose the local blockchain.

## Create the voter accounts

This transaction serves to create the vaults for the voters:

```cadence:title=tx_01_SetupAccount.cdc
import FungibleToken from 0xf8d6e0586b0a20c7
import VotingTutorialGovernanceToken from 0xf8d6e0586b0a20c7

/// This transaction configures an account to store and receive tokens defined by
/// the VotingTutorialGovernanceToken contract.
transaction {
  let account: AuthAccount

  prepare(acct: AuthAccount) {

    /// A new empty Vault object
    let vault <- VotingTutorialGovernanceToken.createEmptyVault()

    // Store the vault in the account storage
    acct.save<@FungibleToken.Vault>(<-vault, to: VotingTutorialGovernanceToken.VaultStoragePath)

    log("Empty Vault stored")

    // Link capability reference
    acct.link<&VotingTutorialGovernanceToken.Vault{FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance, VotingTutorialGovernanceToken.VotingWeight}>(VotingTutorialGovernanceToken.VaultPublicPath, target: VotingTutorialGovernanceToken.VaultStoragePath)

    self.account = acct
    log("VotingTutorialGovernanceToken Vault Reference created")
  }

   post {
        // Check that the capability was created correctly
       getAccount(self.account.address).getCapability<&VotingTutorialGovernanceToken.Vault{FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance, VotingTutorialGovernanceToken.VotingWeight}>(VotingTutorialGovernanceToken.VaultPublicPath)
       .check():
         "VotingTutorialGovernanceToken Vault Reference was not created correctly"
    }
}
```

Execute this transaction for both users:

```console
flow transactions send transactions/tx_01_SetupAccount.cdc --signer acct2
flow transactions send transactions/tx_01_SetupAccount.cdc --signer acct3
```

## Mint tokens to those two accounts

```cadence:title=tx_02_MintTokens.cdc
import FungibleToken from 0xf8d6e0586b0a20c7
import VotingTutorialGovernanceToken from 0xf8d6e0586b0a20c7

/// This transaction mints tokens and deposits them into the receivers account's vault
transaction (recipient1: Address, recipient2: Address, amountRecipient1: UFix64, amountRecipient2: UFix64) {

    /// Local variable for storing the reference to the minter resource
    let mintingRef: &VotingTutorialGovernanceToken.VaultMinter

    /// Local variables for storing the references to the Vaults of
    /// the accounts that will receive the newly minted tokens
    var receiver1: Capability<&AnyResource{FungibleToken.Receiver}>
    var receiver2: Capability<&AnyResource{FungibleToken.Receiver}>

    prepare(acct: AuthAccount) {
        // Borrow a reference to the stored, private minter resource
        self.mintingRef = acct.borrow<&VotingTutorialGovernanceToken.VaultMinter>(from: VotingTutorialGovernanceToken.MinterStoragePath)
            ?? panic("Could not borrow a reference to the minter")

        // Get the account objects
        let recipient1Account = getAccount(recipient1)
        let recipient2Account = getAccount(recipient2)

        // Get their public receiver capabilities
        self.receiver1 = recipient1Account.getCapability<&AnyResource{FungibleToken.Receiver}>(VotingTutorialGovernanceToken.VaultPublicPath)
        self.receiver2 = recipient2Account.getCapability<&AnyResource{FungibleToken.Receiver}>(VotingTutorialGovernanceToken.VaultPublicPath)
    }

    execute {
        // Mint tokens and deposit them into recipient1's Vault
        self.mintingRef.mintTokens(amount: amountRecipient1, recipient: self.receiver1)
        log("tokens minted and deposited to the vault of recipient1")
        // Mint tokens and deposit them into recipient2's Vault
        self.mintingRef.mintTokens(amount: amountRecipient2, recipient: self.receiver2)
        log("tokens minted and deposited to the vault of recipient2")
    }
}
```

Execute this transaction:

```console
flow transactions send transactions/tx_02_MintTokens.cdc "0x01cf0e2f2f715450" "0x179b6b1cb6755e31" 30.0 150.0 --signer emulator-account
```

## Create the proposals for voting

```cadence:title=tx_03_CreateNewProposals.cdc
import VotingTutorialAdministration from 0xf8d6e0586b0a20c7

/// This transaction allows the administrator of the VotingTutorialAdministration contract
/// to create new proposals for voting and save them to the smart contract
transaction {
    /// A reference to the admin Resource
    let adminRef: &VotingTutorialAdministration.Administrator
    /// The proposals to add
    let proposals: {Int : ProposalData}

    prepare(admin: AuthAccount) {
        self.adminRef = admin.borrow<&VotingTutorialAdministration.Administrator>(from: VotingTutorialAdministration.adminStoragePath)!

        let ts = getCurrentBlock().timestamp
        let food = ["Pizza", "Spaghetti", "Pancake"]
        let proposal1 = VotingTutorialAdministration.ProposalData(name: "What's up for dinner?", options: food, blockTs: ts)
        let oneChoice = ["Yes", "No"]
        let proposal2 = VotingTutorialAdministration.ProposalData(name: "Let's throw a party!", options: oneChoice, blockTs: ts)
        self.proposals = {0 : proposal1, 1 : proposal2}
    }

    execute {
        // Call the addProposals function to create the dictionary of ProposolData
        self.adminRef.addProposals(self.proposals)
        log("Proposals added!")
    }

    post {
        VotingTutorialAdministration.proposals.length == 2
    }
}
```

Execute this transaction:

```console
flow transactions send transactions/tx_03_CreateNewProposals.cdc --signer emulator-account
```

Optionally - if you want to test the 'voting token balance timestamp < proposal timestamp' requirement, call mint again but change the token amounts.
This minting will not affect the voting weight, as it happened after the proposal was established.

## Create new ballots

```cadence:title=tx_04_CreateNewBallot.cdc 
import VotingTutorialAdministration from 0xf8d6e0586b0a20c7
import VotingTutorialGovernanceToken from 0xf8d6e0586b0a20c7

/// This transaction allows the voter with a governance token vault
/// to create a new ballot and store it in her account
transaction () {
    prepare(voter: AuthAccount) {

        /// A reference to the voter's VotingTutorialGovernanceToken Vault
        let vaultRef = voter.getCapability<&VotingTutorialGovernanceToken.Vault{VotingTutorialGovernanceToken.VotingWeight}>(VotingTutorialGovernanceToken.VaultPublicPath)

        /// A new Ballot attached to the voter's vault
        let ballot <- VotingTutorialAdministration.issueBallot(recipientCap: vaultRef)

        // store that ballot in the voter's account storage
        voter.save<@VotingTutorialAdministration.Ballot>(<-ballot, to: VotingTutorialAdministration.ballotStoragePath)

        log("Ballot transferred to voter")
    }
}
```

Execute this transaction for both users:

```console
flow transactions send transactions/tx_04_CreateNewBallot.cdc --signer acct2
flow transactions send transactions/tx_04_CreateNewBallot.cdc --signer acct3
```

## Cast vote

This transaction is used for the final vote casting:

```cadence:title=tx_05_SelectAndCastVotes.cdc
import VotingTutorialAdministration from 0xf8d6e0586b0a20c7

/// This transaction allows a voter to select a proposal via it's id and vote for it
transaction (proposalId: Int, optionId: Int) {
    prepare(voter: AuthAccount) {
        /// The Ballot of the voter
        let ballot <- voter.load<@VotingTutorialAdministration.Ballot>(from: VotingTutorialAdministration.ballotStoragePath)
            ?? panic("Could not load the voter's ballot")

        // Vote on the proposal and the option
        ballot.vote(proposalId: proposalId, optionId: optionId)

        // destroy resource
        destroy ballot

        log("Vote cast and tallied")
    }
}
```

Voters can cast their votes by passing the proposal and option id (in the first case for the first proposal and the third option, in the second case for the second proposal and the first option):

```console
flow transactions send transactions/tx_05_SelectAndCastVotes.cdc "0" "2" --signer acct2
flow transactions send transactions/tx_05_SelectAndCastVotes.cdc "1" "0" --signer acct3
```

## Check balances

In order to check both the last recorded balance and timestamp of the balance for the two user accounts, run this:

```console
flow scripts execute scripts/GetVotingWeight.cdc "0x01cf0e2f2f715450" "0x179b6b1cb6755e31"
```

## Check proposal outcome

In order to see the recorded proposals outcome, run this:

```console
flow scripts execute scripts/GetProposalsData.cdc
```
