module DataSources.SqlParser.Parsers.CreateViewTest exposing (..)

import DataSources.SqlParser.Parsers.CreateView exposing (parseView)
import DataSources.SqlParser.Parsers.Select exposing (SelectColumn(..), SelectTable(..))
import DataSources.SqlParser.TestHelpers.Tests exposing (testStatement)
import Libs.Nel exposing (Nel)
import Test exposing (Test, describe)


suite : Test
suite =
    describe "CreateView"
        [ describe "parseView"
            [ testStatement ( parseView, "basic" )
                """CREATE OR REPLACE VIEW public.autocomplete AS
                    SELECT accounts.id AS account_id,
                           accounts.email
                    FROM public.accounts
                    WHERE accounts.deleted_at IS NULL
                    WITH NO DATA;"""
                { schema = Just "public"
                , table = "autocomplete"
                , select =
                    { columns =
                        Nel (BasicColumn { table = Just "accounts", column = "id", alias = Just "account_id" })
                            [ BasicColumn { table = Just "accounts", column = "email", alias = Nothing } ]
                    , tables = [ BasicTable { schema = Just "public", table = "accounts", alias = Nothing } ]
                    , whereClause = Just "accounts.deleted_at IS NULL"
                    }
                , replace = True
                , materialized = False
                , extra = Just "WITH NO DATA"
                }
            , testStatement ( parseView, "with data" )
                """CREATE MATERIALIZED VIEW public.autocomplete AS
                    WITH more_data AS (SELECT * FROM ref)
                    SELECT accounts.id AS account_id,
                           accounts.email
                    FROM public.accounts
                    WHERE accounts.deleted_at IS NULL
                    WITH NO DATA;"""
                { schema = Just "public"
                , table = "autocomplete"
                , select =
                    { columns =
                        Nel (BasicColumn { table = Just "accounts", column = "id", alias = Just "account_id" })
                            [ BasicColumn { table = Just "accounts", column = "email", alias = Nothing } ]
                    , tables = [ BasicTable { schema = Just "public", table = "accounts", alias = Nothing } ]
                    , whereClause = Just "accounts.deleted_at IS NULL"
                    }
                , replace = False
                , materialized = True
                , extra = Just "WITH NO DATA"
                }
            ]
        ]
