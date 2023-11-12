module Models.Project.Unique exposing (Unique, decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.Nel exposing (Nel)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath)
import Models.Project.UniqueName as UniqueName exposing (UniqueName)


type alias Unique =
    { name : UniqueName
    , columns : Nel ColumnPath
    , definition : Maybe String
    }


encode : Unique -> Value
encode value =
    Encode.notNullObject
        [ ( "name", value.name |> UniqueName.encode )
        , ( "columns", value.columns |> Encode.nel ColumnPath.encode )
        , ( "definition", value.definition |> Encode.maybe Encode.string )
        ]


decode : Decode.Decoder Unique
decode =
    Decode.map3 Unique
        (Decode.field "name" UniqueName.decode)
        (Decode.field "columns" (Decode.nel ColumnPath.decode))
        (Decode.maybeField "definition" Decode.string)
