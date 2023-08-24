module Services.QueryBuilderTest exposing (..)

import Dict
import Expect
import Libs.Models.DatabaseKind exposing (DatabaseKind(..))
import Libs.Nel as Nel exposing (Nel)
import Models.DbValue exposing (DbValue(..))
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath)
import Models.Project.ColumnType exposing (ColumnType)
import Models.Project.TableId exposing (TableId)
import Services.QueryBuilder exposing (FilterOperation(..), FilterOperator(..), IncomingRowsQuery, RowQuery, TableFilter, filterTable, findRow, incomingRows, limitResults)
import Test exposing (Test, describe, only, test)


suite : Test
suite =
    describe "QueryBuilder"
        [ describe "filterTable"
            [ test "table only" (\_ -> fTable PostgreSQL publicUsers [] |> Expect.equal """SELECT *
FROM "public"."users";
""")
            , test "with eq filter" (\_ -> fTable PostgreSQL users [ filter OpAnd "id" OpEqual (DbInt 3) ] |> Expect.equal """SELECT *
FROM "users"
WHERE "id"=3;
""")
            , test "with 2 filters" (\_ -> fTable PostgreSQL users [ filter OpAnd "id" OpNotEqual (DbInt 3), filter OpAnd "name" OpIsNotNull (DbString "") ] |> Expect.equal """SELECT *
FROM "users"
WHERE "id"!=3 AND "name" IS NOT NULL;
""")
            , test "with json" (\_ -> fTable PostgreSQL users [ filter OpAnd "data:id" OpEqual (DbInt 3) ] |> Expect.equal """SELECT *
FROM "users"
WHERE ("data"->>'id')::int=3;
""")
            ]
        , describe "findRow"
            [ test "with id" (\_ -> fRow PostgreSQL ( "public", "users" ) [ ( "id", DbInt 3 ) ] |> Expect.equal """SELECT *
FROM "public"."users"
WHERE "id"=3
LIMIT 1;
""")
            , test "composite key" (\_ -> fRow PostgreSQL ( "", "user_roles" ) [ ( "user_id", DbInt 3 ), ( "role_id", DbString "ac1f3" ) ] |> Expect.equal """SELECT *
FROM "user_roles"
WHERE "user_id"=3 AND "role_id"='ac1f3'
LIMIT 1;
""")
            ]
        , describe "limitResults"
            [ test "without limit" (\_ -> limitResults PostgreSQL "SELECT * FROM users;" |> Expect.equal "SELECT * FROM users\nLIMIT 100;\n")
            , test "with limit" (\_ -> limitResults PostgreSQL "SELECT * FROM users LIMIT 10;" |> Expect.equal "SELECT * FROM users LIMIT 10;")
            , test "with offset" (\_ -> limitResults PostgreSQL "SELECT * FROM users OFFSET 10;" |> Expect.equal "SELECT * FROM users\nLIMIT 100 OFFSET 10;\n")
            , test "with limit & offset" (\_ -> limitResults PostgreSQL "SELECT * FROM users LIMIT 10 OFFSET 10;" |> Expect.equal "SELECT * FROM users LIMIT 10 OFFSET 10;")
            , test "multiline" (\_ -> limitResults PostgreSQL """SELECT e.id, e.name
FROM events e
WHERE e.name='project_loaded';  """ |> Expect.equal """SELECT e.id, e.name
FROM events e
WHERE e.name='project_loaded'
LIMIT 100;
""")
            ]
        , describe "incomingRows"
            [ test "simple"
                (\_ ->
                    incomingRows PostgreSQL ([ ( ( "", "events" ), inQuery [ ( "id", "int" ) ] [ ( "created_by", "int" ) ] ) ] |> Dict.fromList) (rowQuery ( "", "users" ) "id" (DbInt 1))
                        |> Expect.equal """SELECT
  array(SELECT json_build_object('id', s."id") FROM "events" s WHERE s."created_by" = m."id" LIMIT 20) as ".events"
FROM "users" m
WHERE "id"=1
LIMIT 1;
"""
                )
            , test "several tables & foreign keys"
                (\_ ->
                    incomingRows PostgreSQL ([ ( ( "", "events" ), inQuery [ ( "id", "int" ) ] [ ( "created_by", "int" ) ] ), ( ( "public", "organizations" ), inQuery [ ( "id", "int" ) ] [ ( "created_by", "int" ), ( "updated_by", "int" ) ] ) ] |> Dict.fromList) (rowQuery ( "", "users" ) "id" (DbInt 1))
                        |> Expect.equal """SELECT
  array(SELECT json_build_object('id', s."id") FROM "events" s WHERE s."created_by" = m."id" LIMIT 20) as ".events",
  array(SELECT json_build_object('id', s."id") FROM "public"."organizations" s WHERE s."created_by" = m."id" OR s."updated_by" = m."id" LIMIT 20) as "public.organizations"
FROM "users" m
WHERE "id"=1
LIMIT 1;
"""
                )
            , test "composite pk & json"
                (\_ ->
                    incomingRows PostgreSQL ([ ( ( "", "events" ), inQuery [ ( "id", "int" ), ( "details.id", "int" ) ] [ ( "details.created_by", "uuid" ) ] ) ] |> Dict.fromList) (rowQuery ( "", "users" ) "id" (DbString "11bd9544-d56a-43d7-9065-6f1f25addf8a"))
                        |> Expect.equal """SELECT
  array(SELECT json_build_object('id', s."id", 'details:id', (s."details"->>'id')::int) FROM "events" s WHERE (s."details"->>'created_by')::uuid = m."id" LIMIT 20) as ".events"
FROM "users" m
WHERE "id"='11bd9544-d56a-43d7-9065-6f1f25addf8a'
LIMIT 1;
"""
                )
            ]
        ]


fTable : DatabaseKind -> TableId -> List TableFilter -> String
fTable db table filters =
    filterTable db { table = table, filters = filters }


fRow : DatabaseKind -> TableId -> List ( String, DbValue ) -> String
fRow db table matches =
    matches |> Nel.fromList |> Maybe.map (\primaryKey -> findRow db { table = table, primaryKey = primaryKey |> Nel.map (\( col, value ) -> { column = Nel col [], value = value }) }) |> Maybe.withDefault ""


publicUsers : TableId
publicUsers =
    ( "public", "users" )


users : TableId
users =
    ( "", "users" )


filter : FilterOperator -> String -> FilterOperation -> DbValue -> TableFilter
filter operator path operation value =
    { operator = operator, column = ColumnPath.fromString path, operation = operation, value = value }


rowQuery : TableId -> ColumnName -> DbValue -> RowQuery
rowQuery table column value =
    { table = table, primaryKey = Nel { column = Nel column [], value = value } [] }


inQuery : List ( String, ColumnType ) -> List ( String, ColumnType ) -> IncomingRowsQuery
inQuery pk fks =
    { primaryKey = pk |> List.map (Tuple.mapFirst cPath) |> Nel.fromList |> Maybe.withDefault (Nel ( Nel "id" [], "int" ) []), foreignKeys = fks |> List.map (Tuple.mapFirst cPath) }


cPath : String -> ColumnPath
cPath col =
    col |> String.split "." |> Nel.fromList |> Maybe.withDefault (Nel col [])
