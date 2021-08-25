module DataSources.SqlParser.FileParserTest exposing (..)

import DataSources.SqlParser.FileParser exposing (SqlTable, buildStatements, parseLines, updateColumn, updateTable)
import DataSources.SqlParser.Utils.Types exposing (SqlLine, SqlStatement)
import Dict
import Expect
import Libs.Nel exposing (Nel)
import Test exposing (Test, describe, test)


fileName : String
fileName =
    "file.sql"


fileContent : String
fileContent =
    """
-- a comment

CREATE TABLE public.users (
  id bigint NOT NULL,
  name character varying(255)
);

COMMENT ON TABLE public.users IS 'A comment ; ''tricky'' one';

ALTER TABLE ONLY public.users
  ADD CONSTRAINT users_id_pkey PRIMARY KEY (id);
"""


fileLines : List SqlLine
fileLines =
    [ { file = fileName, line = 1, text = "" }
    , { file = fileName, line = 2, text = "-- a comment" }
    , { file = fileName, line = 3, text = "" }
    , { file = fileName, line = 4, text = "CREATE TABLE public.users (" }
    , { file = fileName, line = 5, text = "  id bigint NOT NULL," }
    , { file = fileName, line = 6, text = "  name character varying(255)" }
    , { file = fileName, line = 7, text = ");" }
    , { file = fileName, line = 8, text = "" }
    , { file = fileName, line = 9, text = "COMMENT ON TABLE public.users IS 'A comment ; ''tricky'' one';" }
    , { file = fileName, line = 10, text = "" }
    , { file = fileName, line = 11, text = "ALTER TABLE ONLY public.users" }
    , { file = fileName, line = 12, text = "  ADD CONSTRAINT users_id_pkey PRIMARY KEY (id);" }
    , { file = fileName, line = 13, text = "" }
    ]


fileStatements : List SqlStatement
fileStatements =
    [ createUsersStatement, commentUsersStatement, addPrimaryKeyOnUsersStatement ]


createUsersStatement : SqlStatement
createUsersStatement =
    { head = { file = fileName, line = 4, text = "CREATE TABLE public.users (" }
    , tail =
        [ { file = fileName, line = 5, text = "  id bigint NOT NULL," }
        , { file = fileName, line = 6, text = "  name character varying(255)" }
        , { file = fileName, line = 7, text = ");" }
        ]
    }


commentUsersStatement : SqlStatement
commentUsersStatement =
    { head = { file = fileName, line = 9, text = "COMMENT ON TABLE public.users IS 'A comment ; ''tricky'' one';" }, tail = [] }


addPrimaryKeyOnUsersStatement : SqlStatement
addPrimaryKeyOnUsersStatement =
    { head = { file = fileName, line = 11, text = "ALTER TABLE ONLY public.users" }
    , tail = [ { file = fileName, line = 12, text = "  ADD CONSTRAINT users_id_pkey PRIMARY KEY (id);" } ]
    }


users : SqlTable
users =
    { schema = "public"
    , table = "users"
    , columns =
        Nel { name = "id", kind = "bigint", nullable = False, default = Nothing, foreignKey = Nothing, comment = Nothing }
            [ { name = "name", kind = "character varying(255)", nullable = True, default = Nothing, foreignKey = Nothing, comment = Nothing } ]
    , primaryKey = Nothing
    , indexes = []
    , uniques = []
    , checks = []
    , comment = Nothing
    , source = createUsersStatement
    }


usersWithComment : SqlTable
usersWithComment =
    { schema = "public"
    , table = "users"
    , columns =
        Nel { name = "id", kind = "bigint", nullable = False, default = Nothing, foreignKey = Nothing, comment = Nothing }
            [ { name = "name", kind = "character varying(255)", nullable = True, default = Nothing, foreignKey = Nothing, comment = Nothing } ]
    , primaryKey = Nothing
    , indexes = []
    , uniques = []
    , checks = []
    , comment = Just "A comment ; 'tricky' one"
    , source = createUsersStatement
    }


usersWithIdComment : SqlTable
usersWithIdComment =
    { schema = "public"
    , table = "users"
    , columns =
        Nel { name = "id", kind = "bigint", nullable = False, default = Nothing, foreignKey = Nothing, comment = Just "A comment" }
            [ { name = "name", kind = "character varying(255)", nullable = True, default = Nothing, foreignKey = Nothing, comment = Nothing } ]
    , primaryKey = Nothing
    , indexes = []
    , uniques = []
    , checks = []
    , comment = Nothing
    , source = createUsersStatement
    }


suite : Test
suite =
    describe "FileParser"
        [ describe "updateTable"
            [ test "basic"
                (\_ ->
                    updateTable "public.users" (\t -> Ok { t | comment = Just "A comment ; 'tricky' one" }) (Dict.singleton "public.users" users)
                        |> Expect.equal (Ok (Dict.singleton "public.users" usersWithComment))
                )
            ]
        , describe "updateColumn"
            [ test "basic"
                (\_ ->
                    updateColumn "public.users" "id" (\c -> Ok { c | comment = Just "A comment" }) (Dict.singleton "public.users" users)
                        |> Expect.equal (Ok (Dict.singleton "public.users" usersWithIdComment))
                )
            ]
        , describe "buildStatements"
            [ test "basic" (\_ -> buildStatements fileLines |> Expect.equal fileStatements)
            , test "with BEGIN"
                (\_ ->
                    buildStatements
                        [ { file = fileName, line = 1, text = "CREATE FUNCTION public.set_log_min_duration(integer) RETURNS void" }
                        , { file = fileName, line = 2, text = "    LANGUAGE plpgsql STRICT SECURITY DEFINER" }
                        , { file = fileName, line = 3, text = "    SET search_path TO 'pg_catalog', 'pg_temp'" }
                        , { file = fileName, line = 4, text = "AS $_$" }
                        , { file = fileName, line = 5, text = "BEGIN" }
                        , { file = fileName, line = 6, text = "    EXECUTE 'SET log_min_duration_statement = ' || $1::text;" }
                        , { file = fileName, line = 7, text = "END" }
                        , { file = fileName, line = 8, text = "$_$;" }
                        ]
                        |> List.length
                        |> Expect.equal 1
                )
            ]
        , describe "parseLines"
            [ test "basic" (\_ -> parseLines fileName fileContent |> Expect.equal fileLines)
            ]
        ]
