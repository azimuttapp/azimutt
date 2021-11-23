module PagesComponents.Projects.New.View exposing (viewNewProject)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Organisms.Header as Header
import Css.Global as Global
import Gen.Route as Route
import Html.Styled exposing (Html, a, div, h1, header, main_, text)
import Html.Styled.Attributes exposing (css, href)
import Libs.Models.TwColor as TwColor exposing (TwColorLevel(..), TwColorPosition(..))
import PagesComponents.Projects.New.Models exposing (Model, Msg(..))
import Shared
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw


viewNewProject : Shared.Model -> Model -> List (Html Msg)
viewNewProject shared model =
    [ Global.global Tw.globalStyles
    , Global.global [ Global.selector "html" [ Tw.h_full, Tw.bg_gray_100 ], Global.selector "body" [ Tw.h_full ] ]
    , div [ css [ TwColor.render Bg shared.theme.color L600, Tw.pb_32 ] ]
        [ Header.app
            { theme = shared.theme
            , brand = { img = { src = "/logo.png", alt = "Azimutt" }, link = { url = Route.toHref Route.Home_, text = "Azimutt" } }
            , navigation =
                { links = [ { url = Route.toHref Route.Projects, text = "Dashboard" } ]
                , onClick = \_ -> Noop
                }
            , search = Nothing
            , notifications = Nothing
            , profile = Nothing
            , mobileMenu = { id = "mobile-menu", onClick = Noop }
            }
            { navigationActive = model.navigationActive
            , mobileMenuOpen = model.mobileMenuOpen
            , profileOpen = False
            }
        , viewHeader [ a [ href (Route.toHref Route.Projects) ] [ Icon.outline ArrowLeft [ Tw.inline_block ], text " ", text model.navigationActive ] ]
        ]
    , div [ css [ Tw.neg_mt_32 ] ]
        [ main_ [ css [ Tw.max_w_7xl, Tw.mx_auto, Tw.pb_12, Tw.px_4, Bp.lg [ Tw.px_8 ], Bp.sm [ Tw.px_6 ] ] ]
            [ div [ css [ Tw.bg_white, Tw.rounded_lg, Tw.shadow, Tw.p_8, Bp.sm [ Tw.p_6 ] ] ] [ h1 [] [ text "Content" ] ]
            ]
        ]
    ]


viewHeader : List (Html msg) -> Html msg
viewHeader content =
    header [ css [ Tw.py_10 ] ]
        [ div [ css [ Tw.max_w_7xl, Tw.mx_auto, Tw.px_4, Bp.lg [ Tw.px_8 ], Bp.sm [ Tw.px_6 ] ] ]
            [ h1 [ css [ Tw.text_3xl, Tw.font_bold, Tw.text_white ] ] content
            ]
        ]
