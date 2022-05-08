module Models.User exposing (User, decode)

import Json.Decode as Decode


type alias User =
    { id : String
    , username : String
    , name : String
    , email : String
    , avatar : String
    , role : String
    , provider : String
    }


decode : Decode.Decoder User
decode =
    Decode.map7 User
        (Decode.field "id" Decode.string)
        (Decode.field "username" Decode.string)
        (Decode.field "name" Decode.string)
        (Decode.field "email" Decode.string)
        (Decode.field "avatar" Decode.string)
        (Decode.field "role" Decode.string)
        (Decode.field "provider" Decode.string)
