module Models.User2 exposing (User2, decode)

import Json.Decode as Decode
import Libs.Json.Decode as Decode
import Libs.Models.Email as Email exposing (Email)
import Libs.Models.Slug as Slug exposing (Slug)
import Libs.Time as Time
import Models.UserId exposing (UserId)
import Models.Username as Username exposing (Username)
import Time


type alias User2 =
    { id : UserId
    , slug : Slug
    , name : Username
    , email : Email
    , avatar : String
    , company : Maybe String
    , location : Maybe String
    , description : Maybe String
    , github : Maybe Username
    , twitter : Maybe Username
    , isAdmin : Bool
    , lastSignedIn : Time.Posix
    , createdAt : Time.Posix
    }


decode : Decode.Decoder User2
decode =
    Decode.map13 User2
        (Decode.field "id" Decode.string)
        (Decode.field "slug" Slug.decode)
        (Decode.field "name" Username.decode)
        (Decode.field "email" Email.decode)
        (Decode.field "avatar" Decode.string)
        (Decode.maybeField "company" Decode.string)
        (Decode.maybeField "location" Decode.string)
        (Decode.maybeField "description" Decode.string)
        (Decode.maybeField "github_username" Username.decode)
        (Decode.maybeField "twitter_username" Username.decode)
        (Decode.field "is_admin" Decode.bool)
        (Decode.field "last_signin" Time.decode)
        (Decode.field "created_at" Time.decode)
