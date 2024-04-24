module DataSources.DbMiner.QueryMariaDBTest exposing (..)

import DataSources.DbMiner.QueryMariaDB exposing (addLimit, exploreColumn, exploreTable)
import Expect
import Models.Project.ColumnPath as ColumnPath
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "QueryMariaDB"
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
  "column",
  count(*) as count
FROM "schema"."table"
GROUP BY "column"
ORDER BY count DESC, "column";
""")
    , test "with empty schema" (\_ -> exploreColumn ( "", "table" ) (ColumnPath.fromString "column") |> Expect.equal """SELECT
  "column",
  count(*) as count
FROM "table"
GROUP BY "column"
ORDER BY count DESC, "column";
""")

    -- TODO, test "with json column" (\_ -> exploreColumn ( "", "table" ) (ColumnPath.fromString "data:email") |> Expect.equal """SELECT
    --"data"->>'email' as "email",
    --count(*) as count
    --FROM "table"
    --GROUP BY "data"->>'email'
    --ORDER BY count DESC, "email";
    --""")
    ]


addLimitSuite : List Test
addLimitSuite =
    [ test "without limit" (\_ -> addLimit "SELECT * FROM users;" |> Expect.equal "SELECT * FROM users\nLIMIT 100;\n")
    , test "with limit" (\_ -> addLimit "SELECT * FROM users LIMIT 10;" |> Expect.equal "SELECT * FROM users LIMIT 10;")
    , test "with offset" (\_ -> addLimit "SELECT * FROM users OFFSET 10;" |> Expect.equal "SELECT * FROM users\nLIMIT 100 OFFSET 10;\n")
    , test "with limit & offset" (\_ -> addLimit "SELECT * FROM users LIMIT 10 OFFSET 10;" |> Expect.equal "SELECT * FROM users LIMIT 10 OFFSET 10;")
    , test "multiline" (\_ -> addLimit """SELECT e.id, e.name
FROM events e
WHERE e.name='project_loaded';  """ |> Expect.equal """SELECT e.id, e.name
FROM events e
WHERE e.name='project_loaded'
LIMIT 100;
""")
    , test "not on update" (\_ -> addLimit "UPDATE users SET deleted=null WHERE id=10;" |> Expect.equal "UPDATE users SET deleted=null WHERE id=10;")
    , test "lowercase" (\_ -> addLimit "select * from users;" |> Expect.equal "select * from users\nLIMIT 100;\n")
    ]
