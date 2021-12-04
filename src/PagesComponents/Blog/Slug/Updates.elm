module PagesComponents.Blog.Slug.Updates exposing (getArticle, parseContent, parseFrontMatter)

import Conf
import Dict exposing (Dict)
import Gen.Route as Route
import Http
import Libs.DateTime as DateTime
import Libs.Dict as D
import Libs.Maybe as M
import Libs.Nel as Nel exposing (Nel)
import Libs.Result as R
import PagesComponents.Blog.Slug.Models exposing (Content, Model(..), authors)


getArticle : (String -> Result Http.Error String -> msg) -> String -> Cmd msg
getArticle buildMsg slug =
    Http.get { url = Route.toHref (Route.Blog__Slug_ { slug = slug }) ++ "/article.md", expect = Http.expectString (buildMsg slug) }


parseContent : String -> String -> Result (Nel String) Content
parseContent slug content =
    -- inspired from https://jekyllrb.com/docs/front-matter
    case content |> String.split "---\n" of
        "" :: frontMatter :: mdStart :: mdRest ->
            frontMatter
                |> parseFrontMatter
                |> Result.andThen
                    (\props ->
                        R.ap3
                            (\title author published ->
                                { title = title
                                , excerpt = (props |> D.getOrElse "excerpt" (mdStart |> String.trim)) |> String.left 280 |> String.trim
                                , category = props |> Dict.get "category"
                                , tags = props |> Dict.get "tags" |> M.mapOrElse (\tags -> tags |> String.split "," |> List.map String.trim) []
                                , author = author
                                , published = published
                                , body = (mdStart :: mdRest) |> String.join "---\n" |> String.trim |> extendMarkdown slug
                                }
                            )
                            (props |> D.get "title")
                            (props |> D.get "author" |> Result.andThen (\author -> authors |> Dict.get author |> Result.fromMaybe ("Can't find '" ++ author ++ "' author")))
                            (props |> D.get "published" |> Result.andThen DateTime.parse)
                    )

        _ :: _ :: _ :: _ ->
            Err (Nel "File do not start by '---'" [])

        "" :: _ :: [] ->
            Err (Nel "Missing a closing '---'" [])

        _ :: _ :: [] ->
            Err (Nel "File do not start by '---'" [])

        _ :: [] ->
            Err (Nel "Missing the front matter section (between --- separators)" [])

        [] ->
            Err (Nel "Not possible, split always yield an element" [])


parseFrontMatter : String -> Result (Nel String) (Dict String String)
parseFrontMatter frontMatter =
    frontMatter
        |> String.trim
        |> String.split "\n"
        |> List.foldr
            (\line ( errs, res ) ->
                case line |> String.split ":" of
                    [] ->
                        ( errs, res )

                    value :: [] ->
                        ( ("No key defined for '" ++ value ++ "'") :: errs, res )

                    key :: value ->
                        if key |> String.contains " " then
                            ( ("Invalid key '" ++ key ++ "'") :: errs, res )

                        else
                            ( errs, ( key |> String.trim, value |> String.join ":" |> String.trim ) :: res )
            )
            ( [], [] )
        |> (\( errs, res ) -> Nel.fromList errs |> M.mapOrElse Err (Ok (Dict.fromList res)))


extendMarkdown : String -> String -> String
extendMarkdown slug md =
    md
        |> String.replace "{{base_link}}" (Route.toHref (Route.Blog__Slug_ { slug = slug }))
        |> String.replace "{{app_link}}" (Route.toHref Route.App)
        |> String.replace "{{roadmap_link}}" (Conf.constants.azimuttGithub ++ "/projects/1")
        |> String.replace "{{feedback_link}}" (Conf.constants.azimuttGithub ++ "/discussions")
