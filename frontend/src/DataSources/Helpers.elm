module DataSources.Helpers exposing (Line, SourceLine, defaultCheckName, defaultIndexName, defaultPkName, defaultRelName, defaultUniqueName)

import Models.Project.CheckName exposing (CheckName)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.IndexName exposing (IndexName)
import Models.Project.PrimaryKeyName exposing (PrimaryKeyName)
import Models.Project.RelationName exposing (RelationName)
import Models.Project.TableName exposing (TableName)
import Models.Project.UniqueName exposing (UniqueName)


type alias SourceLine =
    { index : Int, text : Line }


type alias Line =
    String


defaultPkName : TableName -> PrimaryKeyName
defaultPkName table =
    table ++ "_pk_az"


defaultRelName : TableName -> ColumnName -> RelationName
defaultRelName table column =
    table ++ "_" ++ column ++ "_fk_az"


defaultUniqueName : TableName -> ColumnName -> UniqueName
defaultUniqueName table column =
    table ++ "_" ++ column ++ "_unique_az"


defaultIndexName : TableName -> ColumnName -> IndexName
defaultIndexName table column =
    table ++ "_" ++ column ++ "_index_az"


defaultCheckName : TableName -> ColumnName -> CheckName
defaultCheckName table column =
    table ++ "_" ++ column ++ "_check_az"
