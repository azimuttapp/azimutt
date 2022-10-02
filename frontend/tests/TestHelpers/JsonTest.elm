module TestHelpers.JsonTest exposing (jsonFuzz, jsonTest)

import Expect
import Fuzz exposing (Fuzzer)
import Json.Decode as Decode
import Json.Encode as Encode
import Test exposing (Test, fuzz, test)


jsonFuzz : String -> Fuzzer a -> (a -> Encode.Value) -> Decode.Decoder a -> Test
jsonFuzz name fuzzer encode decoder =
    fuzz fuzzer ("encode/decode any " ++ name) (\a -> a |> encode |> Encode.encode 0 |> Decode.decodeString decoder |> Expect.equal (Ok a))


jsonTest : String -> a -> String -> (a -> Encode.Value) -> Decode.Decoder a -> Test
jsonTest name value json encode decoder =
    test ("encode/decode " ++ name)
        (\_ ->
            value
                |> Expect.all
                    [ \v -> v |> encode |> Encode.encode 0 |> Expect.equal json
                    , \v -> json |> Decode.decodeString decoder |> Expect.equal (Ok v)
                    ]
        )
