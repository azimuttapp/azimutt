module DataSources.SqlParser.Parsers.CommentTest exposing (..)

import DataSources.SqlParser.Parsers.Comment exposing (parseColumnComment, parseTableComment)
import DataSources.SqlParser.Utils.HelpersTest exposing (stmCheck)
import Test exposing (Test, describe)


suite : Test
suite =
    describe "Comment"
        [ describe "parseTableComment"
            [ stmCheck "basic" "COMMENT ON TABLE public.table1 IS 'A comment';" parseTableComment (\_ -> Ok { schema = Just "public", table = "table1", comment = "A comment" })
            , stmCheck "with quotes" "COMMENT ON TABLE public.table1 IS 'A ''good'' comment';" parseTableComment (\_ -> Ok { schema = Just "public", table = "table1", comment = "A 'good' comment" })
            , stmCheck "with semicolon" "COMMENT ON TABLE public.table1 IS 'A ; comment';" parseTableComment (\_ -> Ok { schema = Just "public", table = "table1", comment = "A ; comment" })
            , stmCheck "bad" "bad" parseTableComment (\_ -> Err [ "Can't parse table comment: 'bad'" ])
            ]
        , describe "parseColumnComment"
            [ stmCheck "basic" "COMMENT ON COLUMN public.table1.col IS 'A comment';" parseColumnComment (\_ -> Ok { schema = Just "public", table = "table1", column = "col", comment = "A comment" })
            , stmCheck "with quotes" "COMMENT ON COLUMN public.table1.col IS 'A ''good'' comment';" parseColumnComment (\_ -> Ok { schema = Just "public", table = "table1", column = "col", comment = "A 'good' comment" })
            , stmCheck "with semicolon" "COMMENT ON COLUMN public.table1.col IS 'A ; comment';" parseColumnComment (\_ -> Ok { schema = Just "public", table = "table1", column = "col", comment = "A ; comment" })
            , stmCheck "bad" "bad" parseColumnComment (\_ -> Err [ "Can't parse column comment: 'bad'" ])
            ]
        ]
