module DataSources.AmlParser.AmlParser exposing (AmlColumn, AmlColumnName, AmlColumnProps, AmlColumnRef, AmlColumnType, AmlColumnValue, AmlComment, AmlNotes, AmlSchemaName, AmlTable, AmlTableName, AmlTableProps, AmlTableRef, parse)

import Libs.Models exposing (FileContent)
import Libs.Models.Position exposing (Position)
import Libs.Nel exposing (Nel)
import Libs.Tailwind exposing (Color)



-- specs from https://azimutt.app/blog/aml-a-language-to-define-your-database-schema


type alias AmlTable =
    { schema : Maybe AmlSchemaName
    , table : AmlTableName
    , props : Maybe AmlTableProps
    , notes : Maybe AmlNotes
    , comment : Maybe AmlComment
    , columns : List AmlColumn
    }


type alias AmlTableProps =
    { position : Maybe Position, color : Maybe Color }


type alias AmlColumn =
    { name : AmlColumnName
    , kind : Maybe AmlColumnType
    , default : Maybe AmlColumnValue
    , nullable : Bool
    , primaryKey : Bool
    , index : Maybe String
    , unique : Maybe String
    , check : Maybe String
    , foreignKey : Maybe AmlColumnRef
    , props : Maybe AmlColumnProps
    , notes : Maybe AmlNotes
    , comment : Maybe AmlComment
    }


type alias AmlColumnProps =
    { hidden : Bool }


type alias AmlTableRef =
    { schema : Maybe AmlSchemaName, table : AmlTableName }


type alias AmlColumnRef =
    { schema : Maybe AmlSchemaName, table : AmlTableName, column : AmlColumnName }


type alias AmlSchemaName =
    String


type alias AmlTableName =
    String


type alias AmlColumnName =
    String


type alias AmlColumnType =
    String


type alias AmlColumnValue =
    String


type alias AmlNotes =
    String


type alias AmlComment =
    String


parse : FileContent -> Result (Nel String) (List AmlTable)
parse _ =
    Ok []
