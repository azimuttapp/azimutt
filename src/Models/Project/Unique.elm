module Models.Project.Unique exposing (Unique, decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as D
import Libs.Json.Encode as E
import Libs.Nel exposing (Nel)
import Models.Project.ColumnName as ColumnName exposing (ColumnName)
import Models.Project.Origin as Origin exposing (Origin)
import Models.Project.UniqueName as UniqueName exposing (UniqueName)


type alias Unique =
    { name : UniqueName, columns : Nel ColumnName, definition : String, origins : List Origin }


encode : Unique -> Value
encode value =
    E.object
        [ ( "name", value.name |> UniqueName.encode )
        , ( "columns", value.columns |> E.nel ColumnName.encode )
        , ( "definition", value.definition |> Encode.string )
        , ( "origins", value.origins |> E.withDefault (Encode.list Origin.encode) [] )
        ]


decode : Decode.Decoder Unique
decode =
    Decode.map4 Unique
        (Decode.field "name" UniqueName.decode)
        (Decode.field "columns" (D.nel ColumnName.decode))
        (Decode.field "definition" Decode.string)
        (D.defaultField "origins" (Decode.list Origin.decode) [])
