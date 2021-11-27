module PagesComponents.Projects.New.View exposing (viewNewProject)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Divider as Divider
import Css
import Gen.Route as Route
import Html.Styled exposing (Html, a, aside, div, form, h2, label, nav, p, span, text)
import Html.Styled.Attributes exposing (css, for, href)
import Html.Styled.Events exposing (onClick)
import Libs.FileInput as FileInput
import Libs.Html.Styled.Attributes exposing (ariaCurrent, role)
import Libs.Models.Theme exposing (Theme)
import Libs.Models.TwColor as TwColor exposing (TwColor(..), TwColorLevel(..), TwColorPosition(..))
import Libs.Tailwind.Utilities as Tu
import PagesComponents.Helpers exposing (appShell)
import PagesComponents.Projects.New.Models exposing (Model, Msg(..), Tab(..))
import Shared
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw


viewNewProject : Shared.Model -> Model -> List (Html Msg)
viewNewProject shared model =
    appShell shared.theme
        (\link -> SelectMenu link.text)
        ToggleMobileMenu
        model
        [ a [ href (Route.toHref Route.Projects) ] [ Icon.outline ArrowLeft [ Tw.inline_block ], text " ", text model.navigationActive ] ]
        [ viewContent shared.theme
            model
            { tabs =
                [ { tab = Schema, icon = DocumentText, text = "From SQL schema" }
                , { tab = Sample, icon = Collection, text = "From sample" }
                ]
            }
        ]
        []


type alias PageModel =
    { tabs : List (TabModel Tab)
    }


type alias TabModel tab =
    { tab : tab, icon : Icon, text : String }


viewContent : Theme -> Model -> PageModel -> Html Msg
viewContent theme model page =
    div [ css [ Tw.divide_y, Bp.lg [ Tw.grid, Tw.grid_cols_12, Tw.divide_x ] ] ]
        [ aside [ css [ Tw.py_6, Bp.lg [ Tw.col_span_3 ] ] ]
            [ nav [ css [ Tw.space_y_1 ] ] (page.tabs |> List.map (viewTab theme model.tabActive)) ]
        , div [ css [ Tw.px_4, Tw.py_6, Bp.sm [ Tw.p_6 ], Bp.lg [ Tw.pb_8, Tw.col_span_9, Tw.rounded_r_lg ] ] ]
            [ viewTabContent theme model.tabActive ]
        ]


viewTab : Theme -> Tab -> TabModel Tab -> Html Msg
viewTab theme selected tab =
    if tab.tab == selected then
        a [ href "", css [ TwColor.render Bg theme.color L50, TwColor.render Border theme.color L500, TwColor.render Text theme.color L700, Tw.border_l_4, Tw.px_3, Tw.py_2, Tw.flex, Tw.items_center, Tw.text_sm, Tw.font_medium, Css.hover [ TwColor.render Bg theme.color L50, TwColor.render Text theme.color L700 ] ], ariaCurrent "page" ]
            [ Icon.outline tab.icon [ TwColor.render Text theme.color L500, Tw.flex_shrink_0, Tw.neg_ml_1, Tw.mr_3, Tw.h_6, Tw.w_6 ]
            , span [ css [ Tw.truncate ] ] [ text tab.text ]
            ]

    else
        a [ href "", onClick (SelectTab tab.tab), css [ Tw.border_transparent, Tw.text_gray_900, Tw.border_l_4, Tw.px_3, Tw.py_2, Tw.flex, Tw.items_center, Tw.text_sm, Tw.font_medium, Css.hover [ Tw.bg_gray_50, Tw.text_gray_900 ] ] ]
            [ Icon.outline tab.icon [ Tw.text_gray_400, Tw.flex_shrink_0, Tw.neg_ml_1, Tw.mr_3, Tw.h_6, Tw.w_6 ]
            , span [ css [ Tw.truncate ] ] [ text tab.text ]
            ]


viewTabContent : Theme -> Tab -> Html Msg
viewTabContent theme tab =
    case tab of
        Schema ->
            viewSchemaUpload theme

        Sample ->
            viewSample


viewSchemaUpload : Theme -> Html Msg
viewSchemaUpload theme =
    div []
        [ form []
            [ div []
                [ h2 [ css [ Tw.text_lg, Tw.leading_6, Tw.font_medium, Tw.text_gray_900 ] ] [ text "Import your SQL schema" ]
                , p [ css [ Tw.mt_1, Tw.text_sm, Tw.text_gray_500 ] ] [ text "Everything stay on your machine, don't worry about your schema privacy." ]
                ]
            , div [ css [ Tw.mt_6, Tw.grid, Tw.grid_cols_1, Tw.gap_y_6, Tw.gap_x_4, Bp.sm [ Tw.grid_cols_6 ] ] ]
                [ div [ css [ Bp.sm [ Tw.col_span_6 ] ] ]
                    [ viewFileUpload theme
                    ]
                ]
            ]
        , div [ css [ Tw.my_6 ] ] [ Divider.withLabel "Parsing ..." ]
        , div [ css [ Tw.bg_gray_50, Tw.overflow_hidden, Tw.rounded_lg ] ]
            [ div [ css [ Tw.px_4, Tw.py_5, Bp.sm [ Tw.p_6 ] ] ]
                [ div [] [ text "some logs..." ]
                ]
            ]
        ]


viewFileUpload : Theme -> Html Msg
viewFileUpload theme =
    let
        id : String
        id =
            "file-upload"
    in
    label
        ([ for id, role "button", css [ Tw.mt_1, Tw.flex, Tw.justify_center, Tw.px_6, Tw.pt_5, Tw.pb_6, Tw.border_2, Tw.border_gray_300, Tw.border_dashed, Tw.rounded_md, Tw.text_gray_600, Tu.focusWithinRing ( theme.color, L600 ) ( White, L600 ), Css.hover [ TwColor.render Border theme.color L400, TwColor.render Text theme.color L600 ] ] ]
            ++ FileInput.onDrop
                { onOver = \_ _ -> FileDragOver
                , onLeave = Just { id = id ++ "-label", msg = FileDragLeave }
                , onDrop = \head _ -> LoadLocalFile head
                }
        )
        [ div [ css [ Tw.space_y_1, Tw.text_center ] ]
            [ Icon.outline DocumentAdd [ Tw.mx_auto, Tw.h_12, Tw.w_12 ]
            , div [ css [ Tw.flex, Tw.text_sm ] ]
                [ span [ css [ Tw.relative, Tw.cursor_pointer, Tw.bg_white, Tw.rounded_md, Tw.font_medium, TwColor.render Text theme.color L600 ] ]
                    [ span [] [ text "Upload a file" ]
                    , FileInput.hiddenInputSingle id [ ".sql" ] LoadLocalFile
                    ]
                , p [ css [ Tw.pl_1 ] ] [ text "or drag and drop" ]
                ]
            , p [ css [ Tw.text_xs ] ] [ text "SQL only" ]
            ]
        ]


viewSample : Html msg
viewSample =
    div [] [ text "Sample" ]
