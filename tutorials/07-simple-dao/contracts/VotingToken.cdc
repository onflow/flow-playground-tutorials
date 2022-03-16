/// VotingToken is an implementation of the Fungible token standard
/// The goal is to showcase the possibilities Cadence to design
/// a governance token.
/// 
/// It has the minimum functionality of being a governance token
/// while it can be extended more to support more sophisticated edge cases.

/// Note - This is not production ready code
/// and is only meant to be used for educational and tutorial purposes

/// This contract keeps track of a checkpoint, which is equivalent to the timestamp
/// on a real network, but the timestamp cannot be used in the playground.

/// When users vote with the token, the voting weight is taken from a specific checkpoint

import FungibleToken from 0x01

pub contract VotingToken: FungibleToken {

    /// Storage path where vault resources are stored.
    pub let vaultPath: StoragePath

    /// Public path where the vault public capabilities are stored
    pub let vaultPublicPath: PublicPath

    /// Storage Path that holds the minter resource
    pub let minterResourcePath: StoragePath

    /// Storage Path that holds the administrator resource
    pub let administratorResourcePath: StoragePath

    /// Total supply of the voting token
    pub var totalSupply: UFix64

    /// Checkpoint is equivalent to timestamp. It is the Id for the point in time
    /// at which a snapshot of the user's balance can be taken.
    pub var checkpointCounter: UInt16

    /// Event emitted when someone (i.e `to`) calls the `delegate` function to make 
    /// vault owner delegate to the `to`.
    pub event Delegated(to: Address, amount: UFix64)

    /// Event emitted when new checkpoint get created by the administrator.
    pub event CheckPointCreated(newCheckpointId: UInt16)

    /// TokensWithdrawn
    ///
    /// The event that is emitted when tokens are withdrawn from a Vault
    pub event TokensWithdrawn(amount: UFix64, from: Address?)

    /// TokensDeposited
    ///
    /// The event that is emitted when tokens are deposited to a Vault
    pub event TokensDeposited(amount: UFix64, to: Address?)

    pub resource interface Recevier {
        pub fun deposit(vault: @Vault)
    }

    pub resource interface Provider {
        pub fun withdraw(amount: UFix64): @Vault
    }

    pub resource interface Balance {
        pub var balance: UFix64

        init(balance: UFix64) {
            post {
                self.balance == balance:
                    "Balance must be initialized to the initial balance"
            }
        }
    }

    /// Interface to query the voting power at a given `checkpointCounter`.
    pub resource interface VotingPower {
        pub fun getVotingPower(at: UInt16): UFix64
        pub fun votingPowerDelegated(): Bool
    }

    /// Interface that allows delegating the voting power to another token holder.
    /// Ex - Alice and Bob are the 2 token holder of the `VotingToken` and Alice doesn't want
    /// to participate in the governance system. She can delegate her voting power to Bob
    /// using the `delegate` function. So Alice calls bob's `delegate()` function to appoint him
    /// as the delegatee of her voting power.
    pub resource interface Delegation {
        pub fun delegate(cap: Capability<&AnyResource{DelegateVotingPower, VotingPower}>)
    }

    /// Interface that facilitates the delegation of voting power.
    /// If status is `true`, the given account delegating their voting power to
    /// the given capability and in future can't vote using their voting power
    /// until the delegation gets revoked.
    pub resource interface DelegateVotingPower {
        pub fun delegateVotingPower(status: Bool, delegateTo: Address)
    }

    /// This Vote resource is used because we don't want to allow someone else to vote
    /// using someone else voting power without being delegated to.
    /// User should create a resource object using `createVoteImpression()` and pass the public
    /// capability to read the voting power.
    /// It is only a workaround to make it permissioned, It could be improve with a better design.
    /// Note - This should always be a private resource stored in /storage/ without a public link
    pub resource Vote {
        // Capability that allows getting the voting power of the resource owner.
        pub let impression: Capability<&AnyResource{VotingPower}>

        init(impression: Capability<&AnyResource{VotingPower}>) {
            self.impression = impression
        }
    }

    pub resource Vault: Provider, Recevier, Balance, VotingPower, DelegateVotingPower, Delegation {
        
        // Amount of tokens held by the vault
        pub var balance: UFix64

        // Variable to know whether the user voting power is delegated or not
        // Ex - if it is set `true` then voting power is delegated to `delegateTo` address.
        pub var isVotingPowerDelegated: Bool

        // Optional address to hold the delegatee of the vault owner.
        access(self) var delegateTo: Address?

        // The checkpoint Id at which the last snapshot was taken for the given vault.
        pub var lastCheckpointId: UInt16

        // Maximum number of vaults that can delegate to this vault.
        // In the current implementation it is set to 10
        pub let maximumDelegators: UInt16

        // Dictionary to keep track of the voting power for a given checkpoint.
        access(self) var votingPower: {UInt16: UFix64}

        // Array list to contain the capabilities of vaults that have delegated to this vault
        access(self) var delegateeOf: [Capability<&AnyResource{VotingPower}>]

        init(balance: UFix64) {
            self.balance = balance
            self.votingPower = {}
            self.isVotingPowerDelegated = false
            self.lastCheckpointId = VotingToken.checkpointCounter
            self.delegateeOf = []
            self.maximumDelegators = 10
            self.delegateTo = nil
        }

        // Function to deposit a VotingToken vault
        // It also going to create the checkpoint/snapshot for a current checkpointCounter.
        pub fun deposit(vault: @Vault) {
            if vault.balance > 0.0 {
                let vault <- from as! @VotingToken.Vault
                self.balance = self.balance + vault.balance
                emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
                self._updateCheckpointBalances()
                vault.balance = 0.0
            }
            destroy vault
        }

        // Function to withdraw the vault.
        // It also going to create the checkpoint/snapshot for a current checkpointCounter.
        pub fun withdraw(amount: UFix64): @Vault {
            if amount > 0.0 {
                self.balance = self.balance - amount
                self._updateCheckpointBalances()
                emit TokensWithdrawn(amount: amount, from: self.owner?.address)
            }
            let token <- create Vault(balance: amount)
            return <- token
        }

        access(self) fun _updateCheckpointBalances() {
            let currentCheckpointId = VotingToken.checkpointCounter
            self.votingPower[currentCheckpointId] = self.balance
        }

        /// Delegates the voting power of this vault to a given capability.
        /// Ex - User A wants to delegate the voting power to User B then User A would call
        /// User B's delegate function and passing its own capability as an argument.
        /// Note - User B can't be a delegate of anymore than the `maximumDelegators`.
        pub fun delegate(cap: Capability<&AnyResource{DelegateVotingPower, VotingPower}>) {
            pre {
                cap.check() : "Not a valid capability"
            }
            let capRef = cap.borrow() ?? panic("Unable to borrow a reference to the delegating capability")
            assert(self.delegateeOf.length < Int(self.maximumDelegators), message: "Delegatee limit reached")
            capRef.delegateVotingPower(status: true, delegateTo: self.owner!.address)
            self.delegateeOf.append(cap)
            emit Delegated(of: cap.address)
        }

        /// Switch to set the owner of the delegated power.
        pub fun delegateVotingPower(status: Bool, delegateTo: Address) {
            self.isVotingPowerDelegated = status
            self.delegateTo = delegateTo
        }

        /// Tells whether the vault owner delegated the voting power or not.
        pub fun votingPowerDelegated() : Bool {
            return self.isVotingPowerDelegated
        }

        /// Get the voting power at the given checkpoint Id.
        pub fun getVotingPower(at: UInt16): UFix64 {
            pre {
                at <= VotingToken.checkpointCounter : "Can not query the voting power to a non existent block number"
            }

            // First, iterate through all the vaults delegating to this vault and add their power
            var tempPower: UFix64 = 0.0;
            for cap in self.delegateeOf {
                let capRef = cap.borrow() ?? panic("Unable to borrow a reference to the delegator capability")
                tempPower = tempPower + capRef.getVotingPower(at: at)
            }

            // Then, get the base voting power of this vault
            var selfVotingPower : UFix64 = 0.0;
            if at >= self.lastCheckpointId {
                selfVotingPower = self.votingPower[self.lastCheckpointId] ?? panic("Should have the value at last checkpoint")
            } else {
                // TODO: Improve the logic here to calculate the voting power for a given checkpoint.
                self.votingPower[at] ?? 0.0
            }

            // Add the two together and return
            return  selfVotingPower + tempPower
        }
    }

    /// Anyone can call this function and create empty vault.
    pub fun createEmptyVault(): @Vault {
        return <- create Vault(balance: 0.0)
    }

    /// Anyone can call this function and create voteImpression.
    pub fun createVoteImpression(impression: Capability<&AnyResource{VotingPower}>): @Vote {
        return <- create Vote(impression: impression)
    }

    pub resource Minter {

        pub fun mint(amount: UFix64, recepient: Capability<&AnyResource{Recevier}>)  {
            pre {
                recepient.check() : "Not a valid token receiver capability"
            }
            if amount > 0.0 {
                let ref = recepient.borrow()?? panic("Unable to borrow reference to receipient capability")
                let token <- create Vault(balance: amount)
                VotingToken.totalSupply = VotingToken.totalSupply + amount
                ref.deposit(vault: <-token)
            }
        }

    }

    /// Administrator resource that can update the checkpoint counter
    pub resource Administrator {
        /// Allow administrator to update the checkpoint counter
        pub fun createCheckpoint() {
            VotingToken.checkpointCounter = VotingToken.checkpointCounter + 1
            emit CheckPointCreated(newCheckpointId: VotingToken.checkpointCounter)
        } 
    }

    init() {
        self.vaultPath = /storage/CadenceVotingTokenTutorialVault
        self.vaultPublicPath = /public/CadenceVotingTokenTutorialVaultPublic
        self.minterResourcePath = /storage/CadenceVotingTokenTutorialMinter
        self.administratorResourcePath = /storage/CadenceVotingTokenTutorialAdministrator
        self.totalSupply = 0.0
        self.checkpointCounter = 0
        let vault <- self.createEmptyVault()
        self.account.save(<- vault, to: self.vaultPath)
        self.account.save(<- create Minter(), to: self.minterResourcePath)
        self.account.save(<- create Administrator(), to: self.administratorResourcePath)

        // Creating the private capabilities so it can be shared with different accounts
        self.account.link<&VotingToken.Minter>(/private/CadenceVotingTokenTutorialMinterPrivate, target: self.minterResourcePath)
        self.account.link<&VotingToken.Administrator>(/private/CadenceVotingTokenTutorialAdministratorPrivate, target: self.administratorResourcePath)
    }

}