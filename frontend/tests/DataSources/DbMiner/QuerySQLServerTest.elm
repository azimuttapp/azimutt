module DataSources.DbMiner.QuerySQLServerTest exposing (..)

import DataSources.DbMiner.QuerySQLServer exposing (addLimit, exploreColumn, exploreTable)
import Expect
import Models.Project.ColumnPath as ColumnPath
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "QuerySQLServer"
        [ describe "exploreTable" exploreTableSuite
        , describe "exploreColumn" exploreColumnSuite
        , describe "addLimit" addLimitSuite
        ]


exploreTableSuite : List Test
exploreTableSuite =
    [ test "with schema" (\_ -> exploreTable ( "schema", "table" ) |> Expect.equal """SELECT * FROM "schema"."table";
""")
    , test "with empty schema" (\_ -> exploreTable ( "", "table" ) |> Expect.equal """SELECT * FROM "table";
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

    -- TODO, test "with json column" (\_ -> exploreColumn ( "", "table" ) (ColumnPath.fromString "data:email") |> Expect.equal """SELECT TOP 100
    --"data"->>'email' as "email",
    --count(*) as count
    --FROM "table"
    --GROUP BY "data"->>'email'
    --ORDER BY count DESC, "email";
    --""")
    ]


addLimitSuite : List Test
addLimitSuite =
    [ test "without limit" (\_ -> addLimit "SELECT * FROM users;" |> Expect.equal "SELECT TOP 100 * FROM users;\n")
    , test "with limit" (\_ -> addLimit "SELECT TOP 10 * FROM users;" |> Expect.equal "SELECT TOP 10 * FROM users;")
    , test "multiline" (\_ -> addLimit """SELECT e.id, e.name
FROM events e
WHERE e.name='project_loaded';  """ |> Expect.equal """SELECT TOP 100 e.id, e.name
FROM events e
WHERE e.name='project_loaded';
""")
    , test "not on update" (\_ -> addLimit "UPDATE users SET deleted=null WHERE id=10;" |> Expect.equal "UPDATE users SET deleted=null WHERE id=10;")
    ]
