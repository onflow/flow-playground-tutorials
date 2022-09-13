import VotingToken from 0xf8d6e0586b0a20c7

pub fun main() {
  //let votingPower = VotingToken.getRelativeBalance()
  //return votingPower

  let acct1 = getAccount(0x01cf0e2f2f715450)
  let acct2 = getAccount(0x179b6b1cb6755e31)

    // Get references to the account's receivers
    // by getting their public capability
    // and borrowing a reference from the capability
    let acct1Ref = acct1.getCapability(VotingToken.VaultPublicPath)
                            .borrow<&VotingToken.Vault{VotingToken.Balance, VotingToken.VotingPower}>()
                            ?? panic("Could not borrow a reference to the acct1 balance")
    
    let acct2Ref = acct2.getCapability(VotingToken.VaultPublicPath)
                            .borrow<&VotingToken.Vault{VotingToken.Balance, VotingToken.VotingPower}>()
                            ?? panic("Could not borrow a reference to the acct2 balance")
    

    log("Account 1 Balance")
    log(acct1Ref.balance)
    log("Account 2 Balance")
    log(acct2Ref.balance)

    log("total supply")
    log(VotingToken.totalSupply)

    let acct1Power = acct1Ref.votingPowerDataSnapshot
    let acct1PowerLastItem = acct1Power.length > 0 ? acct1Power[acct1Power.length - 1] : nil
    log("Account 1 last recorded balance")
    log(acct1PowerLastItem?.vaultBalance)
    log("Account 1 ts")
    log(acct1PowerLastItem?.blockTs)

    let acct2Power = acct2Ref.votingPowerDataSnapshot
    let acct2PowerLastItem = acct2Power.length > 0 ? acct2Power[acct2Power.length - 1] : nil
    log("Account 2 last recorded balance")
    log(acct2PowerLastItem?.vaultBalance)
    log("Account 2 ts")
    log(acct2PowerLastItem?.blockTs)
}