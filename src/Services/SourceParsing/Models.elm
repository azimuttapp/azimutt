module Services.SourceParsing.Models exposing (ParsingMsg(..), ParsingState)

import DataSources.SqlParser.FileParser exposing (SchemaError, SqlSchema)
import DataSources.SqlParser.StatementParser exposing (Command)
import DataSources.SqlParser.Utils.Types exposing (ParseError, SqlStatement)
import Dict exposing (Dict)
import Libs.Models exposing (FileContent, FileLineContent)


type alias ParsingState msg =
    { cpt : Int
    , fileContent : FileContent
    , lines : Maybe (List FileLineContent)
    , statements : Maybe (Dict Int SqlStatement)
    , commands : Maybe (Dict Int ( SqlStatement, Result (List ParseError) Command ))
    , schemaIndex : Int
    , schemaErrors : List (List SchemaError)
    , schema : Maybe SqlSchema
    , buildMsg : ParsingMsg -> msg
    , buildProject : msg
    }


type ParsingMsg
    = BuildLines
    | BuildStatements
    | BuildCommand
    | EvolveSchema
