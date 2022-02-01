module PagesComponents.Blog.Slug.View exposing (viewArticle)

import Components.Atoms.Markdown exposing (markdown)
import Components.Slices.Content as Content
import Css.Global as Global
import Html.Styled exposing (Html, div, fromUnstyled, li, text, ul)
import Html.Styled.Attributes exposing (style)
import Libs.Http as H
import Libs.Nel as Nel
import PagesComponents.Blog.Slug.Models exposing (Model(..))
import PagesComponents.Helpers as Helpers
import Tailwind.Utilities as Tw


viewArticle : Model -> List (Html msg)
viewArticle model =
    [ Global.global Tw.globalStyles
    , Helpers.publicHeader |> fromUnstyled
    , case model of
        Loading ->
            Content.centered
                { section = "Loading"
                , title = "Loading"
                , introduction = Nothing
                , content = [ div [ style "margin-top" "20rem", style "margin-bottom" "20rem", style "text-align" "center" ] [ text "Loading" ] ]
                , dots = False
                }

        BadSlug err ->
            Content.centered
                { section = "Error"
                , title = "Bad url"
                , introduction = Nothing
                , content = [ text (H.errorToString err) ]
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
                , content = [ markdown [ "blog-article" ] content.body ]
                , dots = True
                }
    , Helpers.newsletterSection |> fromUnstyled
    , Helpers.publicFooter |> fromUnstyled
    ]
