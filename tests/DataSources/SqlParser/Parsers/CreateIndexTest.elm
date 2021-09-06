module DataSources.SqlParser.Parsers.CreateIndexTest exposing (..)

import DataSources.SqlParser.Parsers.CreateIndex exposing (parseCreateIndex)
import DataSources.SqlParser.Utils.HelpersTest exposing (testStatement)
import Libs.Nel exposing (Nel)
import Test exposing (Test, describe)


suite : Test
suite =
    describe "CreateIndex"
        [ describe "parseCreateIndex"
            [ testStatement "basic" "CREATE INDEX unique_email on p.users(email);" parseCreateIndex (\_ -> Ok { name = "unique_email", table = { schema = Just "p", table = "users" }, columns = Nel "email" [], definition = "(email)" })
            , testStatement "lowercase, no schema, multiple columns, many spaces" "create index  unique_kind  on  users  (kind_type, kind_id);" parseCreateIndex (\_ -> Ok { name = "unique_kind", table = { schema = Nothing, table = "users" }, columns = Nel "kind_type" [ "kind_id" ], definition = "(kind_type, kind_id)" })
            , testStatement "complex" "CREATE INDEX phone_idx ON public.accounts USING btree (phone_number) WHERE (phone_number IS NOT NULL);" parseCreateIndex (\_ -> Ok { name = "phone_idx", table = { schema = Just "public", table = "accounts" }, columns = Nel "phone_number" [], definition = "USING btree (phone_number) WHERE (phone_number IS NOT NULL)" })
            ]
        ]
