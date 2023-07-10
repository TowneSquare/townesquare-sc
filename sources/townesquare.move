module townesquare_sc::townesquare {
    use aptos_framework::event;
    use aptos_framework::account;
    use aptos_std::table::{Self, Table};
    use std::string::{Self, String};
    use std::signer;

    // Errors
    const E_NOT_INITIALIZED: u64 = 1;
    const EPOST_DOESNT_EXIST: u64 = 2;
    const EPOST_IS_DELETED: u64 = 3;
    const ENOT_GENESIS_ACCOUNT: u64 = 4;
    const EINVALID_ACCOUNT: u64 = 5;
    const EUSER_DOESNT_EXIST: u64 = 6;
    const E_IS_EMERGENCY: u64 = 7;

    struct TownesquareState has key {
        is_emergency: bool // if is_emergency is true, we can't do anyaction
    }

    struct UserList has key {
        users: Table<address, User>, // users list
    }

    struct User has store, drop, copy {
        user_wallet: address, // User wallet address
        username: String, // username is unique id of townesquare app
        profile_image: String, // This is link of profile image of user
        bio: String, // users's bio
    }

    struct PostList has key {
        admin: address, // admin address
        posts: Table<u128, Post>, // Post list which posted by poster
    }

    struct Post has store, drop, copy {
        poster: address, // poster address
        user_id: String, // user id of our database. It should be string
        post_id: u128, // post_id is generated by on-chain
        content: String, // encryption string of content
        is_deleted: bool, // not sure that this field is neccessary or not
        digest: String
    }

    struct EventHandles has key {
        post_event_handle: event::EventHandle<Post>, // Post Events
        user_event_handle: event::EventHandle<User>, // User Events
    }

    struct PostIdGenerator has key {
        sequence: u128, // post sequence
    }

    // initialize all state variables under genesis account
    public fun initialize(admin: &signer) {
        let admin_address = signer::address_of(admin);
        assert!(admin_address == @townesquare, ENOT_GENESIS_ACCOUNT);
        let post_id_generator = PostIdGenerator {
            sequence: 0,
        };
        move_to(admin, post_id_generator);

        move_to(admin, EventHandles {
            post_event_handle: account::new_event_handle<Post>(admin),
            user_event_handle: account::new_event_handle<User>(admin),
        });

        let user_list = UserList {
            users: table::new(),
        };
        move_to(admin, user_list);

        let post_list = PostList {
            admin: admin_address,
            posts: table::new(),
        };
        move_to(admin, post_list);

        let townesuqare_state = TownesquareState {
            is_emergency: false
        };
        move_to(admin, townesuqare_state);
    }
    
    fun next_post_id(
        post_id_generator: &mut PostIdGenerator,
    ): u128 {
        post_id_generator.sequence = post_id_generator.sequence + 1;
        post_id_generator.sequence
    }

    public(friend) fun emit_post_event(post_event: Post) acquires EventHandles {
        let events = borrow_global_mut<EventHandles>(@townesquare);
        event::emit_event(&mut events.post_event_handle, post_event);
    }

    public(friend) fun emit_user_event(user_event: User) acquires EventHandles {
        let events = borrow_global_mut<EventHandles>(@townesquare);
        event::emit_event(&mut events.user_event_handle, user_event);
    }

    public entry fun update_emergency(admin: &signer) acquires TownesquareState {
        assert!(signer::address_of(admin) == @townesquare, ENOT_GENESIS_ACCOUNT);
        let townesuqare_state = borrow_global_mut<TownesquareState>(@townesquare);
        townesuqare_state.is_emergency = !townesuqare_state.is_emergency;
    }

    public entry fun create_user(user: &signer, username: String, profile_image: String, bio: String) acquires TownesquareState, UserList, EventHandles {
        // check emergency
        let townesuqare_state = borrow_global_mut<TownesquareState>(@townesquare);
        assert!(townesuqare_state.is_emergency == false, E_IS_EMERGENCY);

         // get the signer address
        let user_address = signer::address_of(user);
        assert!(exists<UserList>(@townesquare), E_NOT_INITIALIZED);

        // get the UserList resource
        let user_list = borrow_global_mut<UserList>(@townesquare);
        let new_user = User {
            user_wallet: user_address,
            username,
            profile_image,
            bio
        };
        table::upsert(&mut user_list.users, user_address, new_user);

        // emit user event
        emit_user_event(new_user);
    }

    public entry fun update_user(user: &signer, username: String, profile_image: String, bio: String) acquires TownesquareState, UserList, EventHandles {
        // check emergency
        let townesuqare_state = borrow_global_mut<TownesquareState>(@townesquare);
        assert!(townesuqare_state.is_emergency == false, E_IS_EMERGENCY);

        // get the signer address
        let user_address = signer::address_of(user);
        assert!(exists<UserList>(@townesquare), E_NOT_INITIALIZED);

        // get UserList resource
        let user_list = borrow_global_mut<UserList>(@townesquare);
        assert!(table::contains(&user_list.users, user_address), EUSER_DOESNT_EXIST);
        let user = table::borrow_mut(&mut user_list.users, user_address);
        // update username/profile_image/bio
        if (username != string::utf8(b"")) {
            user.username = username;
        };
        if (profile_image != string::utf8(b"")) {
            user.profile_image = profile_image;
        };
        if (bio != string::utf8(b"")) {
            user.bio = bio;
        };

        // emit user event
        emit_user_event(*user);
    }

    public entry fun create_post(poster: &signer, user_id: String, content: String, digest: String) acquires TownesquareState, UserList, PostList, PostIdGenerator, EventHandles {
        // check emergency
        let townesuqare_state = borrow_global_mut<TownesquareState>(@townesquare);
        assert!(townesuqare_state.is_emergency == false, E_IS_EMERGENCY);

        // get the signer address
        let poster_address = signer::address_of(poster);

        // check poster register userprofile on-chain
        assert!(exists<UserList>(@townesquare), E_NOT_INITIALIZED);
        let user_list = borrow_global_mut<UserList>(@townesquare);
        assert!(table::contains(&user_list.users, poster_address), EUSER_DOESNT_EXIST);

        // get the PostList resource
        assert!(exists<PostList>(@townesquare), E_NOT_INITIALIZED);
        let post_list = borrow_global_mut<PostList>(@townesquare);

        // generate post_id
        assert!(exists<PostIdGenerator>(@townesquare), E_NOT_INITIALIZED);
        let post_id_generator = borrow_global_mut<PostIdGenerator>(@townesquare);
        let post_id = next_post_id(post_id_generator);

        // add post on-chain
        let new_post = Post {
            poster: poster_address,
            user_id,
            post_id,
            content,
            is_deleted: false,
            digest
        };
        table::upsert(&mut post_list.posts, post_id, new_post);

        // emit post event
        emit_post_event(new_post);
    }

    public entry fun delete_post(poster: &signer, post_id: u128) acquires TownesquareState, PostList, EventHandles {
        // check emergency
        let townesuqare_state = borrow_global_mut<TownesquareState>(@townesquare);
        assert!(townesuqare_state.is_emergency == false, E_IS_EMERGENCY);

        // get the signer address
        let poster_address = signer::address_of(poster);
        assert!(exists<PostList>(@townesquare), E_NOT_INITIALIZED);
        
        // get the PostList resource
        let post_list = borrow_global_mut<PostList>(@townesquare);
        assert!(table::contains(&post_list.posts, post_id), EPOST_DOESNT_EXIST);
        let post = table::borrow_mut(&mut post_list.posts, post_id);
        assert!(post.is_deleted == false, EPOST_IS_DELETED);
        assert!(post.poster == poster_address || poster_address == post_list.admin, EINVALID_ACCOUNT);
        post.is_deleted = true;

        emit_post_event(*post);
    } 
}
