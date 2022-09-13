Run the emulator

```console
flow emulator -v
```
Deploy the project in another window
```console
flow project deploy
```
Create two extra accounts ('acct2', 'acct3')
```console
flow accounts create
```
Edit the account section of 'flow.json' like this:
```json
  "accounts": {
    "acct2": {
      "address": "01cf0e2f2f715450",
      "key": {
        "type": "hex",
        "index": 0,
        "signatureAlgorithm": "ECDSA_P256",
        "hashAlgorithm": "SHA3_256",
        "privateKey": "copy-paste_private_key_of_acct2"
      }
    },
    "acct3": {
      "address": "179b6b1cb6755e31",
      "key": {
        "type": "hex",
        "index": 0,
        "signatureAlgorithm": "ECDSA_P256",
        "hashAlgorithm": "SHA3_256",
        "privateKey": "copy-paste_private_key_of_acct3"
      }
    },
    "emulator-account": {
      "address": "f8d6e0586b0a20c7",
      "key": {
        "type": "hex",
        "index": 0,
        "signatureAlgorithm": "ECDSA_P256",
        "hashAlgorithm": "SHA3_256",
        "privateKey": "copy-paste_private_key_of_emulator-account"
      }
    }
  },
```
Once you are in flow.json, make sure that the deployment section contains '"VotingToken", "Voting"'

Create the voter accounts:
```console
flow transactions send transactions/tx_01_SetupAccount.cdc --signer acct2
flow transactions send transactions/tx_01_SetupAccount.cdc --signer acct3
```
Mint tokens to those two accounts:
```console
flow transactions send transactions/tx_02_MintTokens.cdc --signer emulator-account
```
Create the proposals for voting:
```console
flow transactions send transactions/tx_03_CreateNewProposals.cdc --signer emulator-account
```
Optionally - if you want to test the 'voting timestamp > proposal timestamp' requirement, call mint again but change the token amounts (TODO: define the amounts via parameters)

Now we need to create a new ballot. This is a multisign tx, hence takes a couple of steps:
```console
flow transactions build transactions/tx_04_CreateNewBallot.cdc --proposer emulator-account --authorizer emulator-account --authorizer acct2 --payer acct3 --filter payload --save transactions/tx_04_0.rlp
flow transactions sign transactions/tx_04_0.rlp --signer emulator-account --filter payload --save transactions/tx_04_1.rlp
flow transactions sign transactions/tx_04_1.rlp --signer acct2 --filter payload --save transactions/tx_04_2.rlp
flow transactions sign transactions/tx_04_2.rlp --signer acct3 --filter payload --save transactions/tx_04_3.rlp
flow transactions send-signed transactions/tx_04_3.rlp
```
Finally a voter can vote:
```console
flow transactions send transactions/tx_05_SelectAndCastVotes.cdc --signer acct2
```
In order to check both the last recorded balance and timestamp of that balance for the two user accounts, run this:
```console
flow scripts execute scripts/GetVotingPower.cdc
```