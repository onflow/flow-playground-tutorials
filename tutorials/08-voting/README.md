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

Make sure that the deployment section in 'flow.json' contains 'FungibleToken', 'VotingTutorialGovernanceToken' and 'VotingTutorialAdministration'.

Create the voter accounts:
```console
flow transactions send transactions/tx_01_SetupAccount.cdc --signer acct2
flow transactions send transactions/tx_01_SetupAccount.cdc --signer acct3
```

Mint tokens to those two accounts:
```console
flow transactions send transactions/tx_02_MintTokens.cdc "0x01cf0e2f2f715450" "0x179b6b1cb6755e31" 30.0 150.0 --signer emulator-account
```

Create the proposals for voting:
```console
flow transactions send transactions/tx_03_CreateNewProposals.cdc --signer emulator-account
```

Optionally - if you want to test the 'voting timestamp > proposal timestamp' requirement, call mint again but change the token amounts.
This minting will not affect the voting weight, as it happened after the proposal was established.

Now we need to create new ballots.
```console
flow transactions send transactions/tx_04_CreateNewBallot.cdc --signer acct2
flow transactions send transactions/tx_04_CreateNewBallot.cdc --signer acct3
```

Finally a voter can vote by passing the proposal and option id (in the first case for the first proposal and the third option, in the second case for the second proposal and the first option):
```console
flow transactions send transactions/tx_05_SelectAndCastVotes.cdc "0" "2" --signer acct2
flow transactions send transactions/tx_05_SelectAndCastVotes.cdc "1" "0" --signer acct3
```

In order to check both the last recorded balance and timestamp of the balance for the two user accounts, run this:
```console
flow scripts execute scripts/GetVotingWeight.cdc "0x01cf0e2f2f715450" "0x179b6b1cb6755e31"
```

In order to see the recorded proposals outcome, run this:
```console
flow scripts execute scripts/GetProposalsData.cdc
```
