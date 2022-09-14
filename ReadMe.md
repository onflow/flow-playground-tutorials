Run the emulator

```console
flow emulator
```
Deploy the project in another window
```console
flow project deploy
```
Create two extra accounts ('acct2', 'acct3')
```console
flow accounts create
```

Once you are in flow.json, make sure that the deployment section contains '"GovernanceToken", "Voting"'

Create the voter accounts:
```console
flow transactions send transactions/tx_01_SetupAccount.cdc --signer acct2
flow transactions send transactions/tx_01_SetupAccount.cdc --signer acct3
```
Mint tokens to those two accounts:
```console
flow transactions send transactions/tx_02_MintTokens.cdc "0x01cf0e2f2f715450" "0x179b6b1cb6755e31" 30.0 150.0 --signer emulator-account
```
Optionally - if you want to test the 'voting timestamp > proposal timestamp' requirement, call mint again but change the token amounts

Create the proposals for voting:
```console
flow transactions send transactions/tx_03_CreateNewProposals.cdc --signer emulator-account
```

Now we need to create a new ballot.
Create the proposals for voting:
```console
flow transactions send transactions/tx_04_CreateNewBallot.cdc --signer acct2
flow transactions send transactions/tx_04_CreateNewBallot.cdc --signer acct3
```
Finally a voter can vote by passing a proposalId "1":
```console
flow transactions send transactions/tx_05_SelectAndCastVotes.cdc "1" --signer acct2
```
In order to check both the last recorded balance and timestamp of that balance for the two user accounts, run this:
```console
flow scripts execute scripts/GetVotingWeight.cdc "0x01cf0e2f2f715450" "0x179b6b1cb6755e31"
```