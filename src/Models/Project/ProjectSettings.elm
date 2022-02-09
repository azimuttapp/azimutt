module Models.Project.ProjectSettings exposing (ProjectSettings, decode, encode, init, isColumnHidden, isTableRemoved)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.List as List
import Libs.Regex as Regex
import Models.ColumnOrder as ColumnOrder exposing (ColumnOrder)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.FindPathSettings as FindPathSettings exposing (FindPathSettings)
import Models.Project.SchemaName as SchemaName exposing (SchemaName)
import Models.Project.Table exposing (TableLike)


type alias ProjectSettings =
    { findPath : FindPathSettings
    , removedSchemas : List SchemaName
    , removeViews : Bool
    , removedTables : String
    , hiddenColumns : String
    , columnOrder : ColumnOrder
    }


init : ProjectSettings
init =
    { findPath = FindPathSettings.init
    , removedSchemas = []
    , removeViews = False
    , removedTables = ""
    , hiddenColumns = ""
    , columnOrder = ColumnOrder.SqlOrder
    }


isTableRemoved : String -> (TableLike x y -> Bool)
isTableRemoved removedTables =
    let
        values : List String
        values =
            removedTables |> String.split "," |> List.map String.trim |> List.filterNot String.isEmpty
    in
    \t -> values |> List.any (\n -> t.name == n || Regex.contains ("^" ++ n ++ "$") t.name)


isColumnHidden : String -> (ColumnName -> Bool)
isColumnHidden hiddenColumnsInput =
    let
        hiddenColumnNames : List String
        hiddenColumnNames =
            hiddenColumnsInput |> String.split "," |> List.map String.trim |> List.filterNot String.isEmpty
    in
    \columnName -> hiddenColumnNames |> List.any (\n -> columnName == n || Regex.contains ("^" ++ n ++ "$") columnName)


encode : ProjectSettings -> ProjectSettings -> Value
encode default value =
    Encode.notNullObject
        [ ( "findPath", value.findPath |> Encode.withDefaultDeep FindPathSettings.encode default.findPath )
        , ( "removedSchemas", value.removedSchemas |> Encode.withDefault (Encode.list SchemaName.encode) default.removedSchemas )
        , ( "removeViews", value.removeViews |> Encode.withDefault Encode.bool default.removeViews )
        , ( "removedTables", value.removedTables |> Encode.withDefault Encode.string default.removedTables )
        , ( "hiddenColumns", value.hiddenColumns |> Encode.withDefault Encode.string default.hiddenColumns )
        , ( "columnOrder", value.columnOrder |> Encode.withDefault ColumnOrder.encode default.columnOrder )
        ]


decode : ProjectSettings -> Decode.Decoder ProjectSettings
decode default =
    Decode.map6 ProjectSettings
        (Decode.defaultFieldDeep "findPath" FindPathSettings.decode default.findPath)
        (Decode.defaultField "removedSchemas" (Decode.list SchemaName.decode) default.removedSchemas)
        (Decode.defaultField "removeViews" Decode.bool default.removeViews)
        (Decode.defaultField "removedTables" Decode.string default.removedTables)
        (Decode.defaultField "hiddenColumns" Decode.string default.hiddenColumns)
        (Decode.defaultField "columnOrder" ColumnOrder.decode default.columnOrder)
