// <autogenerated>
//   This file was generated by dddappp code generator.
//   Any changes made to this file manually will be lost next time the file is regenerated.
// </autogenerated>

module townesquare_sc::user_updated {

    use std::string::String;
    use townesquare_sc::user::{Self, UserUpdated};

    public fun user_wallet(user_updated: &UserUpdated): address {
        user::user_updated_user_wallet(user_updated)
    }

    public fun username(user_updated: &UserUpdated): String {
        user::user_updated_username(user_updated)
    }

    public fun profile_image(user_updated: &UserUpdated): String {
        user::user_updated_profile_image(user_updated)
    }

    public fun bio(user_updated: &UserUpdated): String {
        user::user_updated_bio(user_updated)
    }

}
