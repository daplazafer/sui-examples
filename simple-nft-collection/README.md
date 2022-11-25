# **Simple NFT collection example**

### ***To rename entire collection objects replace `NftNameHere` with your collection name in collection.move*

## **1. Deploy contract**
* Install [sui](https://docs.sui.io/devnet/learn) and run this command to deploy contract on the blockchain:
```
$ sui client publish --gas-budget 10000
```
* Keep `0xcollection` and `0xcontract_address` listed bellow to interact with the contract.
```
----- Transaction Effects ----
Status : Success
Created Objects:
  - ID: 0xcollection , Owner: Shared
  - ID: 0xcontract_address , Owner: Immutable
```
## **2. Interact with the contract**
* ### **Mint NFT (`mint`)**
  Mint NFT of this collection.
  * **$1:** Collection address
  * **$2:** Array with sui addresses of the sender
```
$ sui client call --package 0xcontract_address --module "collection" --function "mint" --args 0xcollection_cap 0xcollection "[\"0xsui1\", \"0xsui2\"]" --gas-budget 10000
```