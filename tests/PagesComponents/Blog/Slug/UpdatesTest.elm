module PagesComponents.Blog.Slug.UpdatesTest exposing (..)

import Dict
import Expect
import Libs.Nel exposing (Nel)
import PagesComponents.Blog.Slug.Updates exposing (parseContent, parseFrontMatter)
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "PagesComponents.Blog.Slug.Updates"
        [ describe "parseContent"
            [ test "basic"
                (\_ ->
                    parseContent "slug" "---\ncategory: test\ntitle: The title\nauthor: loic\n---\n\nMarkdown content\nYeah!!!\n"
                        |> Expect.equal (Ok { category = Just "test", title = "The title", author = "loic", body = "Markdown content\nYeah!!!", tags = [], excerpt = "Markdown content\nYeah!!!" })
                )
            ]
        , describe "parseFrontMatter"
            [ test "basic"
                (\_ ->
                    parseFrontMatter "title: Hello les gens\ndesc: C'est ici!"
                        |> Expect.equal (Ok (Dict.fromList [ ( "title", "Hello les gens" ), ( "desc", "C'est ici!" ) ]))
                )
            , test "no space in key"
                (\_ ->
                    parseFrontMatter "title 2: Hello les gens"
                        |> Expect.equal (Err (Nel "Invalid key 'title 2'" []))
                )
            , test "missing key"
                (\_ ->
                    parseFrontMatter "Hello les gens"
                        |> Expect.equal (Err (Nel "No key defined for 'Hello les gens'" []))
                )
            ]
        ]
