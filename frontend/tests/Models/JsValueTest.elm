module Models.JsValueTest exposing (..)

import Dict
import Models.JsValue as JsValue exposing (JsValue)
import Test exposing (Test, describe)
import TestHelpers.Fuzzers as Fuzzers
import TestHelpers.Helpers exposing (fuzzSerde, testSerde)


suite : Test
suite =
    describe "JsValue"
        [ describe "serde"
            [ testSerde "String" JsValue.encode JsValue.decode (JsValue.String "aaa")
            , testSerde "Int" JsValue.encode JsValue.decode (JsValue.Int 1)
            , testSerde "Float" JsValue.encode JsValue.decode (JsValue.Float 1.2)
            , testSerde "Bool" JsValue.encode JsValue.decode (JsValue.Bool True)
            , testSerde "Null" JsValue.encode JsValue.decode JsValue.Null
            , testSerde "Array" JsValue.encode JsValue.decode (JsValue.Array [ JsValue.Int 0, JsValue.String "a", JsValue.Null ])
            , testSerde "Object" JsValue.encode JsValue.decode (JsValue.Object ([ ( "name", JsValue.String "a" ), ( "count", JsValue.Int 3 ), ( "bio", JsValue.Null ) ] |> Dict.fromList))
            , fuzzSerde "JsValue" JsValue.encode JsValue.decode Fuzzers.jsValue
            ]
        ]
