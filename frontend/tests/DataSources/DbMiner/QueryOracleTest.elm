module DataSources.DbMiner.QueryOracleTest exposing (..)

import DataSources.DbMiner.QueryOracle exposing (exploreTable)
import Expect
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "QueryOracle" [ describe "exploreTable" exploreTableSuite ]


exploreTableSuite : List Test
exploreTableSuite =
    [ test "with schema" (\_ -> exploreTable ( "schema", "table" ) |> Expect.equal """SELECT *
FROM "schema"."table";
""")
    , test "with empty schema" (\_ -> exploreTable ( "", "table" ) |> Expect.equal """SELECT *
FROM "table";
""")
    ]
