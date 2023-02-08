module Models.Project.Index exposing (Index, clearOrigins, decode, encode, merge)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.Nel as Nel exposing (Nel)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath)
import Models.Project.IndexName as IndexName exposing (IndexName)
import Models.Project.Origin as Origin exposing (Origin)
import Services.Lenses exposing (setOrigins)


type alias Index =
    { name : IndexName
    , columns : Nel ColumnPath
    , definition : Maybe String
    , origins : List Origin
    }


merge : Index -> Index -> Index
merge i1 i2 =
    { name = i1.name
    , columns = Nel.merge ColumnPath.toString ColumnPath.merge i1.columns i2.columns
    , definition = i1.definition
    , origins = i1.origins ++ i2.origins
    }


clearOrigins : Index -> Index
clearOrigins index =
    index |> setOrigins []


encode : Index -> Value
encode value =
    Encode.notNullObject
        [ ( "name", value.name |> IndexName.encode )
        , ( "columns", value.columns |> Encode.nel ColumnPath.encode )
        , ( "definition", value.definition |> Encode.maybe Encode.string )
        , ( "origins", value.origins |> Origin.encodeList )
        ]


decode : Decode.Decoder Index
decode =
    Decode.map4 Index
        (Decode.field "name" IndexName.decode)
        (Decode.field "columns" (Decode.nel ColumnPath.decode))
        (Decode.maybeField "definition" Decode.string)
        (Decode.defaultField "origins" (Decode.list Origin.decode) [])
