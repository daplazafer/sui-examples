module collection::set {
    use std::vector;

    struct Set<T:drop > has store, drop, copy {
        elements: vector<T>,
    }

    public fun new<T: drop>(): Set<T> {
        Set<T> { elements: vector::empty<T>() }
    }

    public fun size<T: drop>(set: Set<T>): u64 {
        vector::length(&set.elements)
    }

    public fun contains<T: drop>(set: Set<T>, element: &T): bool {
        vector::contains(&set.elements, element)
    }

    public fun add<T: drop>(set: Set<T>, element: T) {
        if(!vector::contains(&set.elements, &element)) 
            vector::push_back(&mut set.elements, element);
    }

    public fun add_all<T: drop>(set: Set<T>, elements: vector<T>) {
        while(vector::length(&elements) > 0) {
            if(!vector::contains(&set.elements, vector::borrow(&elements, vector::length(&elements) -1))) 
                vector::push_back(&mut set.elements, vector::pop_back(&mut elements));
        }
    }

    public fun remove<T: drop>(set: &mut Set<T>, element: T) {
        let(contains, index) = vector::index_of(&set.elements, &element);
        if(contains) {
            let _ = vector::swap_remove(&mut set.elements, index);
        };
    }

    public fun clear<T: drop>(set: &mut Set<T>) {
        set.elements = vector::empty<T>();
    }

}