module PagesComponents.Projects.View exposing (viewProjects)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.ItemList as ItemList
import Components.Molecules.Modal as Modal
import Components.Molecules.Tooltip as Tooltip
import Conf
import Css
import Dict
import Gen.Route as Route
import Html.Styled exposing (Html, a, button, div, fromUnstyled, h3, li, p, span, text, toUnstyled, ul)
import Html.Styled.Attributes exposing (class, css, href, id, type_)
import Html.Styled.Events exposing (onClick)
import Libs.DateTime exposing (formatDate)
import Libs.Html.Styled exposing (bText)
import Libs.Html.Styled.Attributes exposing (ariaHidden, role, track)
import Libs.Models.Color as Color
import Libs.String as S
import Libs.Tailwind.Utilities as Tu
import Libs.Task as T
import Models.Project exposing (Project)
import PagesComponents.Helpers exposing (appShell)
import PagesComponents.Projects.Models exposing (Model, Msg(..))
import Shared exposing (StoredProjects(..))
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw
import Time
import Track


viewProjects : Shared.Model -> Model -> List (Html Msg)
viewProjects shared model =
    appShell (\link -> SelectMenu link.text)
        ToggleMobileMenu
        model
        [ text model.selectedMenu ]
        [ viewContent shared model ]
        [ viewModal model ]


viewContent : Shared.Model -> Model -> Html Msg
viewContent shared model =
    div [ css [ Tw.p_8, Bp.sm [ Tw.p_6 ] ] ]
        [ viewProjectList shared model
        ]


viewProjectList : Shared.Model -> Model -> Html Msg
viewProjectList shared model =
    div []
        [ h3 [ css [ Tw.text_lg, Tw.font_medium ] ] [ text "Projects" ]
        , case model.projects of
            Loading ->
                div [ css [ Tw.mt_6 ] ] [ projectList [ viewProjectPlaceholder ] ]

            Loaded [] ->
                viewNoProjects

            Loaded projects ->
                div [ css [ Tw.mt_6 ] ] [ projectList ((projects |> List.map (viewProjectCard shared.zone)) ++ [ viewNewProject ]) ]
        ]


viewNoProjects : Html Msg
viewNoProjects =
    div []
        [ p [ css [ Tw.mt_1, Tw.text_sm, Tw.text_gray_500 ] ]
            [ text "You haven’t created any project yet. Import your own schema." ]
        , viewFirstProject
        , div [ css [ Tw.mt_6, Tw.text_sm, Tw.font_medium, Color.text Conf.theme.color 600 ] ]
            [ text "Or explore a sample one"
            , span [ ariaHidden True ] [ text " →" ]
            ]
        , ItemList.withIcons Conf.theme
            (Conf.schemaSamples
                |> Dict.values
                |> List.sortBy .tables
                |> List.map
                    (\s ->
                        { color = s.color
                        , icon = s.icon
                        , title = s.name ++ " (" ++ (s.tables |> String.fromInt) ++ " tables)"
                        , description = s.description
                        , active = True
                        , onClick = NavigateTo (Route.toHref Route.Projects__New ++ "?sample=" ++ s.key)
                        }
                    )
            )
        ]


viewFirstProject : Html msg
viewFirstProject =
    a [ href (Route.toHref Route.Projects__New), css [ Tw.mt_6, Tw.relative, Tw.block, Tw.w_full, Tw.border_2, Tw.border_gray_200, Tw.border_dashed, Tw.rounded_lg, Tw.py_12, Tw.text_center, Tw.text_gray_400, Css.focus [ Tw.outline_none, Tw.ring_2, Tw.ring_offset_2, Color.ring Conf.theme.color 500 ], Css.hover [ Tw.border_gray_400 ] ] ]
        [ Icon.outline DocumentAdd [ Tw.mx_auto, Tw.h_12, Tw.w_12 ]
        , span [ css [ Tw.mt_2, Tw.block, Tw.text_sm, Tw.font_medium ] ] [ text "Create a new project" ]
        ]


projectList : List (Html msg) -> Html msg
projectList content =
    ul [ role "list", css [ Tw.grid, Tw.grid_cols_1, Tw.gap_6, Bp.lg [ Tw.grid_cols_4 ], Bp.md [ Tw.grid_cols_3 ], Bp.sm [ Tw.grid_cols_2 ] ] ] content


viewProjectPlaceholder : Html msg
viewProjectPlaceholder =
    li [ class "tw-project-placeholder", css [ Tw.animate_pulse, Tw.col_span_1, Tw.flex, Tw.flex_col, Tw.border, Tw.border_gray_200, Tw.rounded_lg, Tw.divide_y, Tw.divide_gray_200, Css.hover [ Tw.shadow_lg ] ] ]
        [ div [ css [ Tw.p_6 ] ]
            [ h3 [ css [ Tw.text_lg, Tw.font_medium ] ] [ viewTextPlaceholder [ Tw.w_24, Tw.h_3 ] ]
            , ul [ css [ Tw.mt_1, Tw.text_gray_500, Tw.text_sm ] ]
                [ li [] [ viewTextPlaceholder [] ]
                , li [] [ viewTextPlaceholder [] ]
                ]
            ]
        , div [ css [ Tw.flex, Tw.divide_x, Tw.divide_gray_200 ] ]
            [ button [ type_ "button", css [ Tw.flex_grow_0, Tw.inline_flex, Tw.items_center, Tw.justify_center, Tw.py_4, Tw.text_sm, Tw.text_gray_700, Tw.font_medium, Tw.px_4, Css.hover [ Tw.text_gray_500 ] ] ]
                [ viewIconPlaceholder [] ]
            , a [ href "#", css [ Tw.flex_grow, Tw.inline_flex, Tw.items_center, Tw.justify_center, Tw.py_4, Tw.text_sm, Tw.text_gray_700, Tw.font_medium, Css.hover [ Tw.text_gray_500 ] ] ]
                [ viewIconPlaceholder [], viewTextPlaceholder [ Tw.ml_3, Tw.w_24 ] ]
            ]
        ]


viewTextPlaceholder : List Css.Style -> Html msg
viewTextPlaceholder styles =
    span [ css ([ Tw.inline_block, Tw.w_full, Tw.max_w_full, Tw.h_2, Tw.bg_gray_300, Tw.rounded_full ] ++ styles) ] []


viewIconPlaceholder : List Css.Style -> Html msg
viewIconPlaceholder styles =
    span [ css ([ Tw.h_6, Tw.w_6, Tw.rounded_full, Tw.bg_gray_300 ] ++ styles) ] []


viewProjectCard : Time.Zone -> Project -> Html Msg
viewProjectCard zone project =
    li [ class "tw-project", css [ Tw.col_span_1, Tw.flex, Tw.flex_col, Tw.border, Tw.border_gray_200, Tw.rounded_lg, Tw.divide_y, Tw.divide_gray_200, Css.hover [ Tw.shadow_lg ] ] ]
        [ div [ css [ Tw.p_6 ] ]
            [ h3 [ css [ Tw.text_lg, Tw.font_medium ] ] [ text project.name ]
            , ul [ css [ Tw.mt_1, Tw.text_gray_500, Tw.text_sm ] ]
                [ li [] [ text ((project.tables |> S.pluralizeD "table") ++ ", " ++ (project.layouts |> S.pluralizeD "layout")) ]
                , li [] [ text ("Edited on " ++ formatDate zone project.createdAt) ]
                ]
            ]
        , div [ css [ Tw.flex, Tw.divide_x, Tw.divide_gray_200 ] ]
            [ button [ type_ "button", onClick (confirmDeleteProject project), css [ Tw.flex_grow_0, Tw.inline_flex, Tw.items_center, Tw.justify_center, Tw.py_4, Tw.text_sm, Tw.text_gray_700, Tw.font_medium, Tw.px_4, Css.hover [ Tw.text_gray_500 ] ] ]
                [ Icon.outline Trash [ Tw.text_gray_400 ] ]
                |> toUnstyled
                |> Tooltip.t "Delete this project"
                |> fromUnstyled
            , a ([ href (Route.toHref (Route.Projects__Id_ { id = project.id })), css [ Tw.flex_grow, Tw.inline_flex, Tw.items_center, Tw.justify_center, Tw.py_4, Tw.text_sm, Tw.text_gray_700, Tw.font_medium, Css.hover [ Tw.text_gray_500 ] ] ] ++ track (Track.loadProject project))
                [ Icon.outline ArrowCircleRight [ Tw.text_gray_400 ], span [ css [ Tw.ml_3 ] ] [ text "Open project" ] ]
            ]
        ]


confirmDeleteProject : Project -> Msg
confirmDeleteProject project =
    ConfirmOpen
        { color = Color.red
        , icon = Trash
        , title = "Delete project"
        , message = span [] [ text "Are you sure you want to delete ", bText project.name, text " project?" ]
        , confirm = "Delete " ++ project.name
        , cancel = "Cancel"
        , onConfirm = T.send (DeleteProject project)
        }


viewNewProject : Html msg
viewNewProject =
    li [ css [ Tw.col_span_1 ] ]
        [ a [ href (Route.toHref Route.Projects__New), css [ Tw.relative, Tw.block, Tw.w_full, Tw.border_2, Tw.border_gray_200, Tw.border_dashed, Tw.rounded_lg, Tw.py_12, Tw.text_center, Tw.text_gray_200, Tu.focusRing ( Conf.theme.color, 500 ) ( Color.white, 500 ), Css.hover [ Tw.border_gray_400, Tw.text_gray_400 ] ] ]
            [ Icon.outline DocumentAdd [ Tw.mx_auto, Tw.h_12, Tw.w_12 ]
            , span [ css [ Tw.mt_2, Tw.block, Tw.text_sm, Tw.font_medium ] ] [ text "Create a new project" ]
            ]
        ]


viewModal : Model -> Html Msg
viewModal model =
    div [ class "tw-modal", id Conf.ids.modal ]
        [ model.confirm
            |> Maybe.map
                (\c ->
                    Modal.confirm
                        { id = Conf.ids.confirmDialog
                        , icon = c.icon
                        , color = c.color
                        , title = c.title
                        , message = c.message |> toUnstyled
                        , confirm = c.confirm
                        , cancel = c.cancel
                        , onConfirm = ModalClose (ConfirmAnswer True c.onConfirm)
                        , onCancel = ModalClose (ConfirmAnswer False Cmd.none)
                        }
                        model.modalOpened
                        |> fromUnstyled
                )
            |> Maybe.withDefault (div [] [])
        ]
