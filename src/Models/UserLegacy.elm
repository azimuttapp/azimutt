module Models.UserLegacy exposing (UserLegacy, avatar, decode, encode)

import Conf
import Json.Decode as Decode exposing (Value)
import Json.Encode as Encode
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.Models.Email as Email exposing (Email)
import Libs.Models.Website as Website exposing (Website)
import Libs.String as String
import Models.UserId as UserId exposing (UserId)
import Models.Username as Username exposing (Username)



-- TODO: remove user as well as project sharing (handled in backend)


type alias UserLegacy =
    { id : UserId
    , username : Username
    , email : Email
    , name : String
    , avatar : Maybe String
    , bio : Maybe String
    , company : Maybe String
    , location : Maybe String
    , website : Maybe Website
    , github : Maybe Username
    , twitter : Maybe Username
    }


avatar : UserLegacy -> String
avatar user =
    user.avatar |> Maybe.withDefault (Conf.constants.externalAssets ++ "/funny-cartoon-monsters/" ++ (user.email |> String.hashCode |> modBy 40 |> String.fromInt) ++ ".jpg")


encode : UserLegacy -> Value
encode value =
    Encode.notNullObject
        [ ( "id", value.id |> UserId.encode )
        , ( "username", value.username |> Username.encode )
        , ( "email", value.email |> Email.encode )
        , ( "name", value.name |> Encode.string )
        , ( "avatar", value.avatar |> Encode.maybe Encode.string )
        , ( "bio", value.bio |> Encode.maybe Encode.string )
        , ( "company", value.company |> Encode.maybe Encode.string )
        , ( "location", value.location |> Encode.maybe Encode.string )
        , ( "website", value.website |> Encode.maybe Website.encode )
        , ( "github", value.github |> Encode.maybe Username.encode )
        , ( "twitter", value.twitter |> Encode.maybe Username.encode )
        ]


decode : Decode.Decoder UserLegacy
decode =
    Decode.map11 UserLegacy
        (Decode.field "id" Decode.string)
        (Decode.field "username" Username.decode)
        (Decode.field "email" Email.decode)
        (Decode.field "name" Decode.string)
        (Decode.maybeField "avatar" Decode.string)
        (Decode.maybeField "bio" Decode.string)
        (Decode.maybeField "company" Decode.string)
        (Decode.maybeField "location" Decode.string)
        (Decode.maybeField "website" Website.decode)
        (Decode.maybeField "github" Username.decode)
        (Decode.maybeField "twitter" Username.decode)
