module DataSources.SqlParser.TestHelpers.Tests exposing (parsedColumn, parsedTable, testParse, testParseSql, testParseStatement)

import DataSources.SqlParser.Parsers.CreateTable exposing (ParsedColumn, ParsedTable)
import DataSources.SqlParser.StatementParser exposing (Command, parse)
import DataSources.SqlParser.Utils.Types exposing (RawSql, SqlStatement)
import Expect
import Libs.Nel as Nel exposing (Nel)
import Test exposing (Test, test)


testParseStatement : String -> RawSql -> Command -> Test
testParseStatement name sql command =
    test name (\_ -> sql |> asStatement |> parse |> Result.map Tuple.second |> Expect.equal (Ok command))


testParse : ( SqlStatement -> Result e a, String ) -> RawSql -> a -> Test
testParse ( parse, name ) sql result =
    test name (\_ -> sql |> asStatement |> parse |> Expect.equal (Ok result))


testParseSql : ( RawSql -> Result e a, String ) -> RawSql -> a -> Test
testParseSql ( parse, name ) sql result =
    test name (\_ -> sql |> parse |> Expect.equal (Ok result))


asStatement : RawSql -> SqlStatement
asStatement sql =
    sql
        |> String.trim
        |> String.split "\n"
        |> List.indexedMap (\i l -> { line = i, text = l })
        |> Nel.fromList
        |> Maybe.withDefault { head = { line = 0, text = sql |> String.trim }, tail = [] }


parsedTable : ParsedTable
parsedTable =
    { schema = Nothing
    , table = "changeme"
    , columns = Nel parsedColumn []
    , primaryKey = Nothing
    , foreignKeys = []
    , uniques = []
    , indexes = []
    , checks = []
    }


parsedColumn : ParsedColumn
parsedColumn =
    { name = "changeme"
    , kind = "changeme"
    , nullable = True
    , default = Nothing
    , primaryKey = Nothing
    , foreignKey = Nothing
    , unique = Nothing
    , check = Nothing
    }
