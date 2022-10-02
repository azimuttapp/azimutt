module DataSources.SqlMiner.Parsers.CreateIndexTest exposing (..)

import DataSources.SqlMiner.Parsers.CreateIndex exposing (parseCreateIndex)
import DataSources.SqlMiner.TestHelpers.Tests exposing (testStatement)
import Libs.Nel exposing (Nel)
import Test exposing (Test, describe)


suite : Test
suite =
    describe "CreateIndex"
        [ describe "parseCreateIndex"
            [ testStatement ( parseCreateIndex, "basic" )
                "CREATE INDEX unique_email on p.users(email);"
                { name = "unique_email", table = { schema = Just "p", table = "users" }, columns = Nel "email" [], definition = "(email)" }
            , testStatement ( parseCreateIndex, "basic with quotes" )
                "CREATE INDEX \"unique_email\" on \"users\" (\"email\");"
                { name = "unique_email", table = { schema = Nothing, table = "users" }, columns = Nel "email" [], definition = "(\"email\")" }
            , testStatement ( parseCreateIndex, "lowercase, no schema, multiple columns, many spaces" )
                "create index  unique_kind  on  users  (kind_type, kind_id);"
                { name = "unique_kind", table = { schema = Nothing, table = "users" }, columns = Nel "kind_type" [ "kind_id" ], definition = "(kind_type, kind_id)" }
            , testStatement ( parseCreateIndex, "complex" )
                "CREATE INDEX phone_idx ON public.accounts USING btree (phone_number) WHERE (phone_number IS NOT NULL);"
                { name = "phone_idx", table = { schema = Just "public", table = "accounts" }, columns = Nel "phone_number" [], definition = "USING btree (phone_number) WHERE (phone_number IS NOT NULL)" }
            ]
        ]
