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
