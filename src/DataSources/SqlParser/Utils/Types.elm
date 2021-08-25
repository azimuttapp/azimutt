module DataSources.SqlParser.Utils.Types exposing (ParseError, RawSql, SqlColumnName, SqlColumnType, SqlColumnValue, SqlConstraintName, SqlForeignKeyRef, SqlLine, SqlPredicate, SqlSchemaName, SqlStatement, SqlTableName, SqlTableRef)

import Libs.Nel exposing (Nel)


type alias SqlLine =
    { file : String, line : Int, text : String }


type alias SqlStatement =
    Nel SqlLine


type alias RawSql =
    String


type alias ParseError =
    String


type alias SqlConstraintName =
    String


type alias SqlSchemaName =
    String


type alias SqlTableName =
    String


type alias SqlColumnName =
    String


type alias SqlColumnType =
    String


type alias SqlColumnValue =
    String


type alias SqlPredicate =
    String


type alias SqlTableRef =
    { schema : Maybe SqlSchemaName, table : SqlTableName }


type alias SqlForeignKeyRef =
    { schema : Maybe SqlSchemaName, table : SqlTableName, column : Maybe SqlColumnName }
