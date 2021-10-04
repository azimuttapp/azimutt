module DataSources.NewSqlParser.Utils.Types exposing (ForeignKeyRef, ParseError, ParsedColumn, ParsedTable, SqlStatement)


type alias SqlStatement =
    String


type alias ParsedTable =
    { schema : Maybe String
    , table : String
    , columns : List ParsedColumn
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


type alias ParseError =
    String
