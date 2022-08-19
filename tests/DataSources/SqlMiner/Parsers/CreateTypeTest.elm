module DataSources.SqlMiner.Parsers.CreateTypeTest exposing (..)

import DataSources.SqlMiner.Parsers.CreateType exposing (ParsedTypeValue(..), parseCreateType)
import DataSources.SqlMiner.TestHelpers.Tests exposing (testStatement)
import Test exposing (Test, describe)


suite : Test
suite =
    describe "CreateType"
        [ describe "parseCreateType"
            [ testStatement ( parseCreateType, "enum" )
                "CREATE TYPE public.result AS ENUM ('pending', 'success', 'failure');"
                { schema = Just "public", name = "result", value = EnumType [ "pending", "success", "failure" ] }
            , testStatement ( parseCreateType, "range" )
                "CREATE TYPE float8_range AS RANGE (subtype = float8, subtype_diff = float8mi);"
                { schema = Nothing, name = "float8_range", value = UnknownType "RANGE (subtype = float8, subtype_diff = float8mi)" }
            , testStatement ( parseCreateType, "basic" )
                "CREATE TYPE foo AS (f1 int, f2 text);"
                { schema = Nothing, name = "foo", value = UnknownType "(f1 int, f2 text)" }
            , testStatement ( parseCreateType, "without AS" )
                "CREATE TYPE box (INTERNALLENGTH = 16, INPUT = my_box_in_function, OUTPUT = my_box_out_function);"
                { schema = Nothing, name = "box", value = UnknownType "(INTERNALLENGTH = 16, INPUT = my_box_in_function, OUTPUT = my_box_out_function)" }
            ]
        ]
