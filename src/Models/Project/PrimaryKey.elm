module Models.Project.PrimaryKey exposing (PrimaryKey, decode, encode, merge)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as D
import Libs.Json.Encode as E
import Libs.Nel as Nel exposing (Nel)
import Models.Project.ColumnName as ColumnName exposing (ColumnName)
import Models.Project.Origin as Origin exposing (Origin)
import Models.Project.PrimaryKeyName as PrimaryKeyName exposing (PrimaryKeyName)


type alias PrimaryKey =
    { name : PrimaryKeyName, columns : Nel ColumnName, origins : List Origin }


merge : PrimaryKey -> PrimaryKey -> PrimaryKey
merge pk1 pk2 =
    { pk1
        | columns = Nel.merge identity ColumnName.merge pk1.columns pk2.columns
        , origins = pk1.origins ++ pk2.origins
    }


encode : PrimaryKey -> Value
encode value =
    E.object
        [ ( "name", value.name |> PrimaryKeyName.encode )
        , ( "columns", value.columns |> E.nel ColumnName.encode )
        , ( "origins", value.origins |> E.withDefault (Encode.list Origin.encode) [] )
        ]


decode : Decode.Decoder PrimaryKey
decode =
    Decode.map3 PrimaryKey
        (Decode.field "name" PrimaryKeyName.decode)
        (Decode.field "columns" (D.nel ColumnName.decode))
        (D.defaultField "origins" (Decode.list Origin.decode) [])
