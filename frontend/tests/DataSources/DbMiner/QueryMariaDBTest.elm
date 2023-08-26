module DataSources.DbMiner.QueryMariaDBTest exposing (..)

import DataSources.DbMiner.QueryMariaDB exposing (exploreColumn, exploreTable)
import Expect
import Models.Project.ColumnPath as ColumnPath
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "QueryMariaDB"
        [ describe "exploreTable" exploreTableSuite
        , describe "exploreColumn" exploreColumnSuite
        ]


exploreTableSuite : List Test
exploreTableSuite =
    [ test "with schema" (\_ -> exploreTable ( "schema", "table" ) |> Expect.equal """SELECT *
FROM "schema"."table"
LIMIT 100;
""")
    , test "with empty schema" (\_ -> exploreTable ( "", "table" ) |> Expect.equal """SELECT *
FROM "table"
LIMIT 100;
""")
    ]


exploreColumnSuite : List Test
exploreColumnSuite =
    [ test "with schema" (\_ -> exploreColumn ( "schema", "table" ) (ColumnPath.fromString "column") |> Expect.equal """SELECT
  "column",
  count(*) as count
FROM "schema"."table"
GROUP BY "column"
ORDER BY count DESC, "column"
LIMIT 100;
""")
    , test "with empty schema" (\_ -> exploreColumn ( "", "table" ) (ColumnPath.fromString "column") |> Expect.equal """SELECT
  "column",
  count(*) as count
FROM "table"
GROUP BY "column"
ORDER BY count DESC, "column"
LIMIT 100;
""")

    -- TODO, test "with json column" (\_ -> exploreColumn ( "", "table" ) (ColumnPath.fromString "data:email") |> Expect.equal """SELECT
    --"data"->>'email' as "email",
    --count(*) as count
    --FROM "table"
    --GROUP BY "data"->>'email'
    --ORDER BY count DESC, "email";
    --""")
    ]
