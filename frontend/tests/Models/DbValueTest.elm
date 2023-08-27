module Models.DbValueTest exposing (..)

import Dict
import Models.DbValue as DbValue exposing (DbValue(..))
import Test exposing (Test, describe)
import TestHelpers.Fuzzers as Fuzzers
import TestHelpers.Helpers exposing (fuzzSerde, testSerde)


suite : Test
suite =
    describe "DbValue"
        [ describe "serde"
            [ testSerde "String" DbValue.encode DbValue.decode (DbString "aaa")
            , testSerde "Int" DbValue.encode DbValue.decode (DbInt 1)
            , testSerde "Float" DbValue.encode DbValue.decode (DbFloat 1.2)
            , testSerde "Bool" DbValue.encode DbValue.decode (DbBool True)
            , testSerde "Null" DbValue.encode DbValue.decode DbNull
            , testSerde "Array" DbValue.encode DbValue.decode (DbArray [ DbInt 0, DbString "a", DbNull ])
            , testSerde "Object" DbValue.encode DbValue.decode (DbObject ([ ( "name", DbString "a" ), ( "count", DbInt 3 ), ( "bio", DbNull ) ] |> Dict.fromList))
            , fuzzSerde "DbValue" DbValue.encode DbValue.decode Fuzzers.dbValue
            ]
        ]
