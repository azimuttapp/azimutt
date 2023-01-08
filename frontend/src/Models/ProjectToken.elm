module Models.ProjectToken exposing (ProjectToken, decode)

import Json.Decode as Decode exposing (Decoder)
import Libs.Json.Decode as Decode
import Libs.Models.Uuid as Uuid exposing (Uuid)
import Libs.Time as Time
import Models.User as User exposing (UserLight)
import Time


type alias ProjectToken =
    { id : Uuid
    , name : String
    , nbAccess : Int
    , lastAccess : Maybe Time.Posix
    , expireAt : Maybe Time.Posix
    , createdAt : Time.Posix
    , createdBy : UserLight
    }


decode : Decoder ProjectToken
decode =
    Decode.map7 ProjectToken
        (Decode.field "id" Uuid.decode)
        (Decode.field "name" Decode.string)
        (Decode.field "nb_access" Decode.int)
        (Decode.maybeField "last_access" Time.decode)
        (Decode.maybeField "expire_at" Time.decode)
        (Decode.field "created_at" Time.decode)
        (Decode.field "created_by" User.decodeLight)
