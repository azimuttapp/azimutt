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
                    parseContent "slug" "---\ntitle: The title\ncategory: test\nauthor: loic\npublished: 2021-10-01\n---\n\nMarkdown content\nYeah!!!\n"
                        |> Expect.equal (Ok { title = "The title", excerpt = "Markdown content\nYeah!!!", category = Just "test", tags = [], author = "loic", published = "2021-10-01", body = "Markdown content\nYeah!!!" })
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
