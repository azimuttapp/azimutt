module DataSources.SqlParser.ProjectAdapter exposing (buildProjectFromSql, buildSchema)

import DataSources.SqlParser.FileParser exposing (SqlCheck, SqlColumn, SqlIndex, SqlPrimaryKey, SqlSchema, SqlTable, SqlUnique)
import Dict
import Libs.Dict as D
import Libs.Ned as Ned
import Libs.Nel as Nel exposing (Nel)
import Libs.Position exposing (Position)
import Libs.String as S
import Models.Project exposing (CanvasProps, Check, Column, ColumnRef, Comment, Index, Layout, PrimaryKey, Project, ProjectId, ProjectSource, ProjectSourceContent(..), Relation, SampleName, Schema, Table, Unique, buildProject)
import Time


buildProjectFromSql : List String -> Time.Posix -> ProjectId -> ProjectSource -> SqlSchema -> Maybe SampleName -> Project
buildProjectFromSql takenNames now id source schema sample =
    buildProject id (S.unique takenNames source.name) (Nel source []) (buildSchema now source schema) sample now


buildSchema : Time.Posix -> ProjectSource -> SqlSchema -> Schema
buildSchema now source schema =
    { tables = schema |> Dict.values |> List.map (buildTable source) |> D.fromListMap .id
    , relations = schema |> Dict.values |> List.concatMap (buildRelations source)
    , layout = Layout (CanvasProps (Position 0 0) 1) [] [] now now
    }


buildTable : ProjectSource -> SqlTable -> Table
buildTable source table =
    { id = ( table.schema, table.table )
    , schema = table.schema
    , name = table.table
    , columns = table.columns |> Nel.indexedMap buildColumn |> Ned.fromNelMap .name
    , primaryKey = table.primaryKey |> Maybe.map buildPrimaryKey
    , uniques = table.uniques |> List.map buildUnique
    , indexes = table.indexes |> List.map buildIndex
    , checks = table.checks |> List.map buildCheck
    , comment = table.comment |> Maybe.map buildComment
    , sources = [ { id = source.id, lines = table.source |> Nel.map (\l -> { no = l.line, text = l.text }) } ]
    }


buildColumn : Int -> SqlColumn -> Column
buildColumn index column =
    { index = index
    , name = column.name
    , kind = column.kind
    , nullable = column.nullable
    , default = column.default
    , comment = column.comment |> Maybe.map buildComment
    , sources = [] -- FIXME
    }


buildPrimaryKey : SqlPrimaryKey -> PrimaryKey
buildPrimaryKey pk =
    { name = pk.name
    , columns = pk.columns
    , sources = [] -- FIXME
    }


buildUnique : SqlUnique -> Unique
buildUnique unique =
    { name = unique.name
    , columns = unique.columns
    , definition = unique.definition
    , sources = [] -- FIXME
    }


buildIndex : SqlIndex -> Index
buildIndex index =
    { name = index.name
    , columns = index.columns
    , definition = index.definition
    , sources = [] -- FIXME
    }


buildCheck : SqlCheck -> Check
buildCheck check =
    { name = check.name
    , columns = check.columns
    , predicate = check.predicate
    , sources = [] -- FIXME
    }


buildComment : String -> Comment
buildComment comment =
    { text = comment
    , sources = [] -- FIXME
    }


buildRelations : ProjectSource -> SqlTable -> List Relation
buildRelations source table =
    table.columns
        |> Nel.filterZip .foreignKey
        |> List.map
            (\( c, fk ) ->
                { name = fk.name
                , src = ColumnRef ( table.schema, table.table ) c.name
                , ref = ColumnRef ( fk.schema, fk.table ) fk.column
                , sources = [ { id = source.id, lines = Nel { no = 0, text = "TODO" } [] } ]
                }
            )
