module utils::payments {
    use std::vector;
    use sui::coin;
    use sui::transfer;
    use sui::pay;
    use sui::tx_context::{Self, TxContext};
    
    const ENoCoins: u64 = 0;

    public fun pay<T>(coins: vector<coin::Coin<T>>, price: u64, recipient: address, ctx: &mut TxContext) {
        assert!(vector::length(&coins) > 0, ENoCoins);

        let coin = vector::pop_back(&mut coins);
        while(!vector::is_empty(&coins)) coin::join(&mut coin, vector::pop_back(&mut coins));
        vector::destroy_empty(coins);
        pay::split_and_transfer<T>(&mut coin, price, recipient, ctx);
        transfer::transfer(coin, tx_context::sender(ctx));
    }
}