module Models.Project.FindPathSettings exposing (FindPathSettings, decode, encode, init)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as D
import Libs.Json.Encode as E
import Models.Project.ColumnName as ColumnName exposing (ColumnName)
import Models.Project.TableId as TableId exposing (TableId)


type alias FindPathSettings =
    { maxPathLength : Int, ignoredTables : List TableId, ignoredColumns : List ColumnName }


init : FindPathSettings
init =
    FindPathSettings 3 [] []


encode : FindPathSettings -> FindPathSettings -> Value
encode default value =
    E.notNullObject
        [ ( "maxPathLength", value.maxPathLength |> E.withDefault Encode.int default.maxPathLength )
        , ( "ignoredTables", value.ignoredTables |> E.withDefault (Encode.list TableId.encode) default.ignoredTables )
        , ( "ignoredColumns", value.ignoredColumns |> E.withDefault (Encode.list ColumnName.encode) default.ignoredColumns )
        ]


decode : FindPathSettings -> Decode.Decoder FindPathSettings
decode default =
    Decode.map3 FindPathSettings
        (D.defaultField "maxPathLength" Decode.int default.maxPathLength)
        (D.defaultField "ignoredTables" (Decode.list TableId.decode) default.ignoredTables)
        (D.defaultField "ignoredColumns" (Decode.list ColumnName.decode) default.ignoredColumns)
