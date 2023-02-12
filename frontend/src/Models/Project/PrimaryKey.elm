module Models.Project.PrimaryKey exposing (PrimaryKey, clearOrigins, decode, encode, merge)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.Nel as Nel exposing (Nel)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath)
import Models.Project.Origin as Origin exposing (Origin)
import Models.Project.PrimaryKeyName as PrimaryKeyName exposing (PrimaryKeyName)
import Services.Lenses exposing (setOrigins)


type alias PrimaryKey =
    { name : Maybe PrimaryKeyName
    , columns : Nel ColumnPath
    , origins : List Origin
    }


merge : PrimaryKey -> PrimaryKey -> PrimaryKey
merge pk1 pk2 =
    { name = pk1.name
    , columns = Nel.merge ColumnPath.toString ColumnPath.merge pk1.columns pk2.columns
    , origins = pk1.origins ++ pk2.origins
    }


clearOrigins : PrimaryKey -> PrimaryKey
clearOrigins pk =
    pk |> setOrigins []


encode : PrimaryKey -> Value
encode value =
    Encode.notNullObject
        [ ( "name", value.name |> Encode.maybe PrimaryKeyName.encode )
        , ( "columns", value.columns |> Encode.nel ColumnPath.encode )
        , ( "origins", value.origins |> Origin.encodeList )
        ]


decode : Decode.Decoder PrimaryKey
decode =
    Decode.map3 PrimaryKey
        (Decode.maybeField "name" PrimaryKeyName.decode)
        (Decode.field "columns" (Decode.nel ColumnPath.decode))
        (Decode.defaultField "origins" (Decode.list Origin.decode) [])
