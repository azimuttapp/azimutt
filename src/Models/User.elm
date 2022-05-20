module Models.User exposing (User, UserId, Username, decode)

import Json.Decode as Decode
import Libs.Json.Decode as Decode
import Libs.Models.Email exposing (Email)


type alias UserId =
    String


type alias Username =
    String


type alias User =
    { id : UserId
    , email : Email
    , username : Username
    , name : String
    , avatar : Maybe String
    , bio : Maybe String
    , company : Maybe String
    , location : Maybe String
    , website : Maybe String
    , github : Maybe String
    , twitter : Maybe String
    }


decode : Decode.Decoder User
decode =
    Decode.map11 User
        (Decode.field "id" Decode.string)
        (Decode.field "email" Decode.string)
        (Decode.field "username" Decode.string)
        (Decode.field "name" Decode.string)
        (Decode.maybeField "avatar" Decode.string)
        (Decode.maybeField "bio" Decode.string)
        (Decode.maybeField "company" Decode.string)
        (Decode.maybeField "location" Decode.string)
        (Decode.maybeField "website" Decode.string)
        (Decode.maybeField "github" Decode.string)
        (Decode.maybeField "twitter" Decode.string)
