module TestHelpers.Helpers exposing (..)

import Expect
import Json.Decode as Decode
import Json.Encode as Encode
import Test exposing (Test, test)


testSerde : String -> (a -> Encode.Value) -> Decode.Decoder a -> a -> Test
testSerde name encode decode value =
    test name (\_ -> value |> encode |> Encode.encode 0 |> Decode.decodeString decode |> Expect.equal (Ok value))


testEncode : String -> (a -> Encode.Value) -> a -> String -> Test
testEncode name encode value json =
    test name (\_ -> value |> encode |> Encode.encode 0 |> Expect.equal json)
