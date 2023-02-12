module Models.Project.TableIdTest exposing (..)

import Expect
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.TableId as TableId exposing (TableId)
import Test exposing (Test, describe, test)


defaultSchema : SchemaName
defaultSchema =
    "public"


tableId1 : TableId
tableId1 =
    ( "other", "users" )


tableId2 : TableId
tableId2 =
    ( "public", "users" )


tableId3 : TableId
tableId3 =
    ( "", "users" )


suite : Test
suite =
    describe "Models.Project.TableId"
        [ describe "asHtmlId"
            [ test "round-trip" (\_ -> tableId2 |> TableId.toHtmlId |> TableId.fromHtmlId |> Expect.equal (Just tableId2))
            , test "serialize" (\_ -> tableId2 |> TableId.toHtmlId |> Expect.equal "table#public#users")
            ]
        , describe "asString"
            [ test "round-trip" (\_ -> tableId2 |> TableId.toString |> TableId.fromString |> Expect.equal (Just tableId2))
            , test "serialize" (\_ -> tableId2 |> TableId.toString |> Expect.equal "public.users")
            ]
        , describe "show"
            [ test "with custom schema" (\_ -> tableId1 |> TableId.show defaultSchema |> Expect.equal "other.users")
            , test "with default schema" (\_ -> tableId2 |> TableId.show defaultSchema |> Expect.equal "users")
            , test "with empty schema" (\_ -> tableId3 |> TableId.show defaultSchema |> Expect.equal "users")
            ]
        , describe "parse"
            [ test "with custom schema" (\_ -> "other.users" |> TableId.parse |> Expect.equal tableId1)
            , test "with default schema" (\_ -> "public.users" |> TableId.parse |> Expect.equal tableId2)
            , test "with empty schema" (\_ -> ".users" |> TableId.parse |> Expect.equal tableId3)
            , test "with no schema" (\_ -> "users" |> TableId.parse |> Expect.equal tableId3)
            ]
        ]
