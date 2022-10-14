module Models.Project.Check exposing (Check, clearOrigins, decode, encode, merge)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.List as List
import Models.Project.CheckName as CheckName exposing (CheckName)
import Models.Project.ColumnName as ColumnName exposing (ColumnName)
import Models.Project.Origin as Origin exposing (Origin)
import Services.Lenses exposing (setOrigins)


type alias Check =
    { name : CheckName
    , columns : List ColumnName
    , predicate : Maybe String
    , origins : List Origin
    }


merge : Check -> Check -> Check
merge c1 c2 =
    { name = c1.name
    , columns = List.merge identity ColumnName.merge c1.columns c2.columns
    , predicate = c1.predicate
    , origins = c1.origins ++ c2.origins
    }


clearOrigins : Check -> Check
clearOrigins check =
    check |> setOrigins []


encode : Check -> Value
encode value =
    Encode.notNullObject
        [ ( "name", value.name |> CheckName.encode )
        , ( "columns", value.columns |> Encode.list ColumnName.encode )
        , ( "predicate", value.predicate |> Encode.maybe Encode.string )
        , ( "origins", value.origins |> Encode.list Origin.encode )
        ]


decode : Decode.Decoder Check
decode =
    Decode.map4 Check
        (Decode.field "name" CheckName.decode)
        (Decode.defaultField "columns" (Decode.list ColumnName.decode) [])
        (Decode.maybeField "predicate" Decode.string)
        (Decode.defaultField "origins" (Decode.list Origin.decode) [])
