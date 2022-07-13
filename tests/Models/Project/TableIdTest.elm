module Models.Project.TableIdTest exposing (..)

import Expect
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.TableId as TableId exposing (TableId)
import Test exposing (Test, describe, test)


defaultSchema : SchemaName
defaultSchema =
    "public"


tableId : TableId
tableId =
    ( "public", "users" )


tableId2 : TableId
tableId2 =
    ( "other", "users" )


suite : Test
suite =
    describe "Models.Project.TableId"
        [ describe "asHtmlId"
            [ test "round-trip" (\_ -> tableId |> TableId.toHtmlId |> TableId.fromHtmlId |> Expect.equal (Just tableId))
            , test "serialize" (\_ -> tableId |> TableId.toHtmlId |> Expect.equal "table-public-users")
            ]
        , describe "asString"
            [ test "round-trip" (\_ -> tableId |> TableId.toString |> TableId.fromString |> Expect.equal (Just tableId))
            , test "serialize" (\_ -> tableId |> TableId.toString |> Expect.equal "public.users")
            ]
        , describe "show"
            [ test "round-trip" (\_ -> tableId2 |> TableId.show defaultSchema |> TableId.parse defaultSchema |> Expect.equal tableId2)
            , test "round-trip with default schema" (\_ -> tableId |> TableId.show defaultSchema |> TableId.parse defaultSchema |> Expect.equal tableId)
            , test "serialize" (\_ -> tableId2 |> TableId.show defaultSchema |> Expect.equal "other.users")
            , test "serialize with default schema" (\_ -> tableId |> TableId.show defaultSchema |> Expect.equal "users")
            ]
        ]
