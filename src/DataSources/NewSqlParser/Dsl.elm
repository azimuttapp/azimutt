module DataSources.NewSqlParser.Dsl exposing (CheckInner, ColumnConstraint(..), ForeignKeyInner, ForeignKeyRef, IndexInner, ParseError, ParsedColumn, ParsedConstraint(..), ParsedTable, PrimaryKeyInner, SqlStatement, UniqueInner)

import Libs.Nel exposing (Nel)


type alias SqlStatement =
    String


type alias ParsedTable =
    { schema : Maybe String
    , table : String
    , columns : List ParsedColumn
    , constraints : List ParsedConstraint
    }


type alias ParsedColumn =
    { name : String
    , kind : String
    , nullable : Bool
    , default : Maybe String
    , primaryKey : Maybe String
    , foreignKey : Maybe ( String, ForeignKeyRef )
    , check : Maybe String
    }


type alias ForeignKeyRef =
    { schema : Maybe String, table : String, column : Maybe String }


type ColumnConstraint
    = ColumnPrimaryKey
    | ColumnForeignKey ForeignKeyRef


type ParsedConstraint
    = PrimaryKey PrimaryKeyInner
    | ForeignKey ForeignKeyInner
    | Unique UniqueInner
    | Index IndexInner
    | Check CheckInner


type alias PrimaryKeyInner =
    { name : Maybe String, columns : Nel String }


type alias ForeignKeyInner =
    { name : Maybe String, src : String, ref : ForeignKeyRef }


type alias UniqueInner =
    { name : String, columns : Nel String }


type alias IndexInner =
    { name : String, columns : Nel String, definition : String }


type alias CheckInner =
    { name : String, columns : List String, predicate : String }


type alias ParseError =
    String
