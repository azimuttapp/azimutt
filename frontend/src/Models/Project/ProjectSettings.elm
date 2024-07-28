module Models.Project.ProjectSettings exposing (HiddenColumns, LlmSettings, ProjectSettings, RemovedTables, decode, encode, fillFindPath, hideColumn, init, removeColumn, removeTable)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.List as List
import Libs.Regex as Regex
import Libs.String as String
import Models.ColumnOrder as ColumnOrder exposing (ColumnOrder)
import Models.OpenAIKey as OpenAIKey exposing (OpenAIKey)
import Models.OpenAIModel as OpenAIModel exposing (OpenAIModel)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath, ColumnPathStr)
import Models.Project.FindPathSettings as FindPathSettings exposing (FindPathSettings)
import Models.Project.SchemaName as SchemaName exposing (SchemaName)
import Models.Project.TableId exposing (TableId)
import Models.RelationStyle as RelationStyle exposing (RelationStyle)
import PagesComponents.Organization_.Project_.Models.ErdColumn exposing (ErdColumn)
import Services.Lenses exposing (mapFindPath, setIgnoredColumns, setIgnoredTables)


type alias ProjectSettings =
    { findPath : FindPathSettings
    , defaultSchema : SchemaName
    , removedSchemas : List SchemaName
    , removeViews : Bool
    , removedTables : RemovedTables
    , hiddenColumns : HiddenColumns
    , columnOrder : ColumnOrder
    , relationStyle : RelationStyle
    , columnBasicTypes : Bool
    , collapseTableColumns : Bool
    , llm : Maybe LlmSettings
    }


type alias RemovedTables =
    String


type alias HiddenColumns =
    { list : String, max : Int, props : Bool, relations : Bool }


type alias LlmSettings =
    { key : OpenAIKey, model : OpenAIModel }


init : SchemaName -> ProjectSettings
init defaultSchema =
    { findPath = FindPathSettings.init
    , defaultSchema = defaultSchema
    , removedSchemas = []
    , removeViews = False
    , removedTables = ""
    , hiddenColumns = { list = "created_.+, updated_.+, deleted_.+", max = 15, props = False, relations = False }
    , columnOrder = ColumnOrder.OrderByProperty
    , relationStyle = RelationStyle.Bezier
    , columnBasicTypes = True
    , collapseTableColumns = False
    , llm = Nothing
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
            removedTables |> String.toLower |> String.split "," |> List.map String.trim |> List.filterNot String.isEmpty
    in
    Tuple.mapSecond String.toLower >> (\( _, tableName ) -> names |> List.any (\name -> tableName == name || Regex.match ("^" ++ name ++ "$") tableName))


removeColumn : String -> ColumnPath -> Bool
removeColumn hiddenColumns =
    let
        ( regexHide, stringHide ) =
            hiddenColumns |> String.toLower |> String.split "," |> List.map String.trim |> List.filterNot String.isEmpty |> List.partition (Regex.match "[+*?^$()[\\]{}|\\\\]")
    in
    ColumnPath.show >> String.toLower >> (\path -> (stringHide |> List.any (\h -> path |> String.startsWith h)) || (regexHide |> List.any (\h -> path |> Regex.match h)))


hideColumn : HiddenColumns -> ErdColumn -> Bool
hideColumn hiddenColumns column =
    removeColumn hiddenColumns.list column.path
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
        , ( "defaultSchema", value.defaultSchema |> Encode.withDefault SchemaName.encode default.defaultSchema )
        , ( "removedSchemas", value.removedSchemas |> Encode.withDefault (Encode.list SchemaName.encode) default.removedSchemas )
        , ( "removeViews", value.removeViews |> Encode.withDefault Encode.bool default.removeViews )
        , ( "removedTables", value.removedTables |> Encode.withDefault Encode.string default.removedTables )
        , ( "hiddenColumns", value.hiddenColumns |> Encode.withDefaultDeep encodeHiddenColumns default.hiddenColumns )
        , ( "columnOrder", value.columnOrder |> Encode.withDefault ColumnOrder.encode default.columnOrder )
        , ( "relationStyle", value.relationStyle |> Encode.withDefault RelationStyle.encode default.relationStyle )
        , ( "columnBasicTypes", value.columnBasicTypes |> Encode.withDefault Encode.bool default.columnBasicTypes )
        , ( "collapseTableColumns", value.collapseTableColumns |> Encode.withDefault Encode.bool default.collapseTableColumns )
        , ( "llm", value.llm |> Encode.maybe encodeLlmSettings )
        ]


decode : ProjectSettings -> Decode.Decoder ProjectSettings
decode default =
    Decode.map11 ProjectSettings
        (Decode.defaultFieldDeep "findPath" FindPathSettings.decode default.findPath)
        (Decode.defaultField "defaultSchema" SchemaName.decode default.defaultSchema)
        (Decode.defaultField "removedSchemas" (Decode.list SchemaName.decode) default.removedSchemas)
        (Decode.defaultField "removeViews" Decode.bool default.removeViews)
        (Decode.defaultField "removedTables" Decode.string default.removedTables)
        (Decode.defaultFieldDeep "hiddenColumns" decodeHiddenColumns default.hiddenColumns)
        (Decode.defaultField "columnOrder" ColumnOrder.decode default.columnOrder)
        (Decode.defaultField "relationStyle" RelationStyle.decode default.relationStyle)
        (Decode.defaultField "columnBasicTypes" Decode.bool default.columnBasicTypes)
        (Decode.defaultField "collapseTableColumns" Decode.bool default.collapseTableColumns)
        (Decode.maybeField "llm" decodeLlmSettings)


encodeHiddenColumns : HiddenColumns -> HiddenColumns -> Value
encodeHiddenColumns default value =
    Encode.notNullObject
        [ ( "list", value.list |> Encode.withDefault Encode.string default.list )
        , ( "max", value.max |> Encode.withDefault Encode.int default.max )
        , ( "props", value.props |> Encode.withDefault Encode.bool default.props )
        , ( "relations", value.relations |> Encode.withDefault Encode.bool default.relations )
        ]


decodeHiddenColumns : HiddenColumns -> Decode.Decoder HiddenColumns
decodeHiddenColumns default =
    Decode.oneOf
        [ Decode.map4 HiddenColumns
            (Decode.defaultField "list" Decode.string default.list)
            (Decode.defaultField "max" Decode.int default.max)
            (Decode.defaultField "props" Decode.bool default.props)
            (Decode.defaultField "relations" Decode.bool default.relations)
        , Decode.map (\list -> { list = list, max = default.max, props = default.props, relations = default.relations })
            Decode.string
        ]


encodeLlmSettings : LlmSettings -> Value
encodeLlmSettings value =
    Encode.notNullObject
        [ ( "key", value.key |> OpenAIKey.encode )
        , ( "model", value.model |> OpenAIModel.encode )
        ]


decodeLlmSettings : Decode.Decoder LlmSettings
decodeLlmSettings =
    Decode.map2 LlmSettings
        (Decode.field "key" OpenAIKey.decode)
        (Decode.field "model" OpenAIModel.decode)
