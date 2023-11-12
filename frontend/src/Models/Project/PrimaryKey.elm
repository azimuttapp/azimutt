module Models.Project.PrimaryKey exposing (PrimaryKey, decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.Nel exposing (Nel)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath)
import Models.Project.PrimaryKeyName as PrimaryKeyName exposing (PrimaryKeyName)


type alias PrimaryKey =
    { name : Maybe PrimaryKeyName
    , columns : Nel ColumnPath
    }


encode : PrimaryKey -> Value
encode value =
    Encode.notNullObject
        [ ( "name", value.name |> Encode.maybe PrimaryKeyName.encode )
        , ( "columns", value.columns |> Encode.nel ColumnPath.encode )
        ]


decode : Decode.Decoder PrimaryKey
decode =
    Decode.map2 PrimaryKey
        (Decode.maybeField "name" PrimaryKeyName.decode)
        (Decode.field "columns" (Decode.nel ColumnPath.decode))
