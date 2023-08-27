module DataSources.DbMiner.QuerySQLServerTest exposing (..)

import DataSources.DbMiner.QuerySQLServer exposing (exploreColumn, exploreTable)
import Expect
import Models.Project.ColumnPath as ColumnPath
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "QuerySQLServer"
        [ describe "exploreTable" exploreTableSuite
        , describe "exploreColumn" exploreColumnSuite
        ]


exploreTableSuite : List Test
exploreTableSuite =
    [ test "with schema" (\_ -> exploreTable ( "schema", "table" ) |> Expect.equal """SELECT TOP 100 *
FROM "schema"."table";
""")
    , test "with empty schema" (\_ -> exploreTable ( "", "table" ) |> Expect.equal """SELECT TOP 100 *
FROM "table";
""")
    ]


exploreColumnSuite : List Test
exploreColumnSuite =
    [ test "with schema" (\_ -> exploreColumn ( "schema", "table" ) (ColumnPath.fromString "column") |> Expect.equal """SELECT TOP 100
  "column",
  count(*) as count
FROM "schema"."table"
GROUP BY "column"
ORDER BY count DESC, "column";
""")
    , test "with empty schema" (\_ -> exploreColumn ( "", "table" ) (ColumnPath.fromString "column") |> Expect.equal """SELECT TOP 100
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
