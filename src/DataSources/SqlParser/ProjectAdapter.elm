module DataSources.SqlParser.ProjectAdapter exposing (buildSourceFromSql)

import Array
import DataSources.SqlParser.FileParser exposing (SqlCheck, SqlColumn, SqlIndex, SqlPrimaryKey, SqlSchema, SqlTable, SqlUnique)
import Dict
import Libs.Dict as D
import Libs.Models exposing (FileLineContent)
import Libs.Ned as Ned
import Libs.Nel as Nel
import Models.Project exposing (Check, Column, Comment, Index, PrimaryKey, Relation, Source, SourceId, SourceInfo, Table, Unique)
import Models.Project.ColumnRef exposing (ColumnRef)


buildSourceFromSql : SourceInfo -> List FileLineContent -> SqlSchema -> Source
buildSourceFromSql sourceInfo lines schema =
    { id = sourceInfo.id
    , name = sourceInfo.name
    , kind = sourceInfo.kind
    , content = Array.fromList lines
    , tables = schema |> Dict.values |> List.map (buildTable sourceInfo.id) |> D.fromListMap .id
    , relations = schema |> Dict.values |> List.concatMap (buildRelations sourceInfo.id)
    , enabled = sourceInfo.enabled
    , fromSample = sourceInfo.fromSample
    , createdAt = sourceInfo.createdAt
    , updatedAt = sourceInfo.updatedAt
    }


buildTable : SourceId -> SqlTable -> Table
buildTable sourceId table =
    { id = ( table.schema, table.table )
    , schema = table.schema
    , name = table.table
    , columns = table.columns |> Nel.indexedMap buildColumn |> Ned.fromNelMap .name
    , primaryKey = table.primaryKey |> Maybe.map buildPrimaryKey
    , uniques = table.uniques |> List.map buildUnique
    , indexes = table.indexes |> List.map buildIndex
    , checks = table.checks |> List.map buildCheck
    , comment = table.comment |> Maybe.map buildComment
    , origins = [ { id = sourceId, lines = table.source |> Nel.map .line |> Nel.toList } ]
    }


buildColumn : Int -> SqlColumn -> Column
buildColumn index column =
    { index = index
    , name = column.name
    , kind = column.kind
    , nullable = column.nullable
    , default = column.default
    , comment = column.comment |> Maybe.map buildComment
    , origins = [] -- FIXME
    }


buildPrimaryKey : SqlPrimaryKey -> PrimaryKey
buildPrimaryKey pk =
    { name = pk.name
    , columns = pk.columns
    , origins = [] -- FIXME
    }


buildUnique : SqlUnique -> Unique
buildUnique unique =
    { name = unique.name
    , columns = unique.columns
    , definition = unique.definition
    , origins = [] -- FIXME
    }


buildIndex : SqlIndex -> Index
buildIndex index =
    { name = index.name
    , columns = index.columns
    , definition = index.definition
    , origins = [] -- FIXME
    }


buildCheck : SqlCheck -> Check
buildCheck check =
    { name = check.name
    , columns = check.columns
    , predicate = check.predicate
    , origins = [] -- FIXME
    }


buildComment : String -> Comment
buildComment comment =
    { text = comment
    , origins = [] -- FIXME
    }


buildRelations : SourceId -> SqlTable -> List Relation
buildRelations sourceId table =
    table.columns
        |> Nel.filterZip .foreignKey
        |> List.map
            (\( c, fk ) ->
                { name = fk.name
                , src = ColumnRef ( table.schema, table.table ) c.name
                , ref = ColumnRef ( fk.schema, fk.table ) fk.column
                , origins = [ { id = sourceId, lines = [] } ]
                }
            )
