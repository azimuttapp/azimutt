module DataSources.DbMiner.QueryMongoDBTest exposing (..)

import DataSources.DbMiner.QueryMongoDB exposing (exploreColumn, exploreTable)
import Expect
import Models.Project.ColumnPath as ColumnPath
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "QueryMongoDB"
        [ describe "exploreTable" exploreTableSuite
        , describe "exploreColumn" exploreColumnSuite
        ]


exploreTableSuite : List Test
exploreTableSuite =
    [ test "with database"
        (\_ ->
            exploreTable ( "database", "collection" )
                |> Expect.equal "database/collection/find/{}/100"
        )
    , test "with mixed collection"
        (\_ ->
            exploreTable ( "database", "collection__type__value" )
                |> Expect.equal "database/collection/find/{\"type\":\"value\"}/100"
        )
    ]


exploreColumnSuite : List Test
exploreColumnSuite =
    [ test "with database"
        (\_ ->
            exploreColumn ( "database", "collection" ) (ColumnPath.fromString "column")
                |> Expect.equal "database/collection/aggregate/[{\"$sortByCount\":\"$column\"},{\"$project\":{\"_id\":0,\"column\":\"$_id\",\"count\":\"$count\"}}]/100"
        )
    , test "with mixed collection"
        (\_ ->
            exploreColumn ( "database", "collection__type__value" ) (ColumnPath.fromString "column")
                |> Expect.equal "database/collection/aggregate/[{\"$match\":{\"type\":{\"$eq\":\"value\"}}},{\"$sortByCount\":\"$column\"},{\"$project\":{\"_id\":0,\"column\":\"$_id\",\"count\":\"$count\"}}]/100"
        )
    ]
