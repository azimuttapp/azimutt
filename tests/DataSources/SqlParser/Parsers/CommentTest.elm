module DataSources.SqlParser.Parsers.CommentTest exposing (..)

import DataSources.SqlParser.Parsers.Comment exposing (parseColumnComment, parseTableComment)
import DataSources.SqlParser.Utils.HelpersTest exposing (testStatement)
import Test exposing (Test, describe)


suite : Test
suite =
    describe "Comment"
        [ describe "parseTableComment"
            [ testStatement "basic" "COMMENT ON TABLE public.table1 IS 'A comment';" parseTableComment (\_ -> Ok { schema = Just "public", table = "table1", comment = "A comment" })
            , testStatement "with quotes" "COMMENT ON TABLE public.table1 IS 'A ''good'' comment';" parseTableComment (\_ -> Ok { schema = Just "public", table = "table1", comment = "A 'good' comment" })
            , testStatement "with semicolon" "COMMENT ON TABLE public.table1 IS 'A ; comment';" parseTableComment (\_ -> Ok { schema = Just "public", table = "table1", comment = "A ; comment" })
            , testStatement "bad" "bad" parseTableComment (\_ -> Err [ "Can't parse table comment: 'bad'" ])
            ]
        , describe "parseColumnComment"
            [ testStatement "basic" "COMMENT ON COLUMN public.table1.col IS 'A comment';" parseColumnComment (\_ -> Ok { schema = Just "public", table = "table1", column = "col", comment = "A comment" })
            , testStatement "with quotes" "COMMENT ON COLUMN public.table1.col IS 'A ''good'' comment';" parseColumnComment (\_ -> Ok { schema = Just "public", table = "table1", column = "col", comment = "A 'good' comment" })
            , testStatement "with quoted column name" """COMMENT ON COLUMN public.table1."col" IS 'A ''good'' comment';""" parseColumnComment (\_ -> Ok { schema = Just "public", table = "table1", column = "col", comment = "A 'good' comment" })
            , testStatement "with semicolon" "COMMENT ON COLUMN public.table1.col IS 'A ; comment';" parseColumnComment (\_ -> Ok { schema = Just "public", table = "table1", column = "col", comment = "A ; comment" })
            , testStatement "bad" "bad" parseColumnComment (\_ -> Err [ "Can't parse column comment: 'bad'" ])
            ]
        ]
