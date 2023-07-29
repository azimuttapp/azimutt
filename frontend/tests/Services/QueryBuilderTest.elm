module Services.QueryBuilderTest exposing (..)

import Expect
import Libs.Models.DatabaseKind exposing (DatabaseKind(..))
import Libs.Nel as Nel exposing (Nel)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnType exposing (ColumnType)
import Models.Project.TableId exposing (TableId)
import Services.QueryBuilder exposing (FilterOperation(..), FilterOperator(..), TableFilter, filterTable, findRow, limitResults)
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "QueryBuilder"
        [ describe "filterTable"
            [ test "empty" (\_ -> fTable PostgreSQL Nothing [] |> Expect.equal "")
            , test "table only" (\_ -> fTable PostgreSQL publicUsers [] |> Expect.equal "SELECT * FROM public.users;")
            , test "with eq filter" (\_ -> fTable PostgreSQL users [ filter OpAnd "id" OpEqual "3" "int" ] |> Expect.equal "SELECT * FROM users WHERE id=3;")
            , test "with 2 filters" (\_ -> fTable PostgreSQL users [ filter OpAnd "id" OpNotEqual "3" "int", filter OpAnd "name" OpIsNotNull "" "text" ] |> Expect.equal "SELECT * FROM users WHERE id!=3 AND name IS NOT NULL;")
            ]
        , describe "findRow"
            [ test "with id" (\_ -> fRow PostgreSQL ( "public", "users" ) [ ( "id", "3", "int" ) ] |> Expect.equal "SELECT * FROM public.users WHERE id=3 LIMIT 1;")
            , test "composite key" (\_ -> fRow PostgreSQL ( "", "user_roles" ) [ ( "user_id", "3", "int" ), ( "role_id", "ac1f3", "varchar" ) ] |> Expect.equal "SELECT * FROM user_roles WHERE user_id=3 AND role_id='ac1f3' LIMIT 1;")
            ]
        , describe "limitResults"
            [ test "without limit" (\_ -> limitResults PostgreSQL "SELECT * FROM users;" |> Expect.equal "SELECT * FROM users LIMIT 100;")
            , test "with limit" (\_ -> limitResults PostgreSQL "SELECT * FROM users LIMIT 10;" |> Expect.equal "SELECT * FROM users LIMIT 10;")
            , test "with offset" (\_ -> limitResults PostgreSQL "SELECT * FROM users OFFSET 10;" |> Expect.equal "SELECT * FROM users LIMIT 100 OFFSET 10;")
            , test "with limit & offset" (\_ -> limitResults PostgreSQL "SELECT * FROM users LIMIT 10 OFFSET 10;" |> Expect.equal "SELECT * FROM users LIMIT 10 OFFSET 10;")
            ]
        ]


fTable : DatabaseKind -> Maybe TableId -> List TableFilter -> String
fTable db table filters =
    filterTable db { table = table, filters = filters }


fRow : DatabaseKind -> TableId -> List ( String, String, String ) -> String
fRow db table matches =
    matches |> Nel.fromList |> Maybe.map (\primaryKey -> findRow db { table = table, primaryKey = primaryKey |> Nel.map (\( col, value, kind ) -> { column = Nel col [], kind = kind, value = value }) }) |> Maybe.withDefault ""


publicUsers : Maybe TableId
publicUsers =
    Just ( "public", "users" )


users : Maybe TableId
users =
    Just ( "", "users" )


filter : FilterOperator -> ColumnName -> FilterOperation -> String -> ColumnType -> TableFilter
filter operator column operation value kind =
    { operator = operator, column = Nel column [], kind = kind, operation = operation, value = value }
