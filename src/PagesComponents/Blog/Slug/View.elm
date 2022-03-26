module PagesComponents.Blog.Slug.View exposing (viewArticle)

import Components.Atoms.Markdown exposing (markdownUnsafe)
import Components.Slices.Content as Content
import Html exposing (Html, div, li, text, ul)
import Html.Attributes exposing (class, style)
import Html.Lazy as Lazy
import Libs.Http as Http
import Libs.Nel as Nel
import PagesComponents.Blog.Slug.Models exposing (Model(..))
import PagesComponents.Helpers as Helpers


viewArticle : Model -> List (Html msg)
viewArticle model =
    [ Helpers.publicHeader
    , case model of
        Loading ->
            Content.centered
                { section = "Loading"
                , title = "Loading"
                , introduction = Nothing
                , content = [ div [ class "my-64 text-center", style "height" "20000px" ] [ text "Loading" ] ]
                , dots = False
                }

        BadSlug err ->
            Content.centered
                { section = "Error"
                , title = "Bad url"
                , introduction = Nothing
                , content = [ text (Http.errorToString err) ]
                , dots = False
                }

        BadContent errs ->
            Content.centered
                { section = "Error"
                , title = "Bad content :("
                , introduction = Nothing
                , content = [ ul [] (errs |> Nel.toList |> List.map (\err -> li [] [ text err ])) ]
                , dots = False
                }

        Loaded content ->
            Content.centered
                { section = content.category |> Maybe.withDefault "Azimutt"
                , title = content.title
                , introduction = Nothing
                , content = [ Lazy.lazy2 markdownUnsafe "blog-article" content.body ]
                , dots = True
                }
    , Helpers.newsletterSection
    , Helpers.publicFooter
    ]
