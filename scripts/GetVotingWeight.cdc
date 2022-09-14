import FungibleToken from 0xf8d6e0586b0a20c7
import GovernanceToken from 0xf8d6e0586b0a20c7

pub fun main(account1: Address, account2: Address) {
  //let votingWeight = GovernanceToken.getRelativeBalance()
  //return votingWeight

  let acct1 = getAccount(account1)
  let acct2 = getAccount(account2)

    // Get references to the account's receivers
    // by getting their public capability
    // and borrowing a reference from the capability
    let acct1BalanceRef = acct1.getCapability(GovernanceToken.VaultPublicPath)
                            .borrow<&AnyResource{FungibleToken.Balance}>()
                            ?? panic("Could not borrow a reference to the acct1 balance")

    let acct2BalanceRef = acct2.getCapability(GovernanceToken.VaultPublicPath)
                            .borrow<&AnyResource{FungibleToken.Balance}>()
                            ?? panic("Could not borrow a reference to the acct2 balance")

    let acct1VoteWeightRef = acct1.getCapability(GovernanceToken.VaultPublicPath)
                            .borrow<&AnyResource{GovernanceToken.VotingWeight}>()
                            ?? panic("Could not borrow a reference to the acct1 voting weight")

    let acct2VoteWeightRef = acct2.getCapability(GovernanceToken.VaultPublicPath)
                            .borrow<&AnyResource{GovernanceToken.VotingWeight}>()
                            ?? panic("Could not borrow a reference to the acct2 voting weight")


    log("Account 1 Balance")
    log(acct1BalanceRef.balance)
    log("Account 2 Balance")
    log(acct2BalanceRef.balance)

    log("total supply")
    log(GovernanceToken.totalSupply)

    let acct1Weight = acct1VoteWeightRef.votingWeightDataSnapshot
    let acct1WeightLastItem = acct1Weight.length > 0 ? acct1Weight[acct1Weight.length - 1] : nil
    log("Account 1 last recorded balance")
    log(acct1WeightLastItem?.vaultBalance)
    log("Account 1 ts")
    log(acct1WeightLastItem?.blockTs)

    let acct2Weight = acct2VoteWeightRef.votingWeightDataSnapshot
    let acct2WeightLastItem = acct2Weight.length > 0 ? acct2Weight[acct2Weight.length - 1] : nil
    log("Account 2 last recorded balance")
    log(acct2WeightLastItem?.vaultBalance)
    log("Account 2 ts")
    log(acct2WeightLastItem?.blockTs)
}