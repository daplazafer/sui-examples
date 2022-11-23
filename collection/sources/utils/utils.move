module utils::utils {
    use std::vector;
    use std::ascii::{Self, String};
    use sui::url::{Self, Url};

    const URL_SEPARATOR: vector<u8> = b"/";
    const EXTENSION_SEPARATOR: vector<u8> = b".";

    public fun build_url(url_prefix: vector<u8>, uri: vector<u8>, file_name: vector<u8>, file_format: vector<u8>): Url {
        let url_builder: vector<u8> = vector::empty<u8>();
        vector::append(&mut url_builder, url_prefix);
        vector::append(&mut url_builder, uri);
        vector::append(&mut url_builder, URL_SEPARATOR);
        vector::append(&mut url_builder, file_name); 
        vector::append(&mut url_builder, EXTENSION_SEPARATOR);
        vector::append(&mut url_builder, file_format);
        url::new_unsafe_from_bytes(url_builder)
    }

    public fun u64_to_vector(number: u64): vector<u8>{
        let result = vector::empty<u8>();
        while (number/10 > 0){
            let rem = number%10;
            vector::push_back(&mut result, (rem+48 as u8));
            number = number/10;
        };
        vector::push_back(&mut result, (number+48 as u8));
        vector::reverse(&mut result);
        result
    }

    public fun u64_to_string(number: u64): String {
        ascii::string(u64_to_vector(number))
    }
}