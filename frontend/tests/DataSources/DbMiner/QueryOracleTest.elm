module DataSources.DbMiner.QueryOracleTest exposing (..)

import DataSources.DbMiner.DbTypes exposing (FilterOperation(..), FilterOperator(..), IncomingRowsQuery, RowQuery, TableFilter)
import DataSources.DbMiner.QueryOracle exposing (addLimit, exploreColumn, exploreTable, filterTable, findRow, incomingRows)
import Dict
import Expect
import Libs.Nel as Nel exposing (Nel)
import Models.DbValue exposing (DbValue(..))
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath)
import Models.Project.ColumnType exposing (ColumnType)
import Models.Project.TableId exposing (TableId)
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "QueryOracle"
        [ describe "exploreTable" exploreTableSuite
        , describe "exploreColumn" exploreColumnSuite
        , describe "filterTable" filterTableSuite
        , describe "findRow" findRowSuite
        , describe "incomingRows" incomingRowsSuite
        , describe "addLimit" addLimitSuite
        ]


exploreTableSuite : List Test
exploreTableSuite =
    [ test "with schema" (\_ -> exploreTable ( "schema", "table" ) |> Expect.equal """SELECT *
FROM "schema"."table";
""")
    , test "with empty schema" (\_ -> exploreTable ( "", "table" ) |> Expect.equal """SELECT *
FROM "table";
""")
    ]


exploreColumnSuite : List Test
exploreColumnSuite =
    [ test "with schema" (\_ -> exploreColumn ( "schema", "table" ) (ColumnPath.fromString "column") |> Expect.equal """SELECT
  t."column",
  count(*) AS COUNT
FROM "schema"."table" t
GROUP BY t."column"
ORDER BY COUNT DESC, "column";
""")
    , test "with empty schema" (\_ -> exploreColumn ( "", "table" ) (ColumnPath.fromString "column") |> Expect.equal """SELECT
  t."column",
  count(*) AS COUNT
FROM "table" t
GROUP BY t."column"
ORDER BY COUNT DESC, "column";
""")
    , test "with json column" (\_ -> exploreColumn ( "", "table" ) (ColumnPath.fromString "data:email") |> Expect.equal """SELECT
  t."data".email AS "email",
  count(*) AS COUNT
FROM "table" t
GROUP BY t."data".email
ORDER BY COUNT DESC, "email";
""")
    ]


filterTableSuite : List Test
filterTableSuite =
    [ test "table only" (\_ -> filterTable publicUsers [] |> Expect.equal """SELECT *
FROM "public"."users" t;
""")
    , test "with eq filter" (\_ -> filterTable users [ filter DbAnd "id" DbEqual (DbInt 3) ] |> Expect.equal """SELECT *
FROM "users" t
WHERE t."id"=3;
""")
    , test "with 2 filters" (\_ -> filterTable users [ filter DbAnd "id" DbNotEqual (DbInt 3), filter DbAnd "name" DbIsNotNull (DbString "") ] |> Expect.equal """SELECT *
FROM "users" t
WHERE t."id"!=3 AND t."name" IS NOT NULL;
""")
    , test "with json" (\_ -> filterTable users [ filter DbAnd "data:id" DbEqual (DbInt 3) ] |> Expect.equal """SELECT *
FROM "users" t
WHERE t."data".id=3;
""")
    ]


findRowSuite : List Test
findRowSuite =
    [ test "with id" (\_ -> fRow ( "public", "users" ) [ ( "id", DbInt 3 ) ] |> Expect.equal """SELECT *
FROM "public"."users"
WHERE "id"=3
FETCH FIRST 1 ROW ONLY;
""")
    , test "composite key" (\_ -> fRow ( "", "user_roles" ) [ ( "user_id", DbInt 3 ), ( "role_id", DbString "ac1f3" ) ] |> Expect.equal """SELECT *
FROM "user_roles"
WHERE "user_id"=3 AND "role_id"='ac1f3'
FETCH FIRST 1 ROW ONLY;
""")
    ]


incomingRowsSuite : List Test
incomingRowsSuite =
    [ test "simple" (\_ -> incomingRows (rowQuery ( "", "users" ) "id" (DbInt 1)) ([ ( ( "", "events" ), inQuery [ ( "id", "int" ) ] [ ( "created_by", "int" ) ] ) ] |> Dict.fromList) 20 |> Expect.equal """SELECT
  JSON_ARRAY((SELECT JSON_OBJECT('id' VALUE s."id") FROM "events" s WHERE s."created_by" = m."id" FETCH FIRST 20 ROWS ONLY) RETURNING JSON) AS ".events"
FROM "users" m
WHERE "id"=1
FETCH FIRST 1 ROW ONLY;
""")
    , test "several tables & foreign keys" (\_ -> incomingRows (rowQuery ( "", "users" ) "id" (DbInt 1)) ([ ( ( "", "events" ), inQuery [ ( "id", "int" ) ] [ ( "created_by", "int" ) ] ), ( ( "public", "organizations" ), inQuery [ ( "id", "int" ) ] [ ( "created_by", "int" ), ( "updated_by", "int" ) ] ) ] |> Dict.fromList) 20 |> Expect.equal """SELECT
  JSON_ARRAY((SELECT JSON_OBJECT('id' VALUE s."id") FROM "events" s WHERE s."created_by" = m."id" FETCH FIRST 20 ROWS ONLY) RETURNING JSON) AS ".events",
  JSON_ARRAY((SELECT JSON_OBJECT('id' VALUE s."id") FROM "public"."organizations" s WHERE s."created_by" = m."id" OR s."updated_by" = m."id" FETCH FIRST 20 ROWS ONLY) RETURNING JSON) AS "public.organizations"
FROM "users" m
WHERE "id"=1
FETCH FIRST 1 ROW ONLY;
""")
    , test "composite pk & json" (\_ -> incomingRows (rowQuery ( "", "users" ) "id" (DbString "11bd9544-d56a-43d7-9065-6f1f25addf8a")) ([ ( ( "", "events" ), inQuery [ ( "id", "int" ), ( "details.id", "int" ) ] [ ( "details.created_by", "uuid" ) ] ) ] |> Dict.fromList) 20 |> Expect.equal """SELECT
  JSON_ARRAY((SELECT JSON_OBJECT('id' VALUE s."id", 'details:id' VALUE s."details".id) FROM "events" s WHERE s."details".created_by = m."id" FETCH FIRST 20 ROWS ONLY) RETURNING JSON) AS ".events"
FROM "users" m
WHERE "id"='11bd9544-d56a-43d7-9065-6f1f25addf8a'
FETCH FIRST 1 ROW ONLY;
""")
    ]


addLimitSuite : List Test
addLimitSuite =
    [ test "without limit" (\_ -> addLimit "SELECT * FROM users;" |> Expect.equal "SELECT * FROM users\nFETCH FIRST 100 ROWS ONLY;\n")
    , test "with limit" (\_ -> addLimit "SELECT * FROM users FETCH FIRST 10 ROWS ONLY;" |> Expect.equal "SELECT * FROM users FETCH FIRST 10 ROWS ONLY;")
    , test "with limit next" (\_ -> addLimit "SELECT * FROM users FETCH NEXT 1 ROW ONLY;" |> Expect.equal "SELECT * FROM users FETCH NEXT 1 ROW ONLY;")
    , test "with offset" (\_ -> addLimit "SELECT * FROM users OFFSET 10 ROWS;" |> Expect.equal "SELECT * FROM users\nOFFSET 10 ROWS FETCH FIRST 100 ROWS ONLY;\n")
    , test "with offset singular" (\_ -> addLimit "SELECT * FROM users OFFSET 1 ROW;" |> Expect.equal "SELECT * FROM users\nOFFSET 1 ROW FETCH FIRST 100 ROWS ONLY;\n")
    , test "with limit & offset" (\_ -> addLimit "SELECT * FROM users OFFSET 1 ROW FETCH FIRST 10 ROWS ONLY;" |> Expect.equal "SELECT * FROM users OFFSET 1 ROW FETCH FIRST 10 ROWS ONLY;")
    , test "multiline" (\_ -> addLimit """SELECT e.id, e.name
FROM events e
WHERE e.name='project_loaded';  """ |> Expect.equal """SELECT e.id, e.name
FROM events e
WHERE e.name='project_loaded'
FETCH FIRST 100 ROWS ONLY;
""")
    , test "not on update" (\_ -> addLimit "UPDATE users SET deleted=null WHERE id=10;" |> Expect.equal "UPDATE users SET deleted=null WHERE id=10;")
    , test "lowercase" (\_ -> addLimit "select * from users;" |> Expect.equal "select * from users\nFETCH FIRST 100 ROWS ONLY;\n")
    ]



-- HELPERS


publicUsers : TableId
publicUsers =
    ( "public", "users" )


users : TableId
users =
    ( "", "users" )


filter : FilterOperator -> String -> FilterOperation -> DbValue -> TableFilter
filter operator path operation value =
    { operator = operator, column = ColumnPath.fromString path, operation = operation, value = value }


fRow : TableId -> List ( String, DbValue ) -> String
fRow table matches =
    matches |> Nel.fromList |> Maybe.map (\primaryKey -> findRow table (primaryKey |> Nel.map (\( col, value ) -> { column = Nel col [], value = value }))) |> Maybe.withDefault ""


rowQuery : TableId -> ColumnName -> DbValue -> RowQuery
rowQuery table column value =
    { table = table, primaryKey = Nel { column = Nel column [], value = value } [] }


inQuery : List ( String, ColumnType ) -> List ( String, ColumnType ) -> IncomingRowsQuery
inQuery pk fks =
    { primaryKey = pk |> List.map (Tuple.mapFirst cPath) |> Nel.fromList |> Maybe.withDefault (Nel ( Nel "id" [], "int" ) [])
    , foreignKeys = fks |> List.map (Tuple.mapFirst cPath)
    , altCols = []
    }


cPath : String -> ColumnPath
cPath col =
    col |> String.split "." |> Nel.fromList |> Maybe.withDefault (Nel col [])
