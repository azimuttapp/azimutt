module Models.ProjectTest exposing (..)

import Expect
import Models.Project exposing (..)
import Test exposing (Test, describe, test)


tableId : TableId
tableId =
    ( "public", "users" )


tableId2 : TableId
tableId2 =
    ( "other", "users" )


suite : Test
suite =
    describe "Models.Project"
        [ describe "tableIdAsHtmlId"
            [ test "round-trip" (\_ -> tableId |> tableIdAsHtmlId |> htmlIdAsTableId |> Expect.equal tableId)
            , test "serialize" (\_ -> tableId |> tableIdAsHtmlId |> Expect.equal "table-public-users")
            ]
        , describe "tableIdAsString"
            [ test "round-trip" (\_ -> tableId |> tableIdAsString |> stringAsTableId |> Expect.equal tableId)
            , test "serialize" (\_ -> tableId |> tableIdAsString |> Expect.equal "public.users")
            ]
        , describe "showTableId"
            [ test "round-trip" (\_ -> tableId2 |> showTableId |> parseTableId |> Expect.equal tableId2)
            , test "round-trip with default schema" (\_ -> tableId |> showTableId |> parseTableId |> Expect.equal tableId)
            , test "serialize" (\_ -> tableId2 |> showTableId |> Expect.equal "other.users")
            , test "serialize with default schema" (\_ -> tableId |> showTableId |> Expect.equal "users")
            ]
        , describe "showTableName"
            [ test "with default schema" (\_ -> showTableName "public" "users" |> Expect.equal "users")
            , test "with other schema" (\_ -> showTableName "wp" "users" |> Expect.equal "wp.users")
            ]
        ]
