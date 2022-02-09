module Models.Project.PrimaryKey exposing (PrimaryKey, decode, encode, merge)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.Nel as Nel exposing (Nel)
import Models.Project.ColumnName as ColumnName exposing (ColumnName)
import Models.Project.Origin as Origin exposing (Origin)
import Models.Project.PrimaryKeyName as PrimaryKeyName exposing (PrimaryKeyName)


type alias PrimaryKey =
    { name : PrimaryKeyName
    , columns : Nel ColumnName
    , origins : List Origin
    }


merge : PrimaryKey -> PrimaryKey -> PrimaryKey
merge pk1 pk2 =
    { name = pk1.name
    , columns = Nel.merge identity ColumnName.merge pk1.columns pk2.columns
    , origins = pk1.origins ++ pk2.origins
    }


encode : PrimaryKey -> Value
encode value =
    Encode.notNullObject
        [ ( "name", value.name |> PrimaryKeyName.encode )
        , ( "columns", value.columns |> Encode.nel ColumnName.encode )
        , ( "origins", value.origins |> Encode.withDefault (Encode.list Origin.encode) [] )
        ]


decode : Decode.Decoder PrimaryKey
decode =
    Decode.map3 PrimaryKey
        (Decode.field "name" PrimaryKeyName.decode)
        (Decode.field "columns" (Decode.nel ColumnName.decode))
        (Decode.defaultField "origins" (Decode.list Origin.decode) [])
