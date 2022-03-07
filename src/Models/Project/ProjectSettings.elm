module Models.Project.ProjectSettings exposing (HiddenColumns, ProjectSettings, RemovedTables, decode, encode, fillFindPath, hideColumn, init, removeColumn, removeTable)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.List as List
import Libs.Regex as Regex
import Libs.String as String
import Models.ColumnOrder as ColumnOrder exposing (ColumnOrder(..))
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.FindPathSettings as FindPathSettings exposing (FindPathSettings)
import Models.Project.SchemaName as SchemaName exposing (SchemaName)
import Models.Project.TableId exposing (TableId)
import PagesComponents.Projects.Id_.Models.ErdColumn exposing (ErdColumn)
import Services.Lenses exposing (mapFindPath, setIgnoredColumns, setIgnoredTables)


type alias ProjectSettings =
    { findPath : FindPathSettings
    , removedSchemas : List SchemaName
    , removeViews : Bool
    , removedTables : RemovedTables
    , hiddenColumns : HiddenColumns
    , columnOrder : ColumnOrder
    , columnBasicTypes : Bool
    }


type alias RemovedTables =
    String


type alias HiddenColumns =
    { list : String, props : Bool, relations : Bool }


init : ProjectSettings
init =
    { findPath = FindPathSettings.init
    , removedSchemas = []
    , removeViews = False
    , removedTables = ""
    , hiddenColumns = { list = "created_.+, updated_.+", props = False, relations = False }
    , columnOrder = OrderByProperty
    , columnBasicTypes = True
    }


fillFindPath : ProjectSettings -> ProjectSettings
fillFindPath settings =
    settings
        |> mapFindPath
            (\fp ->
                fp
                    |> setIgnoredTables (fp.ignoredTables |> String.orElse settings.removedTables)
                    |> setIgnoredColumns (fp.ignoredColumns |> String.orElse settings.hiddenColumns.list)
            )


removeTable : RemovedTables -> TableId -> Bool
removeTable removedTables =
    let
        names : List String
        names =
            removedTables |> String.split "," |> List.map String.trim |> List.filterNot String.isEmpty
    in
    \( _, tableName ) -> names |> List.any (\name -> tableName == name || Regex.match ("^" ++ name ++ "$") tableName)


removeColumn : String -> ColumnName -> Bool
removeColumn hiddenColumns =
    let
        names : List String
        names =
            hiddenColumns |> String.split "," |> List.map String.trim |> List.filterNot String.isEmpty
    in
    \column -> names |> List.any (\name -> column == name || Regex.match ("^" ++ name ++ "$") column)


hideColumn : HiddenColumns -> ErdColumn -> Bool
hideColumn hiddenColumns column =
    removeColumn hiddenColumns.list column.name
        || (hiddenColumns.relations && (column |> hasRelation |> not))
        || (hiddenColumns.props && (column |> hasProperty |> not))


hasRelation : ErdColumn -> Bool
hasRelation column =
    List.nonEmpty column.inRelations || List.nonEmpty column.outRelations


hasProperty : ErdColumn -> Bool
hasProperty c =
    c.isPrimaryKey || List.nonEmpty c.inRelations || List.nonEmpty c.outRelations || List.nonEmpty c.uniques || List.nonEmpty c.indexes || List.nonEmpty c.checks


encode : ProjectSettings -> ProjectSettings -> Value
encode default value =
    Encode.notNullObject
        [ ( "findPath", value.findPath |> Encode.withDefaultDeep FindPathSettings.encode default.findPath )
        , ( "removedSchemas", value.removedSchemas |> Encode.withDefault (Encode.list SchemaName.encode) default.removedSchemas )
        , ( "removeViews", value.removeViews |> Encode.withDefault Encode.bool default.removeViews )
        , ( "removedTables", value.removedTables |> Encode.withDefault Encode.string default.removedTables )
        , ( "hiddenColumns", value.hiddenColumns |> Encode.withDefaultDeep encodeHiddenColumns default.hiddenColumns )
        , ( "columnOrder", value.columnOrder |> Encode.withDefault ColumnOrder.encode default.columnOrder )
        , ( "columnBasicTypes", value.columnBasicTypes |> Encode.withDefault Encode.bool default.columnBasicTypes )
        ]


decode : ProjectSettings -> Decode.Decoder ProjectSettings
decode default =
    Decode.map7 ProjectSettings
        (Decode.defaultFieldDeep "findPath" FindPathSettings.decode default.findPath)
        (Decode.defaultField "removedSchemas" (Decode.list SchemaName.decode) default.removedSchemas)
        (Decode.defaultField "removeViews" Decode.bool default.removeViews)
        (Decode.defaultField "removedTables" Decode.string default.removedTables)
        (Decode.defaultFieldDeep "hiddenColumns" decodeHiddenColumns default.hiddenColumns)
        (Decode.defaultField "columnOrder" ColumnOrder.decode default.columnOrder)
        (Decode.defaultField "columnBasicTypes" Decode.bool default.columnBasicTypes)


encodeHiddenColumns : HiddenColumns -> HiddenColumns -> Value
encodeHiddenColumns default value =
    Encode.notNullObject
        [ ( "list", value.list |> Encode.withDefault Encode.string default.list )
        , ( "props", value.props |> Encode.withDefault Encode.bool default.props )
        , ( "relations", value.relations |> Encode.withDefault Encode.bool default.relations )
        ]


decodeHiddenColumns : HiddenColumns -> Decode.Decoder HiddenColumns
decodeHiddenColumns default =
    Decode.oneOf
        [ Decode.map3 HiddenColumns
            (Decode.defaultField "list" Decode.string default.list)
            (Decode.defaultField "props" Decode.bool default.props)
            (Decode.defaultField "relations" Decode.bool default.relations)
        , Decode.map (\list -> { list = list, props = default.props, relations = default.relations })
            Decode.string
        ]
