---
title: 9. Voting Contract
---

In this tutorial, we're going to deploy a contract that allows users to vote on multiple proposals that a voting administrator controls.

---
With the advent of blockchain technology and smart contracts,
it has become popular to try to create decentralized voting mechanisms that allow large groups of users to vote completely on chain.
This tutorial will provide a trivial example for how this might be achieved by using a resource-oriented programming model.

We'll take you through these steps to get comfortable with the Voting contract.

1. Deploy the contracts to the local blockchain emulator
2. Create two user accounts
3. Create two voter accounts for these users
4. Mint tokens to these two accounts
5. Create proposals for users to vote on
6. Create `Ballot` resources for both voters
7. Record and cast votes in the central Voting contract
8. Read the results of the vote


## A Voting Contract in Cadence

In this contract, a `Ballot` is represented as a resource.
A user can request a `Ballot`, and then vote for a proposal 
and submit the `Ballot` to the central smart contract to have their vote recorded.
Using a resource type is logical for this application,
because if a user wants to delegate their vote,
they can send that `Ballot` to another account.

## Setup the environment
Navigate in a terminal window to the voting tutorial dictionary and execute:
Execute
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
	"networks": {
		"emulator": "127.0.0.1:3569",
		"mainnet": "access.mainnet.nodes.onflow.org:9000",
		"testnet": "access.devnet.nodes.onflow.org:9000"
	},
	"accounts": {
		"emulator-account": {
			"address": "f8d6e0586b0a20c7",
			"key": "39353f597de2bed6781760838a62536374bfff46b8efac5ebb450825debdd778"
		}
	},
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
## Run the emulator:
Once the configuration is saved, execute:
```console
flow emulator
```
## Deploy the project:
Open another terminal window and execute
```console
flow project deploy
```
All three contracts should be deployed.
FungibleToken is a Cadence standard, while `VotingTutorialGovernanceToken` and `VotingTutorialAdministration` are specific to this tutorial.
`VotingTutorialGovernanceToken` is needed in order to vote:
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
`VotingTutorialAdministration` allows administration of the whole voting process:
```cadence:title=VotingTutorialAdministration.cdc
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
```
## Create two extra accounts ('acct2', 'acct3'):
```console
flow accounts create
```
When asked, choose the local blockchain.

## Create the voter accounts:
```console
flow transactions send transactions/tx_01_SetupAccount.cdc --signer acct2
flow transactions send transactions/tx_01_SetupAccount.cdc --signer acct3
```

## Mint tokens to those two accounts:
```console
flow transactions send transactions/tx_02_MintTokens.cdc "0x01cf0e2f2f715450" "0x179b6b1cb6755e31" 30.0 150.0 --signer emulator-account
```

## Create the proposals for voting:
```console
flow transactions send transactions/tx_03_CreateNewProposals.cdc --signer emulator-account
```

Optionally - if you want to test the 'voting timestamp > proposal timestamp' requirement, call mint again but change the token amounts.
This minting will not affect the voting weight, as it happened after the proposal was established.

## Create new ballots:
```console
flow transactions send transactions/tx_04_CreateNewBallot.cdc --signer acct2
flow transactions send transactions/tx_04_CreateNewBallot.cdc --signer acct3
```
## Cast vote:
Finally a voter can cast a vote by passing the proposal and option id (in the first case for the first proposal and the third option, in the second case for the second proposal and the first option):
```console
flow transactions send transactions/tx_05_SelectAndCastVotes.cdc "0" "2" --signer acct2
flow transactions send transactions/tx_05_SelectAndCastVotes.cdc "1" "0" --signer acct3
```
## Check balances:
In order to check both the last recorded balance and timestamp of the balance for the two user accounts, run this:
```console
flow scripts execute scripts/GetVotingWeight.cdc "0x01cf0e2f2f715450" "0x179b6b1cb6755e31"
```
## Check proposal outcome:
In order to see the recorded proposals outcome, run this:
```console
flow scripts execute scripts/GetProposalsData.cdc
```
