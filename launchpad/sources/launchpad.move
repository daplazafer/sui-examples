module launchpad::launchpad {
    use sui::object::{Self, UID};
    use std::string::{Self, String};
    use sui::address;

    fun init(ctx: &mut TxContext) {
        
    }

    public entry fun create_collection(

    ) {

    }

    public entry fun mint(
        collection: &mut Collection, 
        sui_balance: vector<Coin<SUI>>, 
        ctx: &mut TxContext,
    ) {
        assert!(collection.minted < collection.max_supply, ESoldOut);

        let (sender_whitelisted, price) = get_price(collection, ctx);

        pay(sui_balance, price, collection.owner, ctx);

        let nft = Nft {
            id: object::new(ctx),
            name: collection.name,
            description: collection.description,
            url: url(vector[IPFS_FOLDER_URL, int_to_bytes(collection.minted), NFT_FILE_FORMAT]),
        };

        transfer::transfer(nft, tx_context::sender(ctx));

        collection.minted = collection.minted + 1;

        if (sender_whitelisted) set::remove(&mut collection.whitelist, &tx_context::sender(ctx));
    }

    fun get_price(collection: &mut Collection, ctx: &mut TxContext): (bool, u64) { 

        let sender_whitelisted = false;
        let price = collection.price;

        if(collection.release > tx_context::epoch(ctx)) {
            sender_whitelisted = set::contains(&collection.whitelist, &tx_context::sender(ctx));
            assert!(sender_whitelisted, ESenderNotInWhitelist);
            price = collection.price_whitelist;
        };

        (sender_whitelisted, price)
    }
    
}