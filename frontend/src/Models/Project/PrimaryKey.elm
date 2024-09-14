module Models.Project.PrimaryKey exposing (PrimaryKey, decode, doc, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.Nel as Nel exposing (Nel)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath, ColumnPathStr)
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


doc : List ColumnPathStr -> Maybe PrimaryKey
doc columns =
    columns |> Nel.fromList |> Maybe.map (Nel.map ColumnPath.fromString) |> Maybe.map (\cols -> { name = Nothing, columns = cols })
