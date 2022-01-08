module PagesComponents.Projects.Id_.Views.Modals.ProjectSettings exposing (viewProjectSettings)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Slideover as Slideover
import Components.Molecules.Tooltip as Tooltip
import Css
import Dict
import Html.Styled exposing (Attribute, Html, button, div, fieldset, input, label, legend, option, p, select, span, text)
import Html.Styled.Attributes exposing (checked, class, css, for, id, placeholder, selected, type_, value)
import Html.Styled.Events exposing (onClick, onInput)
import Libs.DateTime as DateTime
import Libs.Html.Styled.Attributes exposing (ariaDescribedby)
import Libs.List as L
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.String as S
import Libs.Tailwind.Utilities as Tu
import Models.ColumnOrder as ColumnOrder
import Models.Project exposing (Project)
import Models.Project.ProjectId exposing (ProjectId)
import Models.Project.ProjectSettings exposing (ProjectSettings)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source exposing (Source)
import Models.Project.SourceId as SourceId
import Models.Project.SourceKind exposing (SourceKind(..))
import PagesComponents.Projects.Id_.Models exposing (Msg(..), ProjectSettingsDialog, ProjectSettingsMsg(..), confirm)
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw
import Time


viewProjectSettings : Time.Zone -> Bool -> Project -> ProjectSettingsDialog -> Html Msg
viewProjectSettings zone opened project model =
    Slideover.slideover
        { id = model.id
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
        view : Icon -> String -> Time.Posix -> String -> Html Msg
        view =
            \icon updatedAtText updatedAt labelTitle ->
                div [ css [ Tw.px_4, Tw.py_2 ] ]
                    [ div [ css [ Tw.flex, Tw.justify_between ] ]
                        [ viewCheckbox ("settings-source-" ++ SourceId.toString source.id)
                            (span [] [ Icon.solid icon [ Tw.inline ], text source.name ]
                                |> Tooltip.b labelTitle
                            )
                            source.enabled
                            (ProjectSettingsMsg (PSToggleSource source))
                        , div []
                            [ button [ type_ "button", onClick (ProjectSettingsMsg (PSSourceUploadOpen (Just source))), css [ Tu.when (source.kind == UserDefined || source.fromSample /= Nothing) [ Tw.hidden ], Css.focus [ Tw.outline_none ] ] ]
                                [ Icon.solid Refresh [ Tw.inline ] ]
                                |> Tooltip.bl "Refresh this source"
                            , button [ type_ "button", onClick (ProjectSettingsMsg (PSDeleteSource source) |> confirm ("Delete " ++ source.name ++ " source?") (text "Are you really sure?")), css [ Css.focus [ Tw.outline_none ] ] ]
                                [ Icon.solid Trash [ Tw.inline ] ]
                                |> Tooltip.bl "Delete this source"
                            ]
                        ]
                    , div [ css [ Tw.flex, Tw.justify_between ] ]
                        [ span [ css [ Tu.text_muted ] ] [ text ((source.tables |> S.pluralizeD "table") ++ " & " ++ (source.relations |> S.pluralizeL "relation")) ]
                        , span [ css [ Tu.text_muted ] ] [ text (DateTime.formatDate zone updatedAt) ] |> Tooltip.lt (updatedAtText ++ DateTime.formatDatetime zone updatedAt)
                        ]
                    ]
    in
    case source.kind of
        LocalFile path _ modified ->
            view DocumentText "File last modified on " modified (path ++ " file")

        RemoteFile url _ ->
            view CloudDownload "Last fetched on " source.updatedAt ("File from " ++ url)

        UserDefined ->
            view User "Last edited on " source.updatedAt "Created by you"


viewAddSource : ProjectId -> Html Msg
viewAddSource _ =
    button [ type_ "button", onClick (ProjectSettingsMsg (PSSourceUploadOpen Nothing)), css [ Tw.px_4, Tw.py_2, Tw.w_full, Tw.text_left, Css.focus [ Tw.outline_none ] ] ]
        [ Icon.solid Plus [ Tw.inline ], text "Add source" ]


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
    viewCheckbox ("settings-schema-" ++ schema) (text schema) (removedSchemas |> List.member schema |> not) (ProjectSettingsMsg (PSToggleSchema schema))


viewDisplaySettingsSection : ProjectSettings -> Html Msg
viewDisplaySettingsSection settings =
    fieldset [ css [ Tw.mt_6 ] ]
        [ legend [ css [ Tw.font_medium, Tw.text_gray_900 ] ] [ text "Display options" ]
        , p [ css [ Tw.text_sm, Tw.text_gray_500 ] ] [ text "Configure global options for Azimutt ERD." ]
        , viewCheckbox "settings-no-views" (text "Remove views" |> Tooltip.tr "Check this if you don't want to have SQL views in Azimutt") settings.removeViews (ProjectSettingsMsg PSToggleRemoveViews)
        , viewInputGroup "settings-removed-tables"
            "Removed tables"
            "Some tables are not useful and can clutter search, find path or even UI. Remove them by name or even regex."
            (\attrs ->
                input
                    ([ type_ "text"
                     , placeholder "Add technical tables, ex: flyway_schema_history..."
                     , value settings.removedTables
                     , onInput (PSUpdateRemovedTables >> ProjectSettingsMsg)
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
                     , onInput (PSUpdateHiddenColumns >> ProjectSettingsMsg)
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
                    ([ onInput (ColumnOrder.fromString >> PSUpdateColumnOrder >> ProjectSettingsMsg)
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
