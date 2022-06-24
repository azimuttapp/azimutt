module DataSources.AmlParser.AmlAdapter exposing (AmlSchema, AmlSchemaError, adapt, buildAmlSource, evolve)

import Array
import Conf
import DataSources.AmlParser.AmlParser exposing (AmlColumn, AmlColumnName, AmlColumnRef, AmlNotes, AmlStatement(..), AmlTable)
import DataSources.Helpers exposing (defaultCheckName, defaultIndexName, defaultRelName, defaultUniqueName)
import Dict exposing (Dict)
import Libs.Dict as Dict
import Libs.List as List
import Libs.Nel as Nel exposing (Nel)
import Libs.Parser as Parser
import Libs.Result as Result
import Models.Project.Check exposing (Check)
import Models.Project.Column exposing (Column)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.Comment exposing (Comment)
import Models.Project.Index exposing (Index)
import Models.Project.PrimaryKey exposing (PrimaryKey)
import Models.Project.Relation exposing (Relation)
import Models.Project.Source exposing (Source)
import Models.Project.SourceId exposing (SourceId)
import Models.Project.Table exposing (Table)
import Models.Project.TableId as TableId exposing (TableId)
import Models.Project.Unique exposing (Unique)
import Models.SourceInfo exposing (SourceInfo)
import Parser exposing (DeadEnd)


type alias AmlSchema =
    { tables : Dict TableId Table
    , relations : List Relation
    , errors : List AmlSchemaError
    }


type alias AmlSchemaError =
    { row : Int
    , col : Int
    , problem : String
    }


buildAmlSource : SourceInfo -> List AmlStatement -> ( List AmlSchemaError, Source )
buildAmlSource source statements =
    let
        schema : AmlSchema
        schema =
            statements |> List.foldl (evolve source.id) (AmlSchema Dict.empty [] [])
    in
    ( schema.errors |> List.reverse
    , { id = source.id
      , name = source.name
      , kind = source.kind
      , content = Array.empty
      , tables = schema.tables
      , relations = schema.relations |> List.reverse
      , enabled = source.enabled
      , fromSample = source.fromSample
      , createdAt = source.createdAt
      , updatedAt = source.updatedAt
      }
    )


adapt : SourceId -> Result (List DeadEnd) (List AmlStatement) -> AmlSchema
adapt source result =
    result
        |> Result.fold
            (\err -> AmlSchema Dict.empty [] (err |> List.map (\e -> { row = e.row, col = e.col, problem = Parser.problemToString e.problem })))
            (List.foldl (evolve source) (AmlSchema Dict.empty [] []))


evolve : SourceId -> AmlStatement -> AmlSchema -> AmlSchema
evolve source statement schema =
    case statement of
        AmlTableStatement amlTable ->
            let
                ( table, relations ) =
                    createTable source amlTable
            in
            schema.tables
                |> Dict.get table.id
                |> Maybe.map (\_ -> { schema | errors = AmlSchemaError 0 0 ("Table '" ++ TableId.show table.id ++ "' is already defined") :: schema.errors })
                |> Maybe.withDefault { schema | tables = schema.tables |> Dict.insert table.id table, relations = relations ++ schema.relations }

        AmlRelationStatement amlRelation ->
            let
                relation : Relation
                relation =
                    createRelation source amlRelation.from amlRelation.to
            in
            { schema | relations = relation :: schema.relations }

        AmlEmptyStatement _ ->
            schema


createTable : SourceId -> AmlTable -> ( Table, List Relation )
createTable source table =
    ( { id = ( table.schema |> Maybe.withDefault Conf.schema.default, table.table )
      , schema = table.schema |> Maybe.withDefault Conf.schema.default
      , name = table.table
      , view = table.isView
      , columns = table.columns |> List.indexedMap (createColumn source) |> Dict.fromListMap .name
      , primaryKey = table.columns |> createPrimaryKey source
      , uniques = table.columns |> createConstraint .unique (defaultUniqueName table.table) |> List.map (\( name, cols ) -> Unique name cols Nothing [ { id = source, lines = [] } ])
      , indexes = table.columns |> createConstraint .index (defaultIndexName table.table) |> List.map (\( name, cols ) -> Index name cols Nothing [ { id = source, lines = [] } ])
      , checks = table.columns |> createConstraint .check (defaultCheckName table.table) |> List.map (\( name, cols ) -> Check name (Nel.toList cols) Nothing [ { id = source, lines = [] } ])
      , comment = table.notes |> Maybe.map (createComment source)
      , origins = [ { id = source, lines = [] } ]
      }
    , table.columns |> List.filterMap (\c -> c.foreignKey |> Maybe.map (\fk -> createRelation source { schema = table.schema, table = table.table, column = c.name } fk))
    )


createColumn : SourceId -> Int -> AmlColumn -> Column
createColumn source index column =
    { index = index
    , name = column.name
    , kind = column.kind |> Maybe.withDefault Conf.schema.column.unknownType
    , nullable = column.nullable
    , default = column.default
    , comment = column.notes |> Maybe.map (createComment source)
    , origins = [ { id = source, lines = [] } ]
    }


createPrimaryKey : SourceId -> List AmlColumn -> Maybe PrimaryKey
createPrimaryKey source columns =
    columns
        |> List.filter .primaryKey
        |> List.map .name
        |> Nel.fromList
        |> Maybe.map
            (\cols ->
                { name = Nothing
                , columns = cols
                , origins = [ { id = source, lines = [] } ]
                }
            )


createConstraint : (AmlColumn -> Maybe String) -> (AmlColumnName -> String) -> List AmlColumn -> List ( String, Nel ColumnName )
createConstraint get defaultName columns =
    columns
        |> List.filter (\c -> get c /= Nothing)
        |> List.groupBy (\c -> c |> get |> Maybe.withDefault "")
        |> Dict.toList
        |> List.foldl
            (\( name, cols ) acc ->
                if name == "" then
                    (cols |> List.map (\c -> ( defaultName c.name, Nel.from c.name ))) ++ acc

                else
                    ( name, cols |> List.map .name |> Nel.fromList |> Maybe.withDefault (Nel.from name) ) :: acc
            )
            []


createComment : SourceId -> AmlNotes -> Comment
createComment source notes =
    { text = notes
    , origins = [ { id = source, lines = [] } ]
    }


createRelation : SourceId -> AmlColumnRef -> AmlColumnRef -> Relation
createRelation source from to =
    let
        fromId : TableId
        fromId =
            ( from.schema |> Maybe.withDefault Conf.schema.default, from.table )

        toId : TableId
        toId =
            ( to.schema |> Maybe.withDefault Conf.schema.default, to.table )
    in
    { id = ( ( fromId, from.column ), ( toId, to.column ) )
    , name = defaultRelName from.table from.column
    , src = { table = fromId, column = from.column }
    , ref = { table = toId, column = to.column }
    , origins = [ { id = source, lines = [] } ]
    }
