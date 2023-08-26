module DataSources.DbMiner.QueryCouchbaseTest exposing (..)

import DataSources.DbMiner.QueryCouchbase exposing (exploreColumn, exploreTable)
import Expect
import Models.Project.ColumnPath as ColumnPath
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "QueryCouchbase"
        [ describe "exploreTable" exploreTableSuite
        , describe "exploreColumn" exploreColumnSuite
        ]


exploreTableSuite : List Test
exploreTableSuite =
    [ test "with bucket and scope" (\_ -> exploreTable ( "bucket__scope", "collection" ) |> Expect.equal """SELECT collection.*
FROM bucket.scope.collection
LIMIT 100;
""")
    , test "with escaped values" (\_ -> exploreTable ( "bucket-2__scope 2", "collection-2" ) |> Expect.equal """SELECT `collection-2`.*
FROM `bucket-2`.`scope 2`.`collection-2`
LIMIT 100;
""")
    , test "with mixed collection" (\_ -> exploreTable ( "bucket__scope", "collection__type__value" ) |> Expect.equal """SELECT collection.*
FROM bucket.scope.collection
WHERE type='value'
LIMIT 100;
""")
    ]


exploreColumnSuite : List Test
exploreColumnSuite =
    [ test "with bucket and scope" (\_ -> exploreColumn ( "bucket__scope", "collection" ) (ColumnPath.fromString "column") |> Expect.equal """SELECT
  collection.column,
  COUNT(*) as count
FROM bucket.scope.collection
GROUP BY column
ORDER BY count DESC
LIMIT 100;
""")
    , test "with escaped values" (\_ -> exploreColumn ( "bucket-2__scope 2", "collection-2" ) (ColumnPath.fromString "column") |> Expect.equal """SELECT
  `collection-2`.column,
  COUNT(*) as count
FROM `bucket-2`.`scope 2`.`collection-2`
GROUP BY column
ORDER BY count DESC
LIMIT 100;
""")
    , test "with mixed collection" (\_ -> exploreColumn ( "bucket__scope", "collection__type__value" ) (ColumnPath.fromString "column") |> Expect.equal """SELECT
  collection.column,
  COUNT(*) as count
FROM bucket.scope.collection
WHERE type='value'
GROUP BY column
ORDER BY count DESC
LIMIT 100;
""")
    ]
