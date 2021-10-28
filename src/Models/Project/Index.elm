module Models.Project.Index exposing (Index, decode, encode, merge)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as D
import Libs.Json.Encode as E
import Libs.Nel as Nel exposing (Nel)
import Models.Project.ColumnName as ColumnName exposing (ColumnName)
import Models.Project.IndexName as IndexName exposing (IndexName)
import Models.Project.Origin as Origin exposing (Origin)


type alias Index =
    { name : IndexName, columns : Nel ColumnName, definition : String, origins : List Origin }


merge : Index -> Index -> Index
merge i1 i2 =
    { i1
        | columns = Nel.merge identity ColumnName.merge i1.columns i2.columns
        , origins = i1.origins ++ i2.origins
    }


encode : Index -> Value
encode value =
    E.object
        [ ( "name", value.name |> IndexName.encode )
        , ( "columns", value.columns |> E.nel ColumnName.encode )
        , ( "definition", value.definition |> Encode.string )
        , ( "origins", value.origins |> E.withDefault (Encode.list Origin.encode) [] )
        ]


decode : Decode.Decoder Index
decode =
    Decode.map4 Index
        (Decode.field "name" IndexName.decode)
        (Decode.field "columns" (D.nel ColumnName.decode))
        (Decode.field "definition" Decode.string)
        (D.defaultField "origins" (Decode.list Origin.decode) [])
