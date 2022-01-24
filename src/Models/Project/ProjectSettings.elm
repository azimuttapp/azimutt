module Models.Project.ProjectSettings exposing (ProjectSettings, decode, encode, init, isColumnHidden, isTableRemoved)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as D
import Libs.Json.Encode as E
import Libs.List as L
import Libs.Regex as R
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
            removedTables |> String.split "," |> List.map String.trim |> L.filterNot String.isEmpty
    in
    \t -> values |> List.any (\n -> t.name == n || R.contains ("^" ++ n ++ "$") t.name)


isColumnHidden : String -> (ColumnName -> Bool)
isColumnHidden hiddenColumnsInput =
    let
        hiddenColumnNames : List String
        hiddenColumnNames =
            hiddenColumnsInput |> String.split "," |> List.map String.trim |> L.filterNot String.isEmpty
    in
    \columnName -> hiddenColumnNames |> List.any (\n -> columnName == n || R.contains ("^" ++ n ++ "$") columnName)


encode : ProjectSettings -> ProjectSettings -> Value
encode default value =
    E.notNullObject
        [ ( "findPath", value.findPath |> E.withDefaultDeep FindPathSettings.encode default.findPath )
        , ( "removedSchemas", value.removedSchemas |> E.withDefault (Encode.list SchemaName.encode) default.removedSchemas )
        , ( "removeViews", value.removeViews |> E.withDefault Encode.bool default.removeViews )
        , ( "removedTables", value.removedTables |> E.withDefault Encode.string default.removedTables )
        , ( "hiddenColumns", value.hiddenColumns |> E.withDefault Encode.string default.hiddenColumns )
        , ( "columnOrder", value.columnOrder |> E.withDefault ColumnOrder.encode default.columnOrder )
        ]


decode : ProjectSettings -> Decode.Decoder ProjectSettings
decode default =
    Decode.map6 ProjectSettings
        (D.defaultFieldDeep "findPath" FindPathSettings.decode default.findPath)
        (D.defaultField "removedSchemas" (Decode.list SchemaName.decode) default.removedSchemas)
        (D.defaultField "removeViews" Decode.bool default.removeViews)
        (D.defaultField "removedTables" Decode.string default.removedTables)
        (D.defaultField "hiddenColumns" Decode.string default.hiddenColumns)
        (D.defaultField "columnOrder" ColumnOrder.decode default.columnOrder)
