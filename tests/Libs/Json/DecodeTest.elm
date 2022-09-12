module Libs.Json.DecodeTest exposing (..)

import Expect
import Json.Decode as Decode
import Libs.Json.Decode as Decode
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Decode"
        [ describe "maybeField"
            [ test "with value" (\_ -> "{\"key\":\"value\"}" |> Decode.decodeString (Decode.maybeField "key" Decode.string) |> Expect.equal (Ok (Just "value")))
            , test "without value" (\_ -> "{}" |> Decode.decodeString (Decode.maybeField "key" Decode.string) |> Expect.equal (Ok Nothing))
            , test "with null" (\_ -> "{\"key\":null}" |> Decode.decodeString (Decode.maybeField "key" Decode.string) |> Expect.equal (Ok Nothing))
            ]
        ]
