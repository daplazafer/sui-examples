module coinflip::random {
    use std::hash::sha2_256;
    use std::vector;
    use sui::tx_context::{Self, TxContext};
    
    public fun generate(mod: u64, ctx: &mut TxContext): u64 {
        let seed = tx_context::epoch(ctx);
        let hash = sha2_256(int_to_bytes(seed));
        module_operation(hash, mod)
    }

    fun int_to_bytes(int: u64): vector<u8> {
        let bytes = vector::empty<u8>();
        while (int / 10 > 0){
            let rem = int % 10;
            vector::push_back(&mut bytes, (rem + 48 as u8));
            int = int / 10;
        };
        vector::push_back(&mut bytes, (int + 48 as u8));
        vector::reverse(&mut bytes);
        bytes
    }

    fun module_operation(bytes: vector<u8>, mod: u64): u64 {
        let len = vector::length(&bytes);
        let int_value: u128 = 0;
        let i = 0;
        while (i < len) {
            int_value = int_value << 8;
            let current_byte = *vector::borrow(&bytes, i);
            int_value = int_value + (current_byte as u128);
            i = i + 1;
        };
        let result  = int_value % (mod as u128);
        (result as u64)
    }
}