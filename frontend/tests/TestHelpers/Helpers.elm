module TestHelpers.Helpers exposing (..)

import Expect
import Fuzz exposing (Fuzzer)
import Json.Decode as Decode
import Json.Encode as Encode
import Test exposing (Test, fuzz, test)


testEncode : String -> (a -> Encode.Value) -> a -> String -> Test
testEncode name encode value json =
    test name (\_ -> value |> encode |> Encode.encode 0 |> Expect.equal json)


testDecode : String -> Decode.Decoder a -> String -> a -> Test
testDecode name decode json value =
    test name (\_ -> json |> Decode.decodeString decode |> Expect.equal (Ok value))


testSerde : String -> (a -> Encode.Value) -> Decode.Decoder a -> a -> Test
testSerde name encode decode value =
    test name (\_ -> value |> encode |> Encode.encode 0 |> Decode.decodeString decode |> Expect.equal (Ok value))


testSerdeJson : String -> (a -> Encode.Value) -> Decode.Decoder a -> a -> String -> Test
testSerdeJson name encode decoder value json =
    test ("encode/decode " ++ name)
        (\_ ->
            value
                |> Expect.all
                    [ \v -> v |> encode |> Encode.encode 0 |> Expect.equal json
                    , \v -> json |> Decode.decodeString decoder |> Expect.equal (Ok v)
                    ]
        )


fuzzSerde : String -> (a -> Encode.Value) -> Decode.Decoder a -> Fuzzer a -> Test
fuzzSerde name encode decoder fuzzer =
    fuzz fuzzer ("encode/decode any " ++ name) (\a -> a |> encode |> Encode.encode 0 |> Decode.decodeString decoder |> Expect.equal (Ok a))
