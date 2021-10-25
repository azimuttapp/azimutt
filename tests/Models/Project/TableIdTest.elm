module Models.Project.TableIdTest exposing (..)

import Expect
import Models.Project.TableId as TableId exposing (TableId)
import Test exposing (Test, describe, test)


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
            [ test "round-trip" (\_ -> tableId |> TableId.asHtmlId |> TableId.parseHtmlId |> Expect.equal tableId)
            , test "serialize" (\_ -> tableId |> TableId.asHtmlId |> Expect.equal "table-public-users")
            ]
        , describe "asString"
            [ test "round-trip" (\_ -> tableId |> TableId.asString |> TableId.parseString |> Expect.equal tableId)
            , test "serialize" (\_ -> tableId |> TableId.asString |> Expect.equal "public.users")
            ]
        , describe "show"
            [ test "round-trip" (\_ -> tableId2 |> TableId.show |> TableId.parse |> Expect.equal tableId2)
            , test "round-trip with default schema" (\_ -> tableId |> TableId.show |> TableId.parse |> Expect.equal tableId)
            , test "serialize" (\_ -> tableId2 |> TableId.show |> Expect.equal "other.users")
            , test "serialize with default schema" (\_ -> tableId |> TableId.show |> Expect.equal "users")
            ]
        ]
