module Models.Project.Check exposing (Check, decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Models.Project.CheckName as CheckName exposing (CheckName)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath)


type alias Check =
    { name : CheckName
    , columns : List ColumnPath
    , predicate : Maybe String
    }


encode : Check -> Value
encode value =
    Encode.notNullObject
        [ ( "name", value.name |> CheckName.encode )
        , ( "columns", value.columns |> Encode.list ColumnPath.encode )
        , ( "predicate", value.predicate |> Encode.maybe Encode.string )
        ]


decode : Decode.Decoder Check
decode =
    Decode.map3 Check
        (Decode.field "name" CheckName.decode)
        (Decode.defaultField "columns" (Decode.list ColumnPath.decode) [])
        (Decode.maybeField "predicate" Decode.string)
