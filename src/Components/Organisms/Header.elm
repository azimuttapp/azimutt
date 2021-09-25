module Components.Organisms.Header exposing (doc, headerSlice)

import Components.Atoms.Icon as Icon
import Conf exposing (constants)
import Css exposing (hover)
import ElmBook.Chapter exposing (chapter, renderComponentList)
import ElmBook.ElmCSS exposing (Chapter)
import Gen.Route as Route exposing (Route)
import Html.Styled exposing (Html, a, div, header, img, nav, span, text)
import Html.Styled.Attributes exposing (alt, css, href, src)
import Libs.Html.Styled exposing (extLink)
import Tailwind.Breakpoints exposing (lg, md, sm)
import Tailwind.Utilities exposing (bg_white, flex, flex_1, font_medium, h_10, h_8, hidden, items_center, justify_between, justify_start, max_w_7xl, mx_auto, px_4, px_6, px_8, py_6, relative, space_x_10, sr_only, text_base, text_gray_500, text_gray_900, w_0, w_auto)


headerSlice : String -> Html msg
headerSlice url =
    header []
        [ div [ css [ relative, bg_white ] ]
            [ div [ css [ flex, justify_between, items_center, max_w_7xl, mx_auto, px_4, py_6, lg [ px_8 ], md [ justify_start, space_x_10 ], sm [ px_6 ] ] ]
                [ div [ css [ flex, justify_start, lg [ w_0, flex_1 ] ] ]
                    [ a [ href (Route.toHref Route.Home_) ]
                        [ span [ css [ sr_only ] ]
                            [ text "Azimutt" ]
                        , img [ src url, alt "Azimutt", css [ h_8, w_auto, sm [ h_10 ] ] ] []
                        ]
                    ]
                , nav [ css [ hidden, space_x_10, md [ flex ] ] ]
                    [ menuLink2 Route.Blog [ text "Blog" ]
                    , menuLink (constants.azimuttGithub ++ "/discussions") [ text "Discussions" ]
                    , menuLink (constants.azimuttGithub ++ "/projects/1") [ text "Roadmap" ]
                    , menuLink constants.azimuttGithub [ text "Source code" ]
                    , menuLink (constants.azimuttGithub ++ "/issues") [ text "Bug reports" ]
                    , menuLink constants.azimuttTwitter [ Icon.twitter [], span [ css [ sr_only ] ] [ text "Twitter" ] ]
                    ]
                ]
            ]
        ]


menuLink : String -> List (Html msg) -> Html msg
menuLink url children =
    extLink url [ css [ text_base, font_medium, text_gray_500, hover [ text_gray_900 ] ] ] children


menuLink2 : Route -> List (Html msg) -> Html msg
menuLink2 url children =
    a [ href (Route.toHref url), css [ text_base, font_medium, text_gray_500, hover [ text_gray_900 ] ] ] children


doc : Chapter x
doc =
    chapter "Header"
        |> renderComponentList
            [ ( "default", headerSlice "/logo.png" )
            ]
