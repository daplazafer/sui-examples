module nftcollection::time_lock {
    use sui::tx_context::{Self, TxContext};
    
    struct TimeLock has store, copy {
        epoch: u64
    }

    public fun new(epoch: u64) : TimeLock {
        TimeLock { epoch }
    }

    public fun is_locked(lock: TimeLock, ctx: &mut TxContext): bool {
        let TimeLock { epoch } = lock;
        tx_context::epoch(ctx) < epoch
    }
}