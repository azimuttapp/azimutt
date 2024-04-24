module DataSources.AmlMiner.AmlAdapter exposing (AmlSchema, AmlSchemaError, buildSource, evolve, initSchema)

import Array exposing (Array)
import Conf
import DataSources.AmlMiner.AmlParser exposing (AmlColumn, AmlColumnName, AmlColumnRef, AmlNotes, AmlStatement(..), AmlTable)
import DataSources.Helpers exposing (defaultCheckName, defaultIndexName, defaultRelName, defaultUniqueName)
import Dict exposing (Dict)
import Libs.Dict as Dict
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Nel as Nel exposing (Nel)
import Libs.Parser as Parser
import Libs.Result as Result
import Libs.String as String
import Models.Project.Check exposing (Check)
import Models.Project.Column exposing (Column)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath)
import Models.Project.Comment exposing (Comment)
import Models.Project.CustomType exposing (CustomType)
import Models.Project.CustomTypeId exposing (CustomTypeId)
import Models.Project.CustomTypeValue as CustomTypeValue
import Models.Project.Index exposing (Index)
import Models.Project.PrimaryKey exposing (PrimaryKey)
import Models.Project.Relation exposing (Relation)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source exposing (Source)
import Models.Project.Table exposing (Table)
import Models.Project.TableId as TableId exposing (TableId)
import Models.Project.Unique exposing (Unique)
import Models.SourceInfo exposing (SourceInfo)
import Parser exposing (DeadEnd)


type alias AmlSchema =
    { tables : Dict TableId Table
    , relations : List Relation
    , types : Dict CustomTypeId CustomType
    , errors : List AmlSchemaError
    }


type alias AmlSchemaError =
    { row : Int
    , col : Int
    , problem : String
    }


initSchema : AmlSchema
initSchema =
    AmlSchema Dict.empty [] Dict.empty []


buildSource : SourceInfo -> Array String -> Result (List DeadEnd) (List AmlStatement) -> ( List AmlSchemaError, Source, Dict TableId (List ColumnPath) )
buildSource source content result =
    let
        schema : AmlSchema
        schema =
            result
                |> Result.fold
                    (\err -> { initSchema | errors = err |> List.map (\e -> { row = e.row, col = e.col, problem = Parser.problemToString e.problem }) })
                    (List.foldl evolve initSchema)

        orderedColumns : Dict TableId (List ColumnPath)
        orderedColumns =
            result |> Result.fold (\_ -> Dict.empty) (List.foldl tablesColumnsOrdered Dict.empty)
    in
    ( schema.errors |> List.reverse
    , { id = source.id
      , name = source.name
      , kind = source.kind
      , content = content
      , tables = schema.tables
      , relations = schema.relations |> List.reverse
      , types = schema.types
      , enabled = source.enabled
      , fromSample = source.fromSample
      , createdAt = source.createdAt
      , updatedAt = source.updatedAt
      }
    , orderedColumns
    )


tablesColumnsOrdered : AmlStatement -> Dict TableId (List ColumnPath) -> Dict TableId (List ColumnPath)
tablesColumnsOrdered statement tables =
    case statement of
        AmlTableStatement table ->
            tables |> Dict.insert (createTableId table) (table.columns |> List.map (.name >> ColumnPath.fromString))

        AmlRelationStatement _ ->
            tables

        AmlEmptyStatement _ ->
            tables


evolve : AmlStatement -> AmlSchema -> AmlSchema
evolve statement schema =
    case statement of
        AmlTableStatement amlTable ->
            let
                ( table, relations, types ) =
                    createTable amlTable
            in
            schema.tables
                |> Dict.get table.id
                |> Maybe.map (\_ -> { schema | errors = AmlSchemaError 0 0 ("Table '" ++ TableId.show Conf.schema.empty table.id ++ "' is already defined") :: schema.errors })
                |> Maybe.withDefault { schema | tables = schema.tables |> Dict.insert table.id table, relations = relations ++ schema.relations, types = Dict.union types schema.types }

        AmlRelationStatement amlRelation ->
            let
                relation : Relation
                relation =
                    createRelation amlRelation.from amlRelation.to
            in
            { schema | relations = relation :: schema.relations }

        AmlEmptyStatement _ ->
            schema


createTableId : AmlTable -> TableId
createTableId table =
    ( table.schema |> Maybe.withDefault Conf.schema.empty, table.table )


createTable : AmlTable -> ( Table, List Relation, Dict CustomTypeId CustomType )
createTable table =
    let
        id : TableId
        id =
            createTableId table
    in
    ( { id = id
      , schema = id |> TableId.schema
      , name = id |> TableId.name
      , view = table.isView
      , definition = Nothing
      , columns = table.columns |> List.indexedMap createColumn |> Dict.fromListMap .name
      , primaryKey = table.columns |> createPrimaryKey
      , uniques = table.columns |> createConstraint .unique (defaultUniqueName table.table) |> List.map (\( name, cols ) -> Unique name cols Nothing)
      , indexes = table.columns |> createConstraint .index (defaultIndexName table.table) |> List.map (\( name, cols ) -> Index name cols Nothing)
      , checks = table.columns |> List.filterMap (\c -> c.check |> Maybe.map (\check -> Check (defaultCheckName table.table c.name) [ Nel.from c.name ] (String.nonEmptyMaybe check)))
      , comment = table.notes |> Maybe.map createComment
      , stats = Nothing
      }
    , table.columns |> List.filterMap (\c -> Maybe.map (createRelation { schema = table.schema, table = table.table, column = c.name }) c.foreignKey)
    , table.columns |> List.filterMap (\c -> Maybe.map2 (createType (c.kindSchema |> Maybe.orElse table.schema)) c.kind c.values) |> Dict.fromListMap .id
    )


createColumn : Int -> AmlColumn -> Column
createColumn index column =
    { index = index
    , name = column.name
    , kind = column.kind |> Maybe.withDefault Conf.schema.column.unknownType
    , nullable = column.nullable
    , default = column.default
    , comment = column.notes |> Maybe.map createComment
    , values = Nothing
    , columns = Nothing -- nested columns not supported in AML
    , stats = Nothing
    }


createPrimaryKey : List AmlColumn -> Maybe PrimaryKey
createPrimaryKey columns =
    columns
        |> List.filter .primaryKey
        |> List.map .name
        |> Nel.fromList
        |> Maybe.map
            (\cols ->
                { name = Nothing
                , columns = cols |> Nel.map ColumnPath.fromString
                }
            )


createConstraint : (AmlColumn -> Maybe String) -> (AmlColumnName -> String) -> List AmlColumn -> List ( String, Nel ColumnPath )
createConstraint get defaultName columns =
    columns
        |> List.filter (\c -> get c /= Nothing)
        |> List.groupBy (\c -> c |> get |> Maybe.withDefault "")
        |> Dict.toList
        |> List.foldl
            (\( name, cols ) acc ->
                if name == "" then
                    (cols |> List.map (\c -> ( defaultName c.name, c.name |> ColumnPath.fromString |> Nel.from ))) ++ acc

                else
                    ( name, cols |> List.map (.name >> ColumnPath.fromString) |> Nel.fromList |> Maybe.withDefault (name |> ColumnPath.fromString |> Nel.from) ) :: acc
            )
            []


createComment : AmlNotes -> Comment
createComment notes =
    { text = notes
    }


createRelation : AmlColumnRef -> AmlColumnRef -> Relation
createRelation from to =
    let
        fromId : TableId
        fromId =
            ( from.schema |> Maybe.withDefault Conf.schema.empty, from.table )

        toId : TableId
        toId =
            ( to.schema |> Maybe.withDefault Conf.schema.empty, to.table )
    in
    { id = ( ( fromId, from.column ), ( toId, to.column ) )
    , name = defaultRelName from.table (ColumnPath.fromString from.column)
    , src = { table = fromId, column = ColumnPath.fromString from.column }
    , ref = { table = toId, column = ColumnPath.fromString to.column }
    }


createType : Maybe SchemaName -> String -> Nel String -> CustomType
createType schema name values =
    { id = ( schema |> Maybe.withDefault Conf.schema.empty, name )
    , name = name
    , value = CustomTypeValue.Enum (values |> Nel.toList)
    }
