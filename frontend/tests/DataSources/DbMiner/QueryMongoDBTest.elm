module DataSources.DbMiner.QueryMongoDBTest exposing (..)

import DataSources.DbMiner.QueryMongoDB exposing (addLimit, exploreColumn, exploreTable, findRow)
import Expect
import Libs.Nel as Nel exposing (Nel)
import Models.DbValue exposing (DbValue(..))
import Models.Project.ColumnPath as ColumnPath
import Models.Project.TableId exposing (TableId)
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "QueryMongoDB"
        [ describe "exploreTable" exploreTableSuite
        , describe "exploreColumn" exploreColumnSuite
        , describe "findRow" findRowSuite
        , describe "addLimit" addLimitSuite
        ]


exploreTableSuite : List Test
exploreTableSuite =
    [ test "with database"
        (\_ ->
            exploreTable ( "admin", "users" )
                |> Expect.equal "db('admin').users.find();\n"
        )
    , test "without database"
        (\_ ->
            exploreTable ( "", "users" )
                |> Expect.equal "db.users.find();\n"
        )
    , test "with mixed collection"
        (\_ ->
            exploreTable ( "", "items__kind__comments" )
                |> Expect.equal "db.items.find({\"kind\": \"comments\"});\n"
        )
    ]


exploreColumnSuite : List Test
exploreColumnSuite =
    [ test "with database"
        (\_ ->
            exploreColumn ( "admin", "users" ) (ColumnPath.fromString "role")
                |> Expect.equal "db('admin').users.aggregate([\n  {\"$sortByCount\": \"$role\"},\n  {\"$project\": {\"_id\": 0, \"role\": \"$_id\", \"count\": \"$count\"}}\n]);\n"
        )
    , test "without database"
        (\_ ->
            exploreColumn ( "", "users" ) (ColumnPath.fromString "role")
                |> Expect.equal "db.users.aggregate([\n  {\"$sortByCount\": \"$role\"},\n  {\"$project\": {\"_id\": 0, \"role\": \"$_id\", \"count\": \"$count\"}}\n]);\n"
        )
    , test "with mixed collection"
        (\_ ->
            exploreColumn ( "", "items__kind__comments" ) (ColumnPath.fromString "role")
                |> Expect.equal "db.items.aggregate([\n  {\"$match\": {\"kind\": {\"$eq\": \"comments\"}}},\n  {\"$sortByCount\": \"$role\"},\n  {\"$project\": {\"_id\": 0, \"role\": \"$_id\", \"count\": \"$count\"}}\n]);\n"
        )
    ]


findRowSuite : List Test
findRowSuite =
    [ test "with db" (\_ -> fRow ( "public", "users" ) [ ( "id", DbInt 3 ) ] |> Expect.equal """db('public').users.find({"id": 3}).limit(1);""")
    , test "without db" (\_ -> fRow ( "", "users" ) [ ( "id", DbInt 3 ) ] |> Expect.equal """db.users.find({"id": 3}).limit(1);""")
    , test "with _id" (\_ -> fRow ( "", "users" ) [ ( "_id", DbString "66ae842903c5dc4e5bd14a00" ) ] |> Expect.equal """db.users.find(ObjectId("66ae842903c5dc4e5bd14a00")).limit(1);""")
    , test "without several cols" (\_ -> fRow ( "", "users" ) [ ( "id", DbInt 3 ), ( "kind", DbString "admin" ) ] |> Expect.equal """db.users.find({"id": 3, "kind": "admin"}).limit(1);""")
    , test "without mixed collection" (\_ -> fRow ( "", "users__kind__admin" ) [ ( "id", DbInt 3 ) ] |> Expect.equal """db.users.find({"kind": "admin", "id": 3}).limit(1);""")
    ]


addLimitSuite : List Test
addLimitSuite =
    [ test "without limit" (\_ -> addLimit "db.users.find();" |> Expect.equal "db.users.find().limit(100);\n")
    , test "with limit" (\_ -> addLimit "db.users.find().limit(10);" |> Expect.equal "db.users.find().limit(10);")
    , test "multiline" (\_ -> addLimit """db.users.find({
  "id": {"$id": 1}
});  """ |> Expect.equal """db.users.find({
  "id": {"$id": 1}
}).limit(100);
""")
    ]


fRow : TableId -> List ( String, DbValue ) -> String
fRow table matches =
    matches |> Nel.fromList |> Maybe.map (\primaryKey -> findRow table (primaryKey |> Nel.map (\( col, value ) -> { column = Nel col [], value = value }))) |> Maybe.withDefault ""
