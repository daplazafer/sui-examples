# **NFT collection example**

### ***To rename entire collection objects replace `NftNameHere` with your collection name in collection.move*

## **1. Deploy contract**
* Install [sui](https://docs.sui.io/devnet/learn) and run this command to deploy contract on the blockchain:
```
$ sui client publish --gas-budget 10000
```
* Keep `0xcollection_cap`, `0xcollection` and `0xcontract_address` listed bellow to interact with the contract.
```
----- Transaction Effects ----
Status : Success
Created Objects:
  - ID: 0xcollection_cap , Owner: Account Address ( 0xcontract_owner )
  - ID: 0xcollection , Owner: Shared
  - ID: 0xcontract_address , Owner: Immutable
```
## **2. Interact with the contract**
### **2.1 User priviledges**
Everyone can use these functions.
* ### **Mint NFT (`mint`)**
  Mint NFT of this collection.
  * **$1:** Collection address
  * **$2:** Array with sui addresses of the sender
```
$ sui client call --package 0xcontract_address --module "collection" --function "add_to_whitelist" --args 0xcollection_cap 0xcollection "[\"0xsui1\", \"0xsui2\"]" --gas-budget 10000
```
* ### **Reveal NFT (`reveal`)**
  Reveal the NFT if you are the owner. Only available if the collection has been deployed with `MINT_REVEALED=false` parameter.
  * **$1:** NFT address
```
$ sui client call --package 0xcontract_address --module "collection" --function "reveal" --args 0xnft_address --gas-budget 10000
```
### **2.2 Cap priviledges**
Only the owner (deployer) has priviledges to use these functions. The collection cap is needed to call every function in this list.
* ### **Add users to whitelist (`add_to_whitelist`)**
  Add users to whitelist.
  * **$1:** Collection cap address
  * **$2:** Collection address
  * **$3:** Array with addresses
```
$ sui client call --package 0xcontract_address --module "collection" --function "add_to_whitelist" --args 0xcollection_cap 0xcollection "[\"0xaddress1\", \"0xaddress2\"]" --gas-budget 10000
```