module PagesComponents.Projects.Id_.Views.Modals.FindPath exposing (viewFindPath)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Alert as Alert
import Components.Molecules.Modal as Modal
import Components.Molecules.Tooltip as Tooltip
import Conf
import Css
import Dict exposing (Dict)
import Html.Styled exposing (Html, br, button, div, h2, h3, img, input, label, option, p, pre, select, small, span, text)
import Html.Styled.Attributes exposing (alt, css, disabled, for, id, placeholder, selected, src, title, type_, value)
import Html.Styled.Events exposing (onClick, onInput)
import Libs.Html.Styled exposing (bText, extLink)
import Libs.Html.Styled.Attributes exposing (ariaDescribedby)
import Libs.List as L
import Libs.Maybe as M
import Libs.Models.Color as Color
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Theme exposing (Theme)
import Libs.Nel as Nel
import Libs.Tailwind.Utilities as Tu
import Models.Project exposing (Project)
import Models.Project.ColumnRef as ColumnRef exposing (ColumnRef)
import Models.Project.FindPathDialog exposing (FindPathDialog)
import Models.Project.FindPathPath exposing (FindPathPath)
import Models.Project.FindPathSettings as FindPathSettings exposing (FindPathSettings)
import Models.Project.FindPathState as FindPathState
import Models.Project.FindPathStep exposing (FindPathStep)
import Models.Project.FindPathStepDir exposing (FindPathStepDir(..))
import Models.Project.Table exposing (Table)
import Models.Project.TableId as TableId exposing (TableId)
import PagesComponents.Projects.Id_.Models exposing (FindPathMsg(..), Msg(..))
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw


viewFindPath : Theme -> Bool -> Project -> FindPathDialog -> Html Msg
viewFindPath theme opened project model =
    let
        titleId : HtmlId
        titleId =
            model.id ++ "-title"
    in
    Modal.modal
        { id = model.id
        , titleId = titleId
        , isOpen = opened
        , onBackgroundClick = ModalClose (FindPathMsg FPClose)
        }
        [ viewHeader theme titleId
        , viewAlert
        , viewSettings model.id model.showSettings project.settings.findPath
        , viewSearchForm model.id project.tables model.from model.to
        , viewPaths theme model
        , viewFooter theme project.settings.findPath model
        ]


viewHeader : Theme -> String -> Html msg
viewHeader theme titleId =
    div [ css [ Tw.pt_6, Tw.px_6, Bp.sm [ Tw.flex, Tw.items_start ] ] ]
        [ div [ css [ Tw.mx_auto, Tw.flex_shrink_0, Tw.flex, Tw.items_center, Tw.justify_center, Tw.h_12, Tw.w_12, Tw.rounded_full, Color.bg theme.color 100, Bp.sm [ Tw.mx_0, Tw.h_10, Tw.w_10 ] ] ]
            [ Icon.outline LocationMarker [ Color.text theme.color 600 ]
            ]
        , div [ css [ Tw.mt_3, Tw.text_center, Bp.sm [ Tw.mt_0, Tw.ml_4, Tw.text_left ] ] ]
            [ h3 [ id titleId, css [ Tw.text_lg, Tw.leading_6, Tw.font_medium, Tw.text_gray_900 ] ] [ text "Find a path between tables" ]
            , p [ css [ Tw.text_sm, Tw.text_gray_500 ] ]
                [ text "Use relations to find a path between two tables. Useful when you don't know how tables are connected but you want to query their data together." ]
            ]
        ]


viewAlert : Html msg
viewAlert =
    div [ css [ Tw.px_6, Tw.mt_3 ] ]
        [ Alert.withDescription { color = Color.yellow, icon = Exclamation, title = "Experimental feature" }
            [ text "This feature is experimental to see if and how it's useful and "
            , extLink Conf.constants.azimuttDiscussionFindPath [ css [ Tu.link ] ] [ text "gather some feedback" ]
            , text "."
            , br [] []
            , text "Please, be indulgent with the UX and share your thoughts on it (useful or not, how to improve...)."
            ]
        ]


viewSettings : HtmlId -> Bool -> FindPathSettings -> Html Msg
viewSettings modalId isOpen settings =
    div [ css [ Tw.px_6, Tw.mt_3 ] ]
        [ button [ onClick (FindPathMsg FPToggleSettings), css [ Tu.link, Css.focus [ Tw.outline_none ] ] ] [ text "Search settings" ]
        , div [ css [ Tw.p_3, Tw.border, Tw.border_gray_300, Tw.bg_gray_50, Tw.rounded_md, Tw.shadow_sm, Tu.unless isOpen [ Tw.hidden ] ] ]
            [ p [ css [ Tw.mt_1, Tw.text_sm, Tw.text_gray_500 ] ]
                [ text """Finding all possible paths in a big graph with a lot of connections can take a long time.
                          Use the settings below to limit your search and keep the search correct.""" ]
            , viewSettingsInput (modalId ++ "-settings-ignored-tables")
                "text"
                "Ignored tables"
                "ex: users, accounts..."
                "Some columns does not have meaningful links so ignore them for better results."
                (settings.ignoredTables |> List.map TableId.show |> String.join ", ")
                (\v -> FindPathMsg (FPSettingsUpdate { settings | ignoredTables = v |> String.split "," |> List.map String.trim |> List.map TableId.parse }))
            , viewSettingsInput (modalId ++ "-settings-ignored-columns")
                "text"
                "Ignored columns"
                "ex: created_by, updated_by, owner..."
                "Some tables are big hubs which leads to bad results and performance, ignore them."
                (settings.ignoredColumns |> String.join ", ")
                (\v -> FindPathMsg (FPSettingsUpdate { settings | ignoredColumns = v |> String.split "," |> List.map String.trim }))
            , viewSettingsInput (modalId ++ "-settings-path-max-length")
                "number"
                "Max path length"
                "ex: 3"
                "Limit paths in length to limit complexity and performance."
                (String.fromInt settings.maxPathLength)
                (\v -> { settings | maxPathLength = v |> String.toInt |> Maybe.withDefault FindPathSettings.init.maxPathLength } |> FPSettingsUpdate |> FindPathMsg)
            ]
        ]


viewSettingsInput : String -> String -> String -> String -> String -> String -> (String -> msg) -> Html msg
viewSettingsInput fieldId fieldType fieldLabel fieldPlaceholder fieldHelp fieldValue msg =
    div [ css [ Bp.sm [ Tw.grid, Tw.grid_cols_4, Tw.gap_3, Tw.items_start, Tw.mt_3 ] ] ]
        [ label [ for fieldId, css [ Tw.block, Tw.text_sm, Tw.font_medium, Tw.text_gray_700, Bp.sm [ Tw.mt_px, Tw.pt_2 ] ] ] [ text fieldLabel ]
        , div [ css [ Tw.mt_1, Bp.sm [ Tw.mt_0, Tw.col_span_3 ] ] ]
            [ input [ type_ fieldType, id fieldId, value fieldValue, onInput msg, placeholder fieldPlaceholder, ariaDescribedby (fieldId ++ "-help"), css [ Tw.form_input, Tw.w_full, Tw.border_gray_300, Tw.rounded_md, Tw.shadow_sm, Css.focus [ Tw.ring_indigo_500, Tw.border_indigo_500 ], Bp.sm [ Tw.text_sm ] ] ] []
            , p [ id (fieldId ++ "-help"), css [ Tw.text_sm, Tw.text_gray_500 ] ] [ text fieldHelp ]
            ]
        ]


viewSearchForm : HtmlId -> Dict TableId Table -> Maybe TableId -> Maybe TableId -> Html Msg
viewSearchForm modalId tables from to =
    div [ css [ Tw.px_6, Tw.mt_3, Tw.flex, Tw.space_x_3 ] ]
        [ viewSelectCard (modalId ++ "-from") "From" "Starting table for the path" from (FPUpdateFrom >> FindPathMsg) tables
        , viewSelectCard (modalId ++ "-to") "To" "Table you want to go to" to (FPUpdateTo >> FindPathMsg) tables
        ]


viewSelectCard : HtmlId -> String -> String -> Maybe TableId -> (Maybe TableId -> Msg) -> Dict TableId Table -> Html Msg
viewSelectCard fieldId title description selectedValue buildMsg tables =
    div [ css [ Tw.flex_grow, Tw.p_3, Tw.border, Tw.border_gray_300, Tw.rounded_md, Tw.shadow_sm, Bp.sm [ Tw.col_span_3 ] ] ]
        [ label [ for fieldId, css [ Tw.block, Tw.text_sm, Tw.font_medium, Tw.text_gray_700 ] ] [ text title ]
        , div [ css [ Tw.mt_1 ] ]
            [ select [ id fieldId, onInput (\id -> Just id |> M.filter (\i -> not (i == "")) |> Maybe.map TableId.fromString |> buildMsg), css [ Tw.form_select, Tw.block, Tw.w_full, Tw.border_gray_300, Tw.rounded_md, Css.focus [ Tw.ring_indigo_500, Tw.border_indigo_500 ], Bp.sm [ Tw.text_sm ] ] ]
                (option [ value "", selected (selectedValue == Nothing) ] [ text "-- Select a table" ]
                    :: (tables
                            |> Dict.values
                            |> List.map
                                (\t ->
                                    option
                                        [ value (TableId.toString t.id)
                                        , selected (selectedValue |> M.has t.id)
                                        ]
                                        [ text (TableId.show t.id) ]
                                )
                       )
                )
            ]
        , p [ css [ Tw.mt_1, Tw.text_sm, Tw.text_gray_500 ] ] [ text description ]
        ]


viewPaths : Theme -> FindPathDialog -> Html Msg
viewPaths theme model =
    case ( model.from, model.to, model.result ) of
        ( Just from, Just to, FindPathState.Found result ) ->
            if result.paths |> List.isEmpty then
                div [ css [ Tw.px_6, Tw.mt_3, Tw.text_center ] ]
                    [ h2 [ css [ Tw.mt_2, Tw.text_lg, Tw.font_medium, Tw.text_gray_900 ] ] [ text "No path found" ]
                    , img [ src "/assets/images/closed-door.jpg", alt "Closed door", css [ Tw.h_96, Tw.inline_block, Tw.align_middle ] ] []
                    ]

            else
                div [ css [ Tw.px_6, Tw.mt_3, Tw.overflow_y_auto ] ]
                    [ div []
                        ([ text ("Found " ++ String.fromInt (List.length result.paths) ++ " paths between tables ")
                         , bText (TableId.show from)
                         , text " and "
                         , bText (TableId.show to)
                         , text ":"
                         , br [] []
                         ]
                            |> L.appendIf ((result.paths |> List.length) > 100) (small [ css [ Tw.text_gray_500 ] ] [ text "Too much results ? Check 'Search settings' above to ignore some table or columns" ])
                        )
                    , div [ css [ Tw.mt_3, Tw.border, Tw.border_gray_300, Tw.rounded_md, Tw.shadow_sm, Tw.divide_y, Tw.divide_gray_300 ] ]
                        (result.paths |> List.sortBy Nel.length |> List.indexedMap (viewPath theme result.opened from))
                    , small [ css [ Tw.text_gray_500 ] ] [ text "Not enough results ? Check 'Search settings' above and increase max length of path or remove some ignored columns..." ]
                    , div [ css [ Tw.mt_3 ] ]
                        [ text "We hope your like this feature. If you have a few minutes, please write us "
                        , extLink Conf.constants.azimuttDiscussionFindPath [ css [ Tu.link ] ] [ text "a quick feedback" ]
                        , text " about it and your use case so we can continue to improve 🚀"
                        ]
                    ]

        _ ->
            div [] []


viewPath : Theme -> Maybe Int -> TableId -> Int -> FindPathPath -> Html Msg
viewPath theme opened from i path =
    div []
        [ div [ onClick (FindPathMsg (FPToggleResult i)), css [ Tw.px_6, Tw.py_4, Tw.cursor_pointer, Tu.when (opened == Just i) [ Color.bg theme.color 100, Color.text theme.color 700 ] ] ]
            (text (String.fromInt (i + 1) ++ ". ") :: span [] [ text (TableId.show from) ] :: (path |> Nel.toList |> List.concatMap viewPathStep))
        , div [ css [ Tw.px_6, Tw.py_3, Tw.border_t, Tw.border_gray_300, Color.text theme.color 700, Tu.when (opened /= Just i) [ Tw.hidden ] ] ]
            [ pre [] [ text (buildQuery from path) ]
            ]
        ]


viewPathStep : FindPathStep -> List (Html msg)
viewPathStep s =
    case s.direction of
        Right ->
            viewPathStepDetails "→" s.relation.src s.relation.ref

        Left ->
            viewPathStepDetails "←" s.relation.ref s.relation.src


viewPathStepDetails : String -> ColumnRef -> ColumnRef -> List (Html msg)
viewPathStepDetails dir from to =
    [ text " > ", span [ css [ Tw.underline ] ] [ text (TableId.show to.table) ] |> Tooltip.t (ColumnRef.show from ++ " " ++ dir ++ " " ++ ColumnRef.show to) ]


buildQuery : TableId -> FindPathPath -> String
buildQuery table joins =
    "SELECT *"
        ++ ("\nFROM " ++ TableId.show table)
        ++ (joins
                |> Nel.toList
                |> List.map
                    (\s ->
                        case s.direction of
                            Right ->
                                "\n  JOIN " ++ TableId.show s.relation.ref.table ++ " ON " ++ ColumnRef.show s.relation.ref ++ " = " ++ ColumnRef.show s.relation.src

                            Left ->
                                "\n  JOIN " ++ TableId.show s.relation.src.table ++ " ON " ++ ColumnRef.show s.relation.src ++ " = " ++ ColumnRef.show s.relation.ref
                    )
                |> String.join ""
           )


viewFooter : Theme -> FindPathSettings -> FindPathDialog -> Html Msg
viewFooter theme settings model =
    div [ css [ Tw.px_6, Tw.py_3, Tw.mt_3, Tw.flex, Tw.items_center, Tw.justify_between, Tw.flex_row_reverse, Tw.bg_gray_50 ] ]
        (case ( model.from, model.to, model.result ) of
            ( Just from, Just to, FindPathState.Found res ) ->
                if from == res.from && to == res.to && settings == res.settings then
                    [ Button.primary3 theme.color [ onClick (FindPathMsg FPClose) ] [ text "Done" ] ]

                else
                    [ Button.primary3 theme.color [ onClick (FindPathMsg FPSearch) ] [ text "Search" ], span [] [ text "Results are out of sync with search 🤯" ] ]

            ( Just _, Just _, FindPathState.Searching ) ->
                [ Button.primary3 theme.color [ disabled True ] [ Icon.loading [ Tw.neg_ml_1, Tw.mr_2, Tw.animate_spin ], text "Searching..." ] ]

            ( Just _, Just _, FindPathState.Empty ) ->
                [ Button.primary3 theme.color [ onClick (FindPathMsg FPSearch) ] [ text "Search" ] ]

            _ ->
                [ Button.primary3 theme.color [ disabled True ] [ text "Search" ] ]
        )
