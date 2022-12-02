# **Coinflip example**

## **1. Deploy contract**
* Install [sui](https://docs.sui.io/devnet/learn) and run this command to deploy contract on the blockchain:
```
$ sui client publish --gas-budget 10000
```
* Keep `0xcasino_cap`, `0xcasino` and `0xcontract_address` listed bellow to interact with the contract.
```
----- Transaction Effects ----
Status : Success
Created Objects:
  - ID: 0xcasino_cap , Owner: Account Address ( 0xcontract_owner )
  - ID: 0xcasino , Owner: Shared
  - ID: 0xcontract_address , Owner: Immutable
```
## **2. Interact with the contract**

* ### **Flip coin (`flip`)**
  Mint NFT of this collection.
  * **$1:** Collection address
  * **$2:** Array with sui addresses of the sender
  * **$3:** Amount to bet
```
$ sui client call --package 0xcontract_address --module "casino" --function "flip" --args 0xcasino_cap 0xcasino "[\"0xsui1\", \"0xsui2\"]" bet --gas-budget 10000
```