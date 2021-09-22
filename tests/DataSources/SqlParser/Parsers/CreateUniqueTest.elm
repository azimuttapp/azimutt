module DataSources.SqlParser.Parsers.CreateUniqueTest exposing (..)

import DataSources.SqlParser.Parsers.CreateUnique exposing (parseCreateUniqueIndex)
import DataSources.SqlParser.TestHelpers.Tests exposing (testParse)
import Libs.Nel exposing (Nel)
import Test exposing (Test, describe)


suite : Test
suite =
    describe "CreateUnique"
        [ describe "parseCreateUniqueIndex"
            [ testParse ( parseCreateUniqueIndex, "basic" )
                "CREATE UNIQUE INDEX unique_email on p.users(email);"
                { name = "unique_email", table = { schema = Just "p", table = "users" }, columns = Nel "email" [], definition = "(email)" }
            , testParse ( parseCreateUniqueIndex, "lowercase, no schema, multiple columns, many spaces" )
                "create unique index  unique_kind  on  users  (kind_type, kind_id);"
                { name = "unique_kind", table = { schema = Nothing, table = "users" }, columns = Nel "kind_type" [ "kind_id" ], definition = "(kind_type, kind_id)" }
            , testParse ( parseCreateUniqueIndex, "complex" )
                "CREATE UNIQUE INDEX kpi_index ON public.statistics USING btree (kpi_id, source_type, source_id);"
                { name = "kpi_index", table = { schema = Just "public", table = "statistics" }, columns = Nel "kpi_id" [ "source_type", "source_id" ], definition = "USING btree (kpi_id, source_type, source_id)" }
            ]
        ]
