module Components.Organisms.Header exposing (headerChapter, headerSlice)

import Components.Atoms.Icon as Icon
import Conf exposing (constants)
import Css
import ElmBook.Chapter exposing (chapter, renderComponentList)
import ElmBook.ElmCSS exposing (Chapter)
import Gen.Route as Route
import Html.Styled exposing (Attribute, Html, a, div, header, img, nav, span, text)
import Html.Styled.Attributes exposing (alt, css, href, rel, src, target)
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw


headerSlice : String -> Html msg
headerSlice url =
    header []
        [ div [ css [ Tw.relative, Tw.bg_white ] ]
            [ div [ css [ Tw.flex, Tw.justify_between, Tw.items_center, Tw.max_w_7xl, Tw.mx_auto, Tw.px_4, Tw.py_6, Bp.lg [ Tw.px_8 ], Bp.md [ Tw.justify_start, Tw.space_x_10 ], Bp.sm [ Tw.px_6 ] ] ]
                [ div [ css [ Tw.flex, Tw.justify_start, Bp.lg [ Tw.w_0, Tw.flex_1 ] ] ]
                    [ a [ href (Route.toHref Route.Home_) ]
                        [ span [ css [ Tw.sr_only ] ]
                            [ text "Azimutt" ]
                        , img [ src url, alt "Azimutt", css [ Tw.h_8, Tw.w_auto, Bp.sm [ Tw.h_10 ] ] ] []
                        ]
                    ]
                , nav [ css [ Tw.hidden, Tw.space_x_10, Bp.md [ Tw.flex ] ] ]
                    [ menuLink [ text "Discussions" ] [ href (constants.azimuttGithub ++ "/discussions"), target "_blank", rel "noopener" ]
                    , menuLink [ text "Roadmap" ] [ href (constants.azimuttGithub ++ "/projects/1"), target "_blank", rel "noopener" ]
                    , menuLink [ text "Source code" ] [ href constants.azimuttGithub, target "_blank", rel "noopener" ]
                    , menuLink [ text "Bug reports" ] [ href (constants.azimuttGithub ++ "/issues"), target "_blank", rel "noopener" ]
                    , menuLink [ span [ css [ Tw.sr_only ] ] [ text "Twitter" ], Icon.twitter ] [ href constants.azimuttTwitter, target "_blank", rel "noopener" ]
                    ]
                ]
            ]
        ]


menuLink : List (Html msg) -> List (Attribute msg) -> Html msg
menuLink content attrs =
    a (attrs ++ [ css [ Tw.text_base, Tw.font_medium, Tw.text_gray_500, Css.hover [ Tw.text_gray_900 ] ] ]) content


headerChapter : Chapter x
headerChapter =
    chapter "Header"
        |> renderComponentList
            [ ( "default", headerSlice "/logo.png" )
            ]
