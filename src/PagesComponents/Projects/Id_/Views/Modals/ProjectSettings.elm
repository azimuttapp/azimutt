module PagesComponents.Projects.Id_.Views.Modals.ProjectSettings exposing (viewProjectSettings)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Slideover as Slideover
import Components.Molecules.Tooltip as Tooltip
import Conf
import Css
import Dict
import Html.Styled exposing (Attribute, Html, button, div, fieldset, input, label, legend, option, p, select, span, text)
import Html.Styled.Attributes exposing (checked, class, css, for, id, placeholder, selected, type_, value)
import Html.Styled.Events exposing (onClick, onInput)
import Libs.DateTime exposing (formatDate, formatTime)
import Libs.Html.Styled.Attributes exposing (ariaDescribedby)
import Libs.List as L
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Tailwind.Utilities as Tu
import Models.ColumnOrder as ColumnOrder
import Models.Project exposing (Project)
import Models.Project.ProjectId exposing (ProjectId)
import Models.Project.ProjectSettings exposing (ProjectSettings)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source exposing (Source)
import Models.Project.SourceId as SourceId
import Models.Project.SourceKind exposing (SourceKind(..))
import PagesComponents.Projects.Id_.Models exposing (Msg(..), ProjectSettingsModel, ProjectSettingsMsg(..), confirm)
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw
import Time


viewProjectSettings : Bool -> Time.Zone -> Project -> ProjectSettingsModel -> Html Msg
viewProjectSettings opened zone project _ =
    Slideover.slideover
        { id = Conf.ids.settings
        , title = "Project settings"
        , isOpen = opened
        , onClickClose = ModalClose (ProjectSettingsMsg PSClose)
        , onClickOverlay = ModalClose (ProjectSettingsMsg PSClose)
        }
        (div []
            [ viewSourcesSection zone project
            , viewSchemasSection project
            , viewDisplaySettingsSection project.settings
            ]
        )


viewSourcesSection : Time.Zone -> Project -> Html Msg
viewSourcesSection zone project =
    fieldset []
        [ legend [ css [ Tw.font_medium, Tw.text_gray_900 ] ] [ text "Project sources" ]
        , div [ css [ Tw.mt_1, Tw.border, Tw.border_gray_300, Tw.rounded_md, Tw.shadow_sm, Tw.divide_y, Tw.divide_gray_300 ] ]
            ((project.sources |> List.map (viewSource project.id zone)) ++ [ viewAddSource project.id ])
        ]


viewSource : ProjectId -> Time.Zone -> Source -> Html Msg
viewSource _ zone source =
    let
        view : Icon -> Time.Posix -> String -> (Html Msg -> Html Msg) -> Html Msg
        view =
            \icon updatedAt labelTitle refreshButton ->
                div [ css [ Tw.px_4, Tw.py_2 ] ]
                    [ div [ css [ Tw.flex, Tw.justify_between ] ]
                        [ viewCheckbox ("settings-source-" ++ SourceId.toString source.id) (span [] [ Icon.solid icon [ Tw.inline ], text source.name ] |> Tooltip.bottom labelTitle) source.enabled (ProjectSettingsMsg (ToggleSource source))
                        , div []
                            [ button [ type_ "button", onClick (confirm ("Delete " ++ source.name ++ " source?") (text "Are you really sure?") (Noop "Delete source")) ] [ Icon.solid Trash [ Tw.inline ] ] |> Tooltip.bottomLeft "Delete this source"
                            , refreshButton (Icon.solid Refresh [ Tw.inline ]) |> Tooltip.bottomLeft "Refresh this source"
                            ]
                        ]
                    , div [ css [ Tw.flex, Tw.justify_between ] ]
                        [ span [ css [ Tu.text_muted ] ] [ text ((source.tables |> Dict.size |> String.fromInt) ++ " tables & " ++ (source.relations |> List.length |> String.fromInt) ++ " relations") ]
                        , span [ css [ Tu.text_muted ] ] [ text (formatDate zone updatedAt) ] |> Tooltip.topLeft ("at " ++ formatTime zone updatedAt)
                        ]
                    ]
    in
    case source.kind of
        LocalFile path _ modified ->
            view DocumentText modified (path ++ " file") (\html -> html {- viewFileLoader "" (Just project) (Just source.id) -})

        RemoteFile url _ ->
            let
                msg : Msg
                msg =
                    Noop """OpenConfirm
                        { content = span [] [ text "Refresh ", bText source.name, text " source with ", bText url, text "?" ]
                        , cmd = send (SourceMsg (LoadRemoteFile (Just project) (Just source.id) url))
                        }"""
            in
            view CloudDownload source.updatedAt ("File from " ++ url) (\html -> button [ type_ "button", class "link", onClick msg ] [ html ])

        UserDefined ->
            view User source.updatedAt "Created by you" (\_ -> span [] [])


viewAddSource : ProjectId -> Html Msg
viewAddSource _ =
    -- viewFileLoader "list-group-item list-group-item-action" (Just project) Nothing (small [] [ viewIcon Icon.plus, text " ", text "Add source" ])
    div [ css [ Tw.px_4, Tw.py_2 ] ] [ Icon.solid Plus [ Tw.inline ], text "Add source" ]


viewSchemasSection : Project -> Html Msg
viewSchemasSection project =
    let
        schemas : List SchemaName
        schemas =
            project.sources |> List.concatMap (.tables >> Dict.values) |> List.map .schema |> L.unique |> List.sort
    in
    if List.length schemas > 1 then
        fieldset [ css [ Tw.mt_6 ] ]
            [ legend [ css [ Tw.font_medium, Tw.text_gray_900 ] ] [ text "Project schemas" ]
            , p [ css [ Tw.text_sm, Tw.text_gray_500 ] ] [ text "Allow you to enable or not SQL schemas in your project." ]
            , div [ class "list-group" ] (schemas |> List.map (viewSchema project.settings.removedSchemas))
            ]

    else
        fieldset [] []


viewSchema : List SchemaName -> SchemaName -> Html Msg
viewSchema removedSchemas schema =
    viewCheckbox ("settings-schema-" ++ schema) (text schema) (removedSchemas |> List.member schema |> not) (ProjectSettingsMsg (ToggleSchema schema))


viewDisplaySettingsSection : ProjectSettings -> Html Msg
viewDisplaySettingsSection settings =
    fieldset [ css [ Tw.mt_6 ] ]
        [ legend [ css [ Tw.font_medium, Tw.text_gray_900 ] ] [ text "Display options" ]
        , p [ css [ Tw.text_sm, Tw.text_gray_500 ] ] [ text "Configure global options for Azimutt ERD." ]
        , viewCheckbox "settings-no-views" (text "Remove views" |> Tooltip.topRight "Check this if you don't want to have SQL views in Azimutt") settings.removeViews (ProjectSettingsMsg ToggleRemoveViews)
        , viewInputGroup "settings-removed-tables"
            "Removed tables"
            "Some tables are not useful and can clutter search, find path or even UI. Remove them by name or even regex."
            (\attrs ->
                input
                    ([ type_ "text"
                     , placeholder "Add technical tables, ex: flyway_schema_history..."
                     , value settings.removedTables
                     , onInput (UpdateRemovedTables >> ProjectSettingsMsg)
                     , css [ Tw.form_input, Tw.shadow_sm, Tw.block, Tw.w_full, Tw.border_gray_300, Tw.rounded_md, Css.focus [ Tw.ring_indigo_500, Tw.border_indigo_500 ], Bp.sm [ Tw.text_sm ] ]
                     ]
                        ++ attrs
                    )
                    []
            )
        , viewInputGroup "settings-hidden-columns"
            "Hidden columns"
            "Some columns are less interesting, hide them by default when showing a table. Use name or regex."
            (\attrs ->
                input
                    ([ type_ "text"
                     , placeholder "Add technical columns, ex: created_at..."
                     , value settings.hiddenColumns
                     , onInput (UpdateHiddenColumns >> ProjectSettingsMsg)
                     , css [ Tw.form_input, Tw.shadow_sm, Tw.block, Tw.w_full, Tw.border_gray_300, Tw.rounded_md, Css.focus [ Tw.ring_indigo_500, Tw.border_indigo_500 ], Bp.sm [ Tw.text_sm ] ]
                     ]
                        ++ attrs
                    )
                    []
            )
        , viewInputGroup "settings-columns-order"
            "Columns order"
            "Select the default column order for tables, will also update order of tables already shown."
            (\attrs ->
                select
                    ([ onInput (ColumnOrder.fromString >> UpdateColumnOrder >> ProjectSettingsMsg)
                     , css [ Tw.form_select, Tw.shadow_sm, Tw.block, Tw.w_full, Tw.border_gray_300, Tw.rounded_md, Css.focus [ Tw.ring_indigo_500, Tw.border_indigo_500 ], Bp.sm [ Tw.text_sm ] ]
                     ]
                        ++ attrs
                    )
                    (ColumnOrder.all |> List.map (\o -> option [ value (ColumnOrder.toString o), selected (o == settings.columnOrder) ] [ text (ColumnOrder.show o) ]))
            )
        ]



-- generic


viewCheckbox : String -> Html msg -> Bool -> msg -> Html msg
viewCheckbox fieldId fieldLabel value msg =
    div [ css [ Tw.mt_3, Tw.relative, Tw.flex, Tw.items_start ] ]
        [ div [ css [ Tw.flex, Tw.items_center, Tw.h_5 ] ]
            [ input [ type_ "checkbox", id fieldId, checked value, onClick msg, css [ Tw.form_checkbox, Tw.h_4, Tw.w_4, Tw.text_indigo_600, Tw.border_gray_300, Tw.rounded, Css.focus [ Tw.ring_indigo_500 ] ] ] []
            ]
        , div [ css [ Tw.ml_3, Tw.text_sm ] ] [ label [ for fieldId, css [ Tw.font_medium, Tw.text_gray_700 ] ] [ fieldLabel ] ]
        ]


viewInputGroup : HtmlId -> String -> String -> (List (Attribute msg) -> Html msg) -> Html msg
viewInputGroup fieldId fieldLabel fieldHelp field =
    div [ css [ Tw.mt_3 ] ]
        [ label [ for fieldId, css [ Tw.block, Tw.text_sm, Tw.font_medium, Tw.text_gray_700 ] ] [ text fieldLabel ]
        , div [ css [ Tw.mt_1 ] ]
            [ field [ id fieldId, ariaDescribedby (fieldId ++ "-help") ] ]
        , p [ css [ Tw.mt_2, Tw.text_sm, Tw.text_gray_500 ], id (fieldId ++ "-help") ]
            [ text fieldHelp ]
        ]
