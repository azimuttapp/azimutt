module DataSources.NewSqlParser.Dsl exposing (ForeignKeyRef, ParseError, ParsedColumn, ParsedConstraint(..), ParsedTable, SqlStatement)

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


type ParsedConstraint
    = PrimaryKey (Maybe String) (Nel String)
    | ForeignKey (Maybe String) String ForeignKeyRef
    | Unique String (Nel String)
    | Index String (Nel String) String
    | Check String (List String) String


type alias ParseError =
    String
