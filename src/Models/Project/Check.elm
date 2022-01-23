module Models.Project.Check exposing (Check, decode, encode, merge)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as D
import Libs.Json.Encode as E
import Libs.List as L
import Models.Project.CheckName as CheckName exposing (CheckName)
import Models.Project.ColumnName as ColumnName exposing (ColumnName)
import Models.Project.Origin as Origin exposing (Origin)


type alias Check =
    { name : CheckName
    , columns : List ColumnName
    , predicate : String
    , origins : List Origin
    }


merge : Check -> Check -> Check
merge c1 c2 =
    { name = c1.name
    , columns = L.merge identity ColumnName.merge c1.columns c2.columns
    , predicate = c1.predicate
    , origins = c1.origins ++ c2.origins
    }


encode : Check -> Value
encode value =
    E.notNullObject
        [ ( "name", value.name |> CheckName.encode )
        , ( "columns", value.columns |> E.withDefault (Encode.list ColumnName.encode) [] )
        , ( "predicate", value.predicate |> Encode.string )
        , ( "origins", value.origins |> E.withDefault (Encode.list Origin.encode) [] )
        ]


decode : Decode.Decoder Check
decode =
    Decode.map4 Check
        (Decode.field "name" CheckName.decode)
        (D.defaultField "columns" (Decode.list ColumnName.decode) [])
        (Decode.field "predicate" Decode.string)
        (D.defaultField "origins" (Decode.list Origin.decode) [])
