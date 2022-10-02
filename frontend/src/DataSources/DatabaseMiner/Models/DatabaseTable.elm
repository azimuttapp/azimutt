module DataSources.DatabaseMiner.Models.DatabaseTable exposing (DatabaseCheck, DatabaseColumn, DatabaseIndex, DatabasePrimaryKey, DatabaseTable, DatabaseUnique, decode)

import Json.Decode as Decode
import Libs.Json.Decode as Decode


type alias DatabaseTable =
    { schema : String
    , table : String
    , view : Bool
    , columns : List DatabaseColumn
    , primaryKey : Maybe DatabasePrimaryKey
    , uniques : List DatabaseUnique
    , indexes : List DatabaseIndex
    , checks : List DatabaseCheck
    , comment : Maybe String
    }


type alias DatabaseColumn =
    { name : String
    , kind : String
    , nullable : Bool
    , default : Maybe String
    , comment : Maybe String
    }


type alias DatabasePrimaryKey =
    { name : Maybe String
    , columns : List String
    }


type alias DatabaseUnique =
    { name : Maybe String
    , columns : List String
    , definition : Maybe String
    }


type alias DatabaseIndex =
    { name : Maybe String
    , columns : List String
    , definition : Maybe String
    }


type alias DatabaseCheck =
    { name : Maybe String
    , columns : List String
    , predicate : Maybe String
    }


decode : Decode.Decoder DatabaseTable
decode =
    Decode.map9 DatabaseTable
        (Decode.field "schema" Decode.string)
        (Decode.field "table" Decode.string)
        (Decode.field "view" Decode.bool)
        (Decode.field "columns" (Decode.list decodeDatabaseColumn))
        (Decode.maybeField "primaryKey" decodeDatabasePrimaryKey)
        (Decode.field "uniques" (Decode.list decodeDatabaseUnique))
        (Decode.field "indexes" (Decode.list decodeDatabaseIndex))
        (Decode.field "checks" (Decode.list decodeDatabaseCheck))
        (Decode.maybeField "comment" Decode.string)


decodeDatabaseColumn : Decode.Decoder DatabaseColumn
decodeDatabaseColumn =
    Decode.map5 DatabaseColumn
        (Decode.field "name" Decode.string)
        (Decode.field "type" Decode.string)
        (Decode.field "nullable" Decode.bool)
        (Decode.maybeField "default" Decode.string)
        (Decode.maybeField "comment" Decode.string)


decodeDatabasePrimaryKey : Decode.Decoder DatabasePrimaryKey
decodeDatabasePrimaryKey =
    Decode.map2 DatabasePrimaryKey
        (Decode.maybeField "name" Decode.string)
        (Decode.field "columns" (Decode.list Decode.string))


decodeDatabaseUnique : Decode.Decoder DatabaseUnique
decodeDatabaseUnique =
    Decode.map3 DatabaseUnique
        (Decode.maybeField "name" Decode.string)
        (Decode.field "columns" (Decode.list Decode.string))
        (Decode.maybeField "definition" Decode.string)


decodeDatabaseIndex : Decode.Decoder DatabaseIndex
decodeDatabaseIndex =
    Decode.map3 DatabaseIndex
        (Decode.maybeField "name" Decode.string)
        (Decode.field "columns" (Decode.list Decode.string))
        (Decode.maybeField "definition" Decode.string)


decodeDatabaseCheck : Decode.Decoder DatabaseCheck
decodeDatabaseCheck =
    Decode.map3 DatabaseCheck
        (Decode.maybeField "name" Decode.string)
        (Decode.field "columns" (Decode.list Decode.string))
        (Decode.maybeField "predicate" Decode.string)
