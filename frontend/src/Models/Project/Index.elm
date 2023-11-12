module Models.Project.Index exposing (Index, decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.Nel exposing (Nel)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath)
import Models.Project.IndexName as IndexName exposing (IndexName)


type alias Index =
    { name : IndexName
    , columns : Nel ColumnPath
    , definition : Maybe String
    }


encode : Index -> Value
encode value =
    Encode.notNullObject
        [ ( "name", value.name |> IndexName.encode )
        , ( "columns", value.columns |> Encode.nel ColumnPath.encode )
        , ( "definition", value.definition |> Encode.maybe Encode.string )
        ]


decode : Decode.Decoder Index
decode =
    Decode.map3 Index
        (Decode.field "name" IndexName.decode)
        (Decode.field "columns" (Decode.nel ColumnPath.decode))
        (Decode.maybeField "definition" Decode.string)
