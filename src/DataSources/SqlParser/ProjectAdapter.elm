module DataSources.SqlParser.ProjectAdapter exposing (buildSourceFromSql)

import Array
import DataSources.SqlParser.FileParser exposing (SqlCheck, SqlColumn, SqlComment, SqlIndex, SqlPrimaryKey, SqlSchema, SqlTable, SqlUnique)
import DataSources.SqlParser.Utils.Types exposing (SqlStatement)
import Dict
import Libs.Dict as Dict
import Libs.Models exposing (FileLineContent)
import Libs.Ned as Ned
import Libs.Nel as Nel
import Models.Project.Check exposing (Check)
import Models.Project.Column exposing (Column)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.Comment exposing (Comment)
import Models.Project.Index exposing (Index)
import Models.Project.Origin exposing (Origin)
import Models.Project.PrimaryKey exposing (PrimaryKey)
import Models.Project.Relation as Relation exposing (Relation)
import Models.Project.Source exposing (Source)
import Models.Project.SourceId exposing (SourceId)
import Models.Project.Table exposing (Table)
import Models.Project.Unique exposing (Unique)
import Models.SourceInfo exposing (SourceInfo)


buildSourceFromSql : SourceInfo -> List FileLineContent -> SqlSchema -> Source
buildSourceFromSql sourceInfo lines schema =
    { id = sourceInfo.id
    , name = sourceInfo.name
    , kind = sourceInfo.kind
    , content = Array.fromList lines
    , tables = schema |> Dict.values |> List.map (buildTable sourceInfo.id) |> Dict.fromListMap .id
    , relations = schema |> Dict.values |> List.concatMap (buildRelations sourceInfo.id)
    , enabled = sourceInfo.enabled
    , fromSample = sourceInfo.fromSample
    , createdAt = sourceInfo.createdAt
    , updatedAt = sourceInfo.updatedAt
    }


buildTable : SourceId -> SqlTable -> Table
buildTable source table =
    { id = ( table.schema, table.table )
    , schema = table.schema
    , name = table.table
    , view = table.view
    , columns = table.columns |> Nel.indexedMap (buildColumn source) |> Ned.fromNelMap .name
    , primaryKey = table.primaryKey |> Maybe.map (buildPrimaryKey source)
    , uniques = table.uniques |> List.map (buildUnique source)
    , indexes = table.indexes |> List.map (buildIndex source)
    , checks = table.checks |> List.map (buildCheck source)
    , comment = table.comment |> Maybe.map (buildComment source)
    , origins = [ buildOrigin source table ]
    }


buildColumn : SourceId -> Int -> SqlColumn -> Column
buildColumn source index column =
    { index = index
    , name = column.name
    , kind = column.kind
    , nullable = column.nullable
    , default = column.default
    , comment = column.comment |> Maybe.map (buildComment source)
    , origins = [ { id = source, lines = [] } ]
    }


buildPrimaryKey : SourceId -> SqlPrimaryKey -> PrimaryKey
buildPrimaryKey source pk =
    { name = pk.name
    , columns = pk.columns
    , origins = [ buildOrigin source pk ]
    }


buildUnique : SourceId -> SqlUnique -> Unique
buildUnique source unique =
    { name = unique.name
    , columns = unique.columns
    , definition = unique.definition
    , origins = [ buildOrigin source unique ]
    }


buildIndex : SourceId -> SqlIndex -> Index
buildIndex source index =
    { name = index.name
    , columns = index.columns
    , definition = index.definition
    , origins = [ buildOrigin source index ]
    }


buildCheck : SourceId -> SqlCheck -> Check
buildCheck source check =
    { name = check.name
    , columns = check.columns
    , predicate = check.predicate
    , origins = [ buildOrigin source check ]
    }


buildComment : SourceId -> SqlComment -> Comment
buildComment source comment =
    { text = comment.text
    , origins = [ buildOrigin source comment ]
    }


buildRelations : SourceId -> SqlTable -> List Relation
buildRelations source table =
    table.columns
        |> Nel.filterZip .foreignKey
        |> List.map
            (\( c, fk ) ->
                Relation.new fk.name (ColumnRef ( table.schema, table.table ) c.name) (ColumnRef ( fk.schema, fk.table ) fk.column) [ buildOrigin source fk ]
            )


buildOrigin : SourceId -> { item | source : SqlStatement } -> Origin
buildOrigin source item =
    { id = source, lines = item.source |> Nel.map .line |> Nel.toList }
