import FungibleToken from "./FungibleToken.cdc"

// GovernanceToken.cdc
//
// The GovernanceToken contract is a sample implementation of a fungible token on Flow which can be used for voting.

pub contract GovernanceToken: FungibleToken {

    // Total supply of all tokens in existence.
    pub var totalSupply: UFix64

    // Paths
    pub let VaultStoragePath: StoragePath
    pub let MinterStoragePath: StoragePath
    pub let VaultPublicPath: PublicPath
    pub let VaultVotingWeightPublicPath: PublicPath
    pub let MinterPrivatePath: PrivatePath

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
            let vault <- from as! @GovernanceToken.Vault
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

            GovernanceToken.totalSupply = GovernanceToken.totalSupply + UFix64(amount)
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
        self.VaultStoragePath = /storage/CadenceVotingTutorialGovernanceTokenVaultStoragePath
        self.MinterStoragePath = /storage/CadenceVotingTutorialGovernanceTokenMinterStoragePath
        self.VaultPublicPath = /public/CadenceVotingTutorialGovernanceTokenVaultPublicPath
        self.VaultVotingWeightPublicPath = /public/CadenceVotingTutorialGovernanceTokenVaultVotingWeightPublicPath
        self.MinterPrivatePath = /private/CadenceVotingTutorialGovernanceTokenMinterPrivatePath

        // create the Vault with the initial balance and put it in storage
        // account.save saves an object to the specified `to` path
        // The path is a literal path that consists of a domain and identifier
        // The domain must be `storage`, `private`, or `public`
        // the identifier can be any name
        let vault <- create Vault(balance: self.totalSupply)
        self.account.save(<-vault, to: self.VaultStoragePath)

        // Create a public capability to the stored Vault that exposes VotingWeight
        //
        self.account.link<&GovernanceToken.Vault{FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance, GovernanceToken.VotingWeight}>(GovernanceToken.VaultPublicPath, target: GovernanceToken.VaultStoragePath)

        // Create a new MintAndBurn resource and store it in account storage
        self.account.save(<-create VaultMinter(), to: self.MinterStoragePath)

        // Create a private capability link for the Minter
        // Capabilities can be used to create temporary references to an object
        // so that callers can use the reference to access fields and functions
        // of the objet.
        //
        // The capability is stored in the /private/ domain, which is only
        // accesible by the owner of the account
        self.account.link<&VaultMinter>(self.MinterPrivatePath, target: self.MinterStoragePath)

        // Emit initialization event
        emit TokensInitialized(initialSupply: self.totalSupply)
    }
}
