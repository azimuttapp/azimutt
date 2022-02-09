module Models.Project.FindPathSettings exposing (FindPathSettings, decode, encode, init)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Models.Project.ColumnName as ColumnName exposing (ColumnName)
import Models.Project.TableId as TableId exposing (TableId)


type alias FindPathSettings =
    { maxPathLength : Int, ignoredTables : List TableId, ignoredColumns : List ColumnName }


init : FindPathSettings
init =
    FindPathSettings 3 [] []


encode : FindPathSettings -> FindPathSettings -> Value
encode default value =
    Encode.notNullObject
        [ ( "maxPathLength", value.maxPathLength |> Encode.withDefault Encode.int default.maxPathLength )
        , ( "ignoredTables", value.ignoredTables |> Encode.withDefault (Encode.list TableId.encode) default.ignoredTables )
        , ( "ignoredColumns", value.ignoredColumns |> Encode.withDefault (Encode.list ColumnName.encode) default.ignoredColumns )
        ]


decode : FindPathSettings -> Decode.Decoder FindPathSettings
decode default =
    Decode.map3 FindPathSettings
        (Decode.defaultField "maxPathLength" Decode.int default.maxPathLength)
        (Decode.defaultField "ignoredTables" (Decode.list TableId.decode) default.ignoredTables)
        (Decode.defaultField "ignoredColumns" (Decode.list ColumnName.decode) default.ignoredColumns)
