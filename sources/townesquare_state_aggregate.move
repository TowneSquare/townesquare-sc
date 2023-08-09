// <autogenerated>
//   This file was generated by dddappp code generator.
//   Any changes made to this file manually will be lost next time the file is regenerated.
// </autogenerated>

module townesquare_sc::townesquare_state_aggregate {
    use townesquare_sc::townesquare_state;
    use townesquare_sc::townesquare_state_create_logic;
    use townesquare_sc::townesquare_state_delete_logic;
    use townesquare_sc::townesquare_state_update_logic;

    public entry fun create(
        account: &signer,
        is_emergency: bool,
        user_admin: address,
        post_admin: address,
    ) {
        let townesquare_state_created = townesquare_state_create_logic::verify(
            account,
            is_emergency,
            user_admin,
            post_admin,
        );
        let townesquare_state = townesquare_state_create_logic::mutate(
            account,
            &townesquare_state_created,
        );
        townesquare_state::add_townesquare_state(townesquare_state);
        townesquare_state::emit_townesquare_state_created(townesquare_state_created);
    }

    public entry fun update(
        account: &signer,
        is_emergency: bool,
        user_admin: address,
        post_admin: address,
    ) {
        let townesquare_state = townesquare_state::remove_townesquare_state();
        let townesquare_state_updated = townesquare_state_update_logic::verify(
            account,
            is_emergency,
            user_admin,
            post_admin,
            &townesquare_state,
        );
        let updated_townesquare_state = townesquare_state_update_logic::mutate(
            account,
            &townesquare_state_updated,
            townesquare_state,
        );
        townesquare_state::update_version_and_add(updated_townesquare_state);
        townesquare_state::emit_townesquare_state_updated(townesquare_state_updated);
    }

    public entry fun delete(
        account: &signer,
    ) {
        let townesquare_state = townesquare_state::remove_townesquare_state();
        let townesquare_state_deleted = townesquare_state_delete_logic::verify(
            account,
            &townesquare_state,
        );
        let updated_townesquare_state = townesquare_state_delete_logic::mutate(
            account,
            &townesquare_state_deleted,
            townesquare_state,
        );
        townesquare_state::drop_townesquare_state(updated_townesquare_state);
        townesquare_state::emit_townesquare_state_deleted(townesquare_state_deleted);
    }

}
