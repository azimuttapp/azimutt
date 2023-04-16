module Models.User exposing (User, UserLight, decode, decodeLight)

import Json.Decode as Decode exposing (Decoder)
import Libs.Json.Decode as Decode
import Libs.Models.Email as Email exposing (Email)
import Libs.Time as Time
import Models.UserId as UserId exposing (UserId)
import Models.UserSlug as UserSlug exposing (UserSlug)
import Models.Username as Username exposing (Username)
import Time


type alias User =
    { id : UserId
    , slug : UserSlug
    , name : Username
    , email : Email
    , avatar : String
    , github : Maybe Username
    , twitter : Maybe Username
    , isAdmin : Bool
    , lastSignedIn : Time.Posix
    , createdAt : Time.Posix
    }


type alias UserLight =
    { id : UserId
    , slug : UserSlug
    , name : Username
    , email : Email
    , avatar : String
    , github : Maybe Username
    , twitter : Maybe Username
    }


decode : Decoder User
decode =
    Decode.map10 User
        (Decode.field "id" UserId.decode)
        (Decode.field "slug" UserSlug.decode)
        (Decode.field "name" Username.decode)
        (Decode.field "email" Email.decode)
        (Decode.field "avatar" Decode.string)
        (Decode.maybeField "github_username" Username.decode)
        (Decode.maybeField "twitter_username" Username.decode)
        (Decode.field "is_admin" Decode.bool)
        (Decode.field "last_signin" Time.decode)
        (Decode.field "created_at" Time.decode)


decodeLight : Decoder UserLight
decodeLight =
    Decode.map7 UserLight
        (Decode.field "id" UserId.decode)
        (Decode.field "slug" UserSlug.decode)
        (Decode.field "name" Username.decode)
        (Decode.field "email" Email.decode)
        (Decode.field "avatar" Decode.string)
        (Decode.maybeField "github_username" Username.decode)
        (Decode.maybeField "twitter_username" Username.decode)
