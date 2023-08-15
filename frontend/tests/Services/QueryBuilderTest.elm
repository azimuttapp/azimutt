module Services.QueryBuilderTest exposing (..)

import Expect
import Libs.Models.DatabaseKind exposing (DatabaseKind(..))
import Libs.Nel as Nel exposing (Nel)
import Models.DbValue exposing (DbValue(..))
import Models.Project.ColumnPath as ColumnPath
import Models.Project.ColumnType exposing (ColumnType)
import Models.Project.TableId exposing (TableId)
import Services.QueryBuilder exposing (FilterOperation(..), FilterOperator(..), TableFilter, decodeRowQuery, encodeRowQuery, filterTable, findRow, limitResults)
import Test exposing (Test, describe, test)
import TestHelpers.Helpers exposing (testSerde)


suite : Test
suite =
    describe "QueryBuilder"
        [ describe "filterTable"
            [ test "empty" (\_ -> fTable PostgreSQL Nothing [] |> Expect.equal "")
            , test "table only" (\_ -> fTable PostgreSQL publicUsers [] |> Expect.equal "SELECT * FROM public.users;")
            , test "with eq filter" (\_ -> fTable PostgreSQL users [ filter OpAnd "id" OpEqual (DbInt 3) "int" ] |> Expect.equal "SELECT * FROM users WHERE id=3;")
            , test "with 2 filters" (\_ -> fTable PostgreSQL users [ filter OpAnd "id" OpNotEqual (DbInt 3) "int", filter OpAnd "name" OpIsNotNull (DbString "") "text" ] |> Expect.equal "SELECT * FROM users WHERE id!=3 AND name IS NOT NULL;")
            , test "with json" (\_ -> fTable PostgreSQL users [ filter OpAnd "data:id" OpEqual (DbInt 3) "int" ] |> Expect.equal "SELECT * FROM users WHERE data->>'id'=3;")
            ]
        , describe "findRow"
            [ test "with id" (\_ -> fRow PostgreSQL ( "public", "users" ) [ ( "id", DbInt 3 ) ] |> Expect.equal "SELECT * FROM public.users WHERE id=3 LIMIT 1;")
            , test "composite key" (\_ -> fRow PostgreSQL ( "", "user_roles" ) [ ( "user_id", DbInt 3 ), ( "role_id", DbString "ac1f3" ) ] |> Expect.equal "SELECT * FROM user_roles WHERE user_id=3 AND role_id='ac1f3' LIMIT 1;")
            ]
        , describe "limitResults"
            [ test "without limit" (\_ -> limitResults PostgreSQL "SELECT * FROM users;" |> Expect.equal "SELECT * FROM users LIMIT 100;")
            , test "with limit" (\_ -> limitResults PostgreSQL "SELECT * FROM users LIMIT 10;" |> Expect.equal "SELECT * FROM users LIMIT 10;")
            , test "with offset" (\_ -> limitResults PostgreSQL "SELECT * FROM users OFFSET 10;" |> Expect.equal "SELECT * FROM users LIMIT 100 OFFSET 10;")
            , test "with limit & offset" (\_ -> limitResults PostgreSQL "SELECT * FROM users LIMIT 10 OFFSET 10;" |> Expect.equal "SELECT * FROM users LIMIT 10 OFFSET 10;")
            , test "multiline" (\_ -> limitResults PostgreSQL """SELECT
                                                                 e.id,
                                                                 e.name
                                                               FROM events e
                                                               WHERE e.name='project_loaded';  """ |> Expect.equal """SELECT
                                                                 e.id,
                                                                 e.name
                                                               FROM events e
                                                               WHERE e.name='project_loaded' LIMIT 100;""")
            ]
        , describe "serde"
            [ testSerde "RowQuery" encodeRowQuery decodeRowQuery { table = ( "", "" ), primaryKey = { head = { column = { head = "", tail = [] }, value = DbNull }, tail = [] } } ]
        ]


fTable : DatabaseKind -> Maybe TableId -> List TableFilter -> String
fTable db table filters =
    filterTable db { table = table, filters = filters }


fRow : DatabaseKind -> TableId -> List ( String, DbValue ) -> String
fRow db table matches =
    matches |> Nel.fromList |> Maybe.map (\primaryKey -> findRow db { table = table, primaryKey = primaryKey |> Nel.map (\( col, value ) -> { column = Nel col [], value = value }) }) |> Maybe.withDefault ""


publicUsers : Maybe TableId
publicUsers =
    Just ( "public", "users" )


users : Maybe TableId
users =
    Just ( "", "users" )


filter : FilterOperator -> String -> FilterOperation -> DbValue -> ColumnType -> TableFilter
filter operator path operation value kind =
    { operator = operator, column = ColumnPath.fromString path, kind = kind, nullable = True, operation = operation, value = value }
