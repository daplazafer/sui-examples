module simplenftcollection::collection {
    use std::string::{Self, String};
    use std::vector;
    use sui::url::{Self, Url};
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use sui::pay;
    
    // ===== Collection parameters =====
    
    const MAX_SUPPLY: u64 = 100;
    const PRICE: u64 = 100000000;  
    const RELEASE: u64 = 0;
    const NFT_NAME: vector<u8> = b"NftNameHere";
    const NFT_DESCRIPTION: vector<u8> = b"NftNameHere Nft";
    const IPFS_FOLDER_URL: vector<u8> = b"ipfs://bafybeiaetnhmscuk6nqdnk4lvh6lxeadehfo342pszyqdodqoodtld77v4/";
    const NFT_FILE_FORMAT: vector<u8> = b".png";
    
    const ESoldOut: u64 = 0;
    const ECollectionNotReleasedYet: u64 = 1;
    const ENoCoins: u64 = 2;

    struct NftNameHereCollection has key {
        id: UID,
        owner: address,
        minted: u64,
        price: u64,
        release: u64,
    }

    struct NftNameHereNft has key, store {
        id: UID,
        name: String,
        description: String,
        url: Url,
    }

    fun init(ctx: &mut TxContext) {
        transfer::share_object(NftNameHereCollection {
            id: object::new(ctx),
            owner: tx_context::sender(ctx),
            minted: 0,
            price: PRICE,
            release: RELEASE,
        });
    }

    public entry fun mint(
        collection: &mut NftNameHereCollection, 
        sui_balance: vector<Coin<SUI>>, 
        ctx: &mut TxContext
    ) {
        assert!(collection.release < tx_context::epoch(ctx), ECollectionNotReleasedYet);
        assert!(collection.minted < MAX_SUPPLY, ESoldOut);

        pay(sui_balance, collection.price, collection.owner, ctx);

        transfer::transfer(NftNameHereNft {
            id: object::new(ctx),
            name: string::utf8(NFT_NAME),
            description: string::utf8(NFT_DESCRIPTION),
            url: url(vector[IPFS_FOLDER_URL, int_to_bytes(collection.minted), NFT_FILE_FORMAT]),
        }, tx_context::sender(ctx));

        collection.minted = collection.minted + 1;
    }

    fun int_to_bytes(int: u64): vector<u8>{
        let bytes = vector::empty<u8>();
        while (int / 10 > 0){
            let rem = int%10;
            vector::push_back(&mut bytes, (rem+48 as u8));
            int = int/10;
        };
        vector::push_back(&mut bytes, (int+48 as u8));
        vector::reverse(&mut bytes);
        bytes
    }

    fun pay<T>(coins: vector<Coin<T>>, price: u64, recipient: address, ctx: &mut TxContext) {
        assert!(vector::length(&coins) > 0, ENoCoins);

        let coin = vector::pop_back(&mut coins);
        while(!vector::is_empty(&coins)) coin::join(&mut coin, vector::pop_back(&mut coins));
        vector::destroy_empty(coins);
        pay::split_and_transfer<T>(&mut coin, price, recipient, ctx);
        transfer::transfer(coin, tx_context::sender(ctx));
    }

    fun url(parts: vector<vector<u8>>): Url{
        vector::reverse(&mut parts);
        let builder = vector::empty<u8>();
        while(!vector::is_empty(&parts)) {
            let part = vector::pop_back(&mut parts);
            vector::append(&mut builder, part);
        };
        vector::destroy_empty(parts);
        url::new_unsafe_from_bytes(builder)
    }
}