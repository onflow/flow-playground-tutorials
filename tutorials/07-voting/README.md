---
title: 9. Voting Contract
---

With the advent of blockchain technology and smart contracts,
it has become popular to try to create decentralized voting mechanisms that allow large groups of users to vote completely on chain.
This tutorial will provide a trivial example for how this might be achieved by using a resource-oriented programming model.
Two contracts will allow users to vote on multiple proposals while their voting power is determined by the balance of certain tokens. 
These so called governance tokens track the user account balance over time, thus enabling insight into the balance just before the creation of a proposal. 
An administration contract serves for the creation of proposals and provides the ballots.  

Other than in the previous tutorials, this time we will work with a local blockchain on your computer.  

This can be achieved by using the [Flow CLI](https://developers.flow.com/tools/flow-cli/index), which allows us to run our code on a local blockchain emulator. The emulator comes bundled with the `Flow CLI`. The `Flow CLI` serves for managing the emulator and all files used in the interaction with the blockchain: Smart contracts, transactions and script files. It also allows you to generate an initial project configuration file, and to create accounts or even generate a default app.  
Furthermore, the Flow CLI also allows you to query the local blockchain, testnet and mainnet for various information regarding e.g. the network status, or different entities.  

---
Let's focus on the procedure now.  
We'll take you through the following steps to get comfortable with the voting contracts and the transactions:  

1. Deploy the contracts to the local blockchain emulator
2. Create two user accounts
3. Create voter accounts for these users
4. Mint tokens to these accounts
5. Create proposals for users to vote on
6. Create `Ballot` resources for both voters
7. Record and cast votes in the central voting contract
8. Read the results of the vote

## Setup the environment

Please follow [this link](https://developers.flow.com/tools/flow-cli/install) for instructions on how to install it on your computer. You should now be able to call it by simply entering `flow`, which will show you a list with all possible commands.
The CLI also contains the [Flow Emulator](https://developers.flow.com/tools/emulator/index), a gRPC server that implements the Flow Access API. Please take a look at the [Flow CLI subsection](https://developers.flow.com/tools/flow-cli/start-emulator) for a brief overview, more details are covered in the [ReadMe](https://github.com/onflow/flow-emulator/#readme).

Once installed, please download the project in the terminal by executing `git clone git@github.com:onflow/flow-playground-tutorials.git`, and then go to the project folder: `cd tutorials/08-voting`.  
One thing we deliberately didn't include in the repository is the project configuration, which is contained in a file called `flow.json`. It lists the various components involved in the deployment of your project on the blockchain: Smart contracts, user accounts, and the different network URLs. You can read more about it [in the documentation](https://developers.flow.com/tools/flow-cli/configuration).  

We can generate an initial `flow.json` configuration file by executing this command inside the project folder:

```console
flow init
```

At the moment, it only contains the default networks and a default admin user account. Most importantly, it is still missing information about the smart contracts that need to be deployed on the blockchain emulator. For this, we need to add two sections, `contracts` and `deployments`. The first one simply lists the relative paths to all the contracts that you want to deploy, the latter one defines which contracts you want to deploy to which accounts on which networks. Let's edit the configuration and add both the `contracts` and the `deployments` section, laying the ground for deployment to the local emulator:

```json:title=flow.json
{
    "contracts": {
        "FungibleToken": "./contracts/FungibleToken.cdc",
        "VotingTutorialAdministration": "./contracts/VotingTutorialAdministration.cdc",
        "VotingTutorialGovernanceToken": "./contracts/VotingTutorialGovernanceToken.cdc"
    },
    //...networks, accounts...
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

## Run the emulator

Once the configuration is saved, you can start the emulator which provides you with a local blockchain:

```console
flow emulator
```

## Deploy the project

Open another terminal window (check that you remain in the project folder) and deploy the project. This relies on the configuration file, which should now contain information about all three smart contracts as shown in the Setup section above.

```console
flow project deploy
```

All three contracts should be deployed now to the local blockchain.  

FungibleToken is a Cadence standard, while `VotingTutorialGovernanceToken` and `VotingTutorialAdministration` are specific to this tutorial. A good introduction to fungible tokens is given in the [Fungible Tokens tutorial](https://developers.flow.com/cadence/tutorial/06-fungible-tokens): "Some of the most popular contract classes on blockchains today are fungible tokens. These contracts create homogeneous tokens that can be transferred to other users and spent as currency (e.g., ERC-20 on Ethereum)."  
Furthermore, the [Github repository](https://github.com/onflow/flow-ft) specifies: "The standard consists of a contract interface called FungibleToken that requires implementing contracts to define a Vault resource that represents the tokens that an account owns. Each account that owns tokens will have a Vault stored in its account storage. Users call functions on each other's Vaults to send and receive tokens."  
`VotingTutorialGovernanceToken` is an implementation of the Fungible Token standard and needed in order to vote, the voter account's vault balance is determining the weight of the vote. It's specialty is that it stores a history of voting weight that is updated on each transfer.  
`VotingTutorialAdministration` is used for administration of the whole voting process.

This is the code for `VotingTutorialGovernanceToken`:  

```cadence:title=VotingTutorialGovernanceToken.cdc
/*
* The VotingTutorialGovernanceToken contract is a sample implementation 
* of a fungible token on Flow which can be used for voting.
*/

import FungibleToken from "./FungibleToken.cdc"

pub contract VotingTutorialGovernanceToken: FungibleToken {

    /// Total supply of all tokens in existence.
    pub var totalSupply: UFix64

    /// Paths
    ///
    /// The Vault will be stored here
    pub let VaultStoragePath: StoragePath
    /// The Minter will be stored here
    pub let MinterStoragePath: StoragePath
    /// The public capability to the stored Vault will be accessible via this path
    pub let VaultPublicPath: PublicPath

    /// Event that is emitted when the contract is created
    pub event TokensInitialized(initialSupply: UFix64)

    /// Event that is emitted when tokens are withdrawn from a Vault
    pub event TokensWithdrawn(amount: UFix64, from: Address?)

    /// Event that is emitted when tokens are deposited to a Vault
    pub event TokensDeposited(amount: UFix64, to: Address?)

    /// Event that is emitted when new tokens are minted
    pub event TokensMinted(amount: UFix64)

    /// Records voting weight data at a given block timestamp snapshot.
    /// Used to provide voting weight when voting for a proposal.
    ///
    pub struct VotingWeightData {
        pub let vaultBalance: UFix64
        pub let blockTs: UFix64

        init(vaultBalance: UFix64, blockTs: UFix64) {
            self.vaultBalance = vaultBalance
            self.blockTs = blockTs
        }
    }

    /// VotingWeight
    ///
    /// Interface to record voting weight
    ///
    pub resource interface VotingWeight {
        pub let vaultId: UInt64
        pub let votingWeightDataSnapshot: [VotingWeightData]
    }

    /// Vault
    ///
    /// Resource to keep track of Governance Tokens
    ///
    pub resource Vault: FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance, VotingWeight {

        /// Keeps track of the total balance of the account's tokens
        pub var balance: UFix64
        /// Add an id for the vault for ease in checking whether vote has already been cast
        pub let vaultId: UInt64
        /// Keeps track of user's voting power
        pub let votingWeightDataSnapshot: [VotingWeightData]

        /// Initializes the Vault fields, sets the balance at resource creation time
        /// and creates a vault id
        init(balance: UFix64) {
            self.balance = balance
            self.vaultId = self.uuid
            self.votingWeightDataSnapshot = []
        }

        /// withdraw takes a fixed point amount as an argument
        /// and withdraws that amount from the Vault.
        ///
        /// It creates a new temporary Vault that is used to hold
        /// the money that is being transferred. It returns the newly
        /// created Vault to the context that called so it can be deposited
        /// elsewhere.
        pub fun withdraw(amount: UFix64): @FungibleToken.Vault {
            self.balance = self.balance - amount
            emit TokensWithdrawn(amount: amount, from: self.owner?.address)
            self.recordVotingWeight()
            return <-create Vault(balance: amount)
        }

        /// deposit takes a Vault object as an argument and adds
        /// its balance to the balance of the owners Vault.
        ///
        /// It is allowed to destroy the sent Vault because the Vault
        /// was a temporary holder of the tokens. The Vault's balance has
        /// been consumed and therefore can be destroyed.
        pub fun deposit(from: @FungibleToken.Vault) {
            let vault <- from as! @VotingTutorialGovernanceToken.Vault
            self.balance = self.balance + vault.balance
            emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
            self.recordVotingWeight()
            destroy vault
        }

        /// recordVotingWeight records the current voting weight of the vault
        priv fun recordVotingWeight() {
            let ts = getCurrentBlock().timestamp
            self.votingWeightDataSnapshot.append(VotingWeightData(vaultBalance: self.balance, blockTs: ts))
        }

    }

    /// createEmptyVault creates a new Vault with a balance of zero
    /// and returns it to the calling context. A user must call this function
    /// and store the returned Vault in their storage in order to allow their
    /// account to be able to receive deposits of this token type.
    pub fun createEmptyVault(): @FungibleToken.Vault {
        return <-create Vault(balance: 0.0)
    }

    /// VaultMinter
    ///
    /// Resource object that an admin can control to mint new tokens
    ///
    pub resource VaultMinter {

        /// mintTokens mints new tokens and deposits them into an account's vault
        /// using their `Receiver` reference.
        /// We say `&AnyResource{Receiver}` to say that the recipient can be any resource
        /// as long as it implements the Receiver interface
        pub fun mintTokens(amount: UFix64, recipient: Capability<&AnyResource{FungibleToken.Receiver}>) {
            let recipientRef = recipient.borrow()
                ?? panic("Could not borrow a receiver reference to the vault")

            VotingTutorialGovernanceToken.totalSupply = VotingTutorialGovernanceToken.totalSupply + UFix64(amount)
            recipientRef.deposit(from: <-create Vault(balance: amount))

            emit TokensMinted(amount: amount)
        }
    }

    /// The init function for the contract. All fields in the contract must
    /// be initialized at deployment. This is just an example of what
    /// an implementation could do in the init function. The numbers are arbitrary.
    init() {
        self.totalSupply = 0.0

        // Assign paths
        self.VaultStoragePath = /storage/CadenceVotingTutorialVotingTutorialGovernanceTokenVaultStoragePath
        self.MinterStoragePath = /storage/CadenceVotingTutorialVotingTutorialGovernanceTokenMinterStoragePath
        self.VaultPublicPath = /public/CadenceVotingTutorialVotingTutorialGovernanceTokenVaultPublicPath

        /// Create the Vault with the initial balance and put it in account storage.
        /// account.save saves an object to the specified `to` path
        /// The path is a literal path that consists of a domain and identifier
        /// The domain must be `storage`, `private`, or `public`
        /// the identifier can be any name
        let vault <- create Vault(balance: self.totalSupply)
        self.account.save(<-vault, to: self.VaultStoragePath)

        /// Create a public capability to the stored Vault that exposes VotingWeight
        self.account.link<&VotingTutorialGovernanceToken.Vault{FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance, VotingTutorialGovernanceToken.VotingWeight}>(VotingTutorialGovernanceToken.VaultPublicPath, target: VotingTutorialGovernanceToken.VaultStoragePath)

        /// Create a new Minter resource and store it in account storage
        self.account.save(<-create VaultMinter(), to: self.MinterStoragePath)

        /// Emit initialization event
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
        // "pub(set)" - this access modifier gives write access to everyone, 
        // so the Ballot resource can update it.
        // see https://developers.flow.com/cadence/language/access-control for more information
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
```

## Create two extra accounts ('acct2', 'acct3')

In the rest of this tutorial, we will use transactions and scripts which interact with the deployed contracts.  
The transactions which are concerned with the expression of the voter will need to be authorized by the voters themselves.  
Therefore we are going to create two voter accounts. In a first step, we are creating the user accounts.  

The following command creates a user account, you need to execute it twice, once for an account named 'acct2', and again for 'acct3'.
When asked, please choose the option *Local Emulator*. Enter 'y' for acceptance at the end:  

```console
flow accounts create
```

## Create the voter accounts

The next transaction serves to create the governance token vault for a voter, effectively giving the user the general ability to vote with governance tokens.  
The vault will later be used in order to get a ballot from the administration contract, which can then be used to vote on proposals which the administrator created.  

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

Please execute this transaction for both users:

```console
flow transactions send transactions/tx_01_SetupAccount.cdc --signer acct2
flow transactions send transactions/tx_01_SetupAccount.cdc --signer acct3
```

## Mint tokens to those two accounts

Now that both user accounts have empty governance token vaults and a receiver capability which allows them to receive tokens,  
we can now mint tokens to the accounts via this transaction, which uses the capabilities as arguments to the `mintTokens` function:

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

Please execute this transaction as the administrator, indicating both the receiving account addresses (which usually do not differ in the local environment), and the token amounts:

```console
flow transactions send transactions/tx_02_MintTokens.cdc "0x01cf0e2f2f715450" "0x179b6b1cb6755e31" 30.0 150.0 --signer emulator-account
```

## Create the proposals for voting

Now that the voters have governance tokens, the administrator can create proposals for voting via the next transaction.  
It's important that the governance tokens were minted before the creation of the proposals, as only the last governance token balance before proposal creation counts when voting happens.

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

Please execute this transaction as the administrator:

```console
flow transactions send transactions/tx_03_CreateNewProposals.cdc --signer emulator-account
```

Optionally - if you want to test the 'voting token balance timestamp < proposal timestamp' requirement, call mint again but change the token amounts.
This minting will not affect the voting weight, as it happened after the proposal was established.

## Create new ballots

Now the voters can get their ballots which allow them to vote on the existing proposals.  
They can create and save them to their account storage themselves via this transaction:  

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

Please execute this transaction twice so that both users are able to vote:

```console
flow transactions send transactions/tx_04_CreateNewBallot.cdc --signer acct2
flow transactions send transactions/tx_04_CreateNewBallot.cdc --signer acct3
```

## Cast vote

Now that each voter has a ballot, they can finally cast their vote via this transaction which takes both the proposal id and the chosen option id as arguments:

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

Both the proposal and option id need to be indicated as in the following example, counting from '0' upwards (in the first case for the first proposal and the third option, in the second case for the second proposal and the first option):

```console
flow transactions send transactions/tx_05_SelectAndCastVotes.cdc "0" "2" --signer acct2
flow transactions send transactions/tx_05_SelectAndCastVotes.cdc "1" "0" --signer acct3
```

## Check balances

If you want to have an insight into the last recorded balance and timestamp of the balance for the two user accounts, you can use the script `GetVotingWeight.cdc`, indication both addresses:

```console
flow scripts execute scripts/GetVotingWeight.cdc "0x01cf0e2f2f715450" "0x179b6b1cb6755e31"
```

## Check proposal outcome

Finally, in order to see the recorded proposals outcome, run the `GetProposalsData` script:

```console
flow scripts execute scripts/GetProposalsData.cdc
```

## Summary

We hope that this was a good introduction to the local blockchain emulator and the `Flow CLI` in general.  
You should feel comfortable now with the local tools and the configuration.  