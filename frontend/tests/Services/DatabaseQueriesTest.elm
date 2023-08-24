module Services.DatabaseQueriesTest exposing (..)

import Expect
import Libs.Models.DatabaseUrl exposing (DatabaseUrl)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath)
import Services.DatabaseQueries exposing (showColumnData, showTableData)
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "DatabaseQueries"
        [ describe "couchbase"
            [ describe "showTableData"
                [ test "with bucket and scope"
                    (\_ ->
                        showTableData ( "bucket__scope", "collection" ) couchbaseUrl
                            |> Expect.equal "SELECT collection.* FROM bucket.scope.collection LIMIT 100;"
                    )
                , test "with escaped values"
                    (\_ ->
                        showTableData ( "bucket-2__scope 2", "collection-2" ) couchbaseUrl
                            |> Expect.equal "SELECT `collection-2`.* FROM `bucket-2`.`scope 2`.`collection-2` LIMIT 100;"
                    )
                , test "with mixed collection"
                    (\_ ->
                        showTableData ( "bucket__scope", "collection__type__value" ) couchbaseUrl
                            |> Expect.equal "SELECT collection.* FROM bucket.scope.collection WHERE type='value' LIMIT 100;"
                    )
                ]
            , describe "showColumnData"
                [ test "with bucket and scope"
                    (\_ ->
                        showColumnData (ColumnPath.fromString "column") ( "bucket__scope", "collection" ) couchbaseUrl
                            |> Expect.equal "SELECT collection.column, COUNT(*) as count FROM bucket.scope.collection GROUP BY column ORDER BY count DESC LIMIT 100;"
                    )
                , test "with escaped values"
                    (\_ ->
                        showColumnData (ColumnPath.fromString "column") ( "bucket-2__scope 2", "collection-2" ) couchbaseUrl
                            |> Expect.equal "SELECT `collection-2`.column, COUNT(*) as count FROM `bucket-2`.`scope 2`.`collection-2` GROUP BY column ORDER BY count DESC LIMIT 100;"
                    )
                , test "with mixed collection"
                    (\_ ->
                        showColumnData (ColumnPath.fromString "column") ( "bucket__scope", "collection__type__value" ) couchbaseUrl
                            |> Expect.equal "SELECT collection.column, COUNT(*) as count FROM bucket.scope.collection WHERE type='value' GROUP BY column ORDER BY count DESC LIMIT 100;"
                    )
                ]
            ]
        , describe "mongo"
            [ describe "showTableData"
                [ test "with database"
                    (\_ ->
                        showTableData ( "database", "collection" ) mongoUrl
                            |> Expect.equal "database/collection/find/{}/100"
                    )
                , test "with mixed collection"
                    (\_ ->
                        showTableData ( "database", "collection__type__value" ) mongoUrl
                            |> Expect.equal "database/collection/find/{\"type\":\"value\"}/100"
                    )
                ]
            , describe "showColumnData"
                [ test "with database"
                    (\_ ->
                        showColumnData (ColumnPath.fromString "column") ( "database", "collection" ) mongoUrl
                            |> Expect.equal "database/collection/aggregate/[{\"$sortByCount\":\"$column\"},{\"$project\":{\"_id\":0,\"column\":\"$_id\",\"count\":\"$count\"}}]/100"
                    )
                , test "with mixed collection"
                    (\_ ->
                        showColumnData (ColumnPath.fromString "column") ( "database", "collection__type__value" ) mongoUrl
                            |> Expect.equal "database/collection/aggregate/[{\"$match\":{\"type\":{\"$eq\":\"value\"}}},{\"$sortByCount\":\"$column\"},{\"$project\":{\"_id\":0,\"column\":\"$_id\",\"count\":\"$count\"}}]/100"
                    )
                ]
            ]
        , describe "postgres"
            [ describe "showTableData"
                [ test "with schema"
                    (\_ ->
                        showTableData ( "schema", "table" ) postgresUrl
                            |> Expect.equal """SELECT *
FROM "schema"."table"
LIMIT 100;
"""
                    )
                , test "with empty schema"
                    (\_ ->
                        showTableData ( "", "table" ) postgresUrl
                            |> Expect.equal """SELECT *
FROM "table"
LIMIT 100;
"""
                    )
                ]
            , describe "showColumnData"
                [ test "with schema"
                    (\_ ->
                        showColumnData (ColumnPath.fromString "column") ( "schema", "table" ) postgresUrl
                            |> Expect.equal """SELECT
  "column",
  count(*)
FROM "schema"."table"
GROUP BY "column"
ORDER BY count DESC, "column"
LIMIT 100;
"""
                    )
                , test "with empty schema"
                    (\_ ->
                        showColumnData (ColumnPath.fromString "column") ( "", "table" ) postgresUrl
                            |> Expect.equal """SELECT
  "column",
  count(*)
FROM "table"
GROUP BY "column"
ORDER BY count DESC, "column"
LIMIT 100;
"""
                    )
                , test "with json column"
                    (\_ ->
                        showColumnData (ColumnPath.fromString "data:email") ( "", "table" ) postgresUrl
                            |> Expect.equal """SELECT
  "data"->'email' as "email",
  count(*)
FROM "table"
GROUP BY "data"->'email'
ORDER BY count DESC, "email"
LIMIT 100;
"""
                    )
                ]
            ]
        ]


couchbaseUrl : DatabaseUrl
couchbaseUrl =
    "couchbases://my_user:my_password@cb.bdej1379mrnpd5me.cloud.couchbase.com"


mongoUrl : DatabaseUrl
mongoUrl =
    "mongodb+srv://azimutt-cli:ZRDJChTa9rCp9Hr@cluster0.0z2iwpi.mongodb.net"


postgresUrl : DatabaseUrl
postgresUrl =
    "postgresql://postgres:postgres@localhost:5432/azimutt_dev"
