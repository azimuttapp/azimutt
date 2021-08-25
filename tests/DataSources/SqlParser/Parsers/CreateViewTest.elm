module DataSources.SqlParser.Parsers.CreateViewTest exposing (..)

import DataSources.SqlParser.Parsers.CreateView exposing (parseView)
import DataSources.SqlParser.Parsers.Select exposing (SelectColumn(..), SelectInfo, SelectTable(..))
import DataSources.SqlParser.Utils.HelpersTest exposing (stmCheck)
import Libs.Nel exposing (Nel)
import Test exposing (Test, describe)


view : String
view =
    """
CREATE MATERIALIZED VIEW public.autocomplete AS
SELECT accounts.id AS account_id,
       accounts.email
FROM public.accounts
WHERE accounts.deleted_at IS NULL
WITH NO DATA;
""" |> String.trim |> String.replace "\n" " "


select : SelectInfo
select =
    { columns =
        Nel (BasicColumn { table = Just "accounts", column = "id", alias = Just "account_id" })
            [ BasicColumn { table = Just "accounts", column = "email", alias = Nothing } ]
    , tables = [ BasicTable { schema = Just "public", table = "accounts", alias = Nothing } ]
    , whereClause = Just "accounts.deleted_at IS NULL"
    }


suite : Test
suite =
    describe "CreateView"
        [ describe "parseView"
            [ stmCheck "basic" view parseView (\s -> Ok { schema = Just "public", table = "autocomplete", select = select, materialized = True, extra = Just "WITH NO DATA", source = s })
            ]
        ]
