module Models.Plan exposing (Plan, decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Encode as Encode


type alias Plan =
    { id : String
    , name : String
    , layouts : Int
    , colors : Bool
    , dbAnalysis : Bool
    , dbAccess : Bool
    }


encode : Plan -> Value
encode value =
    Encode.notNullObject
        [ ( "id", value.name |> Encode.string )
        , ( "name", value.name |> Encode.string )
        , ( "layouts", value.layouts |> Encode.int )
        , ( "colors", value.colors |> Encode.bool )
        , ( "db_analysis", value.dbAnalysis |> Encode.bool )
        , ( "db_access", value.dbAccess |> Encode.bool )
        ]


decode : Decode.Decoder Plan
decode =
    Decode.map6 Plan
        (Decode.field "id" Decode.string)
        (Decode.field "name" Decode.string)
        (Decode.field "layouts" Decode.int)
        (Decode.field "colors" Decode.bool)
        (Decode.field "db_analysis" Decode.bool)
        (Decode.field "db_access" Decode.bool)
