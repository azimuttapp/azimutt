module DataSources.DatabaseSourceParser.DatabaseAdapter exposing (buildSource)

import Array
import DataSources.DatabaseSourceParser.DatabaseSchema exposing (DatabaseSchema)
import DataSources.DatabaseSourceParser.Models.DatabaseRelation exposing (DatabaseRelation)
import DataSources.DatabaseSourceParser.Models.DatabaseTable exposing (DatabaseCheck, DatabaseColumn, DatabaseIndex, DatabasePrimaryKey, DatabaseTable, DatabaseUnique)
import DataSources.Helpers exposing (defaultCheckName, defaultIndexName, defaultUniqueName)
import Dict exposing (Dict)
import Libs.Dict as Dict
import Libs.Models.DatabaseUrl as DatabaseUrl exposing (DatabaseUrl)
import Libs.Nel as Nel
import Models.Project.Check exposing (Check)
import Models.Project.Column exposing (Column)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.Comment exposing (Comment)
import Models.Project.Index exposing (Index)
import Models.Project.Origin exposing (Origin)
import Models.Project.PrimaryKey exposing (PrimaryKey)
import Models.Project.Relation as Relation exposing (Relation)
import Models.Project.Source exposing (Source)
import Models.Project.SourceId exposing (SourceId)
import Models.Project.SourceKind as SourceKind
import Models.Project.Table exposing (Table)
import Models.Project.TableId exposing (TableId)
import Models.Project.Unique exposing (Unique)
import Time


buildSource : Time.Posix -> SourceId -> DatabaseUrl -> DatabaseSchema -> Source
buildSource now sourceId url schema =
    let
        origins : List Origin
        origins =
            [ { id = sourceId, lines = [] } ]
    in
    { id = sourceId
    , name = DatabaseUrl.databaseName url
    , kind = SourceKind.DatabaseConnection url
    , content = Array.empty
    , tables = schema.tables |> List.map (buildTable origins) |> Dict.fromList
    , relations = schema.relations |> List.filterMap (buildRelation origins)
    , enabled = True
    , fromSample = Nothing
    , createdAt = now
    , updatedAt = now
    }


buildTable : List Origin -> DatabaseTable -> ( TableId, Table )
buildTable origins table =
    let
        id : TableId
        id =
            ( table.schema, table.table )
    in
    ( id
    , { id = id
      , schema = table.schema
      , name = table.table
      , view = table.view
      , columns = table.columns |> buildColumns origins
      , primaryKey = table.primaryKey |> Maybe.andThen (buildPrimaryKey origins)
      , uniques = table.uniques |> List.filterMap (buildUnique origins table.table)
      , indexes = table.indexes |> List.filterMap (buildIndex origins table.table)
      , checks = table.checks |> List.map (buildCheck origins table.table)
      , comment = table.comment |> Maybe.map (buildComment origins)
      , origins = origins
      }
    )


buildColumns : List Origin -> List DatabaseColumn -> Dict ColumnName Column
buildColumns origins columns =
    columns |> List.indexedMap (buildColumn origins) |> Dict.fromListMap .name


buildColumn : List Origin -> Int -> DatabaseColumn -> Column
buildColumn origins index column =
    { index = index
    , name = column.name
    , kind = column.kind
    , nullable = column.nullable
    , default = column.default
    , comment = column.comment |> Maybe.map (buildComment origins)
    , origins = origins
    }


buildPrimaryKey : List Origin -> DatabasePrimaryKey -> Maybe PrimaryKey
buildPrimaryKey origins pk =
    pk.columns
        |> Nel.fromList
        |> Maybe.map
            (\columns ->
                { name = pk.name
                , columns = columns
                , origins = origins
                }
            )


buildUnique : List Origin -> String -> DatabaseUnique -> Maybe Unique
buildUnique origins table unique =
    unique.columns
        |> Nel.fromList
        |> Maybe.map
            (\columns ->
                { name = unique.name |> Maybe.withDefault (defaultUniqueName table columns.head)
                , columns = columns
                , definition = unique.definition
                , origins = origins
                }
            )


buildIndex : List Origin -> String -> DatabaseIndex -> Maybe Index
buildIndex origins table index =
    index.columns
        |> Nel.fromList
        |> Maybe.map
            (\columns ->
                { name = index.name |> Maybe.withDefault (defaultIndexName table columns.head)
                , columns = columns
                , definition = index.definition
                , origins = origins
                }
            )


buildCheck : List Origin -> String -> DatabaseCheck -> Check
buildCheck origins table check =
    { name = check.name |> Maybe.withDefault (defaultCheckName table (check.columns |> List.head |> Maybe.withDefault ""))
    , columns = check.columns
    , predicate = check.predicate
    , origins = origins
    }


buildComment : List Origin -> String -> Comment
buildComment origins comment =
    { text = comment
    , origins = origins
    }


buildRelation : List Origin -> DatabaseRelation -> Maybe Relation
buildRelation origins relation =
    relation.columns
        |> List.head
        |> Maybe.map
            (\col ->
                Relation.new relation.name
                    { table = ( relation.src.schema, relation.src.table ), column = col.src }
                    { table = ( relation.ref.schema, relation.ref.table ), column = col.ref }
                    origins
            )
