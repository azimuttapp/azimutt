module Models.User2 exposing (User2, decode)

import Json.Decode as Decode
import Libs.Models.Slug as Slug exposing (Slug)
import Models.UserId exposing (UserId)
import Models.Username as Username exposing (Username)


type alias User2 =
    { id : UserId
    , slug : Slug
    , name : Username
    }


decode : Decode.Decoder User2
decode =
    Decode.map3 User2
        (Decode.field "id" Decode.string)
        (Decode.field "slug" Slug.decode)
        (Decode.field "name" Username.decode)
