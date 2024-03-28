module DataSources.DbMiner.QueryBigQueryTest exposing (..)

import DataSources.DbMiner.QueryBigQuery exposing (addLimit, exploreColumn, exploreTable)
import Expect
import Models.Project.ColumnPath as ColumnPath
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "QueryBigQuery"
        [ describe "exploreTable" exploreTableSuite
        , describe "exploreColumn" exploreColumnSuite
        , describe "addLimit" addLimitSuite
        ]


exploreTableSuite : List Test
exploreTableSuite =
    [ test "with schema" (\_ -> exploreTable ( "schema", "table" ) |> Expect.equal """SELECT *
FROM `schema`.`table`;
""")
    , test "with empty schema" (\_ -> exploreTable ( "", "table" ) |> Expect.equal """SELECT *
FROM `table`;
""")
    ]


exploreColumnSuite : List Test
exploreColumnSuite =
    [ test "with schema" (\_ -> exploreColumn ( "schema", "table" ) (ColumnPath.fromString "column") |> Expect.equal """SELECT
  `column`,
  count(*) AS count
FROM `schema`.`table`
GROUP BY `column`
ORDER BY count DESC, `column`;
""")
    , test "with empty schema" (\_ -> exploreColumn ( "", "table" ) (ColumnPath.fromString "column") |> Expect.equal """SELECT
  `column`,
  count(*) AS count
FROM `table`
GROUP BY `column`
ORDER BY count DESC, `column`;
""")
    , test "with json column" (\_ -> exploreColumn ( "", "table" ) (ColumnPath.fromString "data:email") |> Expect.equal """SELECT
  `data`,
  count(*) AS count
FROM `table`
GROUP BY `data`
ORDER BY count DESC, `data`;
""")
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
    ]
