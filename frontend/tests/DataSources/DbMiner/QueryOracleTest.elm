module DataSources.DbMiner.QueryOracleTest exposing (..)

import DataSources.DbMiner.QueryOracle exposing (addLimit, exploreColumn, exploreTable)
import Expect
import Models.Project.ColumnPath as ColumnPath
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "QueryOracle"
        [ describe "exploreTable" exploreTableSuite
        , describe "exploreColumn" exploreColumnSuite
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
