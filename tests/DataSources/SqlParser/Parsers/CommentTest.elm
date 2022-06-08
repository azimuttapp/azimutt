module DataSources.SqlParser.Parsers.CommentTest exposing (..)

import DataSources.SqlParser.Parsers.Comment exposing (parseColumnComment, parseTableComment)
import DataSources.SqlParser.TestHelpers.Tests exposing (testParse)
import Test exposing (Test, describe)


suite : Test
suite =
    describe "Comment"
        [ describe "parseTableComment"
            [ testParse ( parseTableComment, "basic" )
                "COMMENT ON TABLE public.table1 IS 'A comment';"
                { schema = Just "public", table = "table1", comment = "A comment" }
            , testParse ( parseTableComment, "view" )
                "COMMENT ON VIEW public.table1 IS 'A comment';"
                { schema = Just "public", table = "table1", comment = "A comment" }
            , testParse ( parseTableComment, "with quotes" )
                "COMMENT ON TABLE public.table1 IS 'A ''good'' comment';"
                { schema = Just "public", table = "table1", comment = "A 'good' comment" }
            , testParse ( parseTableComment, "with semicolon" )
                "COMMENT ON TABLE public.table1 IS 'A ; comment';"
                { schema = Just "public", table = "table1", comment = "A ; comment" }
            ]
        , describe "parseColumnComment"
            [ testParse ( parseColumnComment, "basic" )
                "COMMENT ON COLUMN public.table1.col IS 'A comment';"
                { schema = Just "public", table = "table1", column = "col", comment = "A comment" }
            , testParse ( parseColumnComment, "with quotes" )
                "COMMENT ON COLUMN public.table1.col IS 'A ''good'' comment';"
                { schema = Just "public", table = "table1", column = "col", comment = "A 'good' comment" }
            , testParse ( parseColumnComment, "with quoted column name" )
                """COMMENT ON COLUMN public.table1."col" IS 'A ''good'' comment';"""
                { schema = Just "public", table = "table1", column = "col", comment = "A 'good' comment" }
            , testParse ( parseColumnComment, "with semicolon" )
                "COMMENT ON COLUMN public.table1.col IS 'A ; comment';"
                { schema = Just "public", table = "table1", column = "col", comment = "A ; comment" }
            ]
        ]
