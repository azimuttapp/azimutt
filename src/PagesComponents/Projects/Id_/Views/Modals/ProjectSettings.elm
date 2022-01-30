module PagesComponents.Projects.Id_.Views.Modals.ProjectSettings exposing (viewProjectSettings)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Atoms.Input as Input
import Components.Molecules.Slideover as Slideover
import Components.Molecules.Tooltip as Tooltip
import Css
import Dict
import Html.Styled exposing (Html, button, div, fieldset, input, label, legend, p, span, text)
import Html.Styled.Attributes exposing (checked, class, css, for, id, type_, value)
import Html.Styled.Events exposing (onClick)
import Libs.DateTime as DateTime
import Libs.Html.Styled exposing (bText)
import Libs.List as L
import Libs.String as S
import Libs.Tailwind.Utilities as Tu
import Models.ColumnOrder as ColumnOrder
import Models.Project.ProjectId exposing (ProjectId)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source exposing (Source)
import Models.Project.SourceId as SourceId
import Models.Project.SourceKind exposing (SourceKind(..))
import Models.Project.Table exposing (Table)
import PagesComponents.Projects.Id_.Models exposing (Msg(..), ProjectSettingsDialog, ProjectSettingsMsg(..), confirm)
import PagesComponents.Projects.Id_.Models.Erd exposing (Erd)
import Tailwind.Utilities as Tw
import Time


viewProjectSettings : Time.Zone -> Bool -> Erd -> ProjectSettingsDialog -> Html Msg
viewProjectSettings zone opened erd model =
    Slideover.slideover
        { id = model.id
        , title = "Project settings"
        , isOpen = opened
        , onClickClose = ModalClose (ProjectSettingsMsg PSClose)
        , onClickOverlay = ModalClose (ProjectSettingsMsg PSClose)
        }
        (div []
            [ viewSourcesSection zone erd
            , viewSchemasSection erd
            , viewDisplaySettingsSection erd
            ]
        )


viewSourcesSection : Time.Zone -> Erd -> Html Msg
viewSourcesSection zone erd =
    fieldset []
        [ legend [ css [ Tw.font_medium, Tw.text_gray_900 ] ] [ text "Project sources" ]
        , div [ css [ Tw.mt_1, Tw.border, Tw.border_gray_300, Tw.rounded_md, Tw.shadow_sm, Tw.divide_y, Tw.divide_gray_300 ] ]
            ((erd.sources |> List.map (viewSource erd.project.id zone)) ++ [ viewAddSource erd.project.id ])
        ]


viewSource : ProjectId -> Time.Zone -> Source -> Html Msg
viewSource _ zone source =
    let
        ( views, tables ) =
            source.tables |> Dict.values |> List.partition .view

        view : Icon -> String -> Time.Posix -> String -> Html Msg
        view =
            \icon updatedAtText updatedAt labelTitle ->
                div [ css [ Tw.px_4, Tw.py_2 ] ]
                    [ div [ css [ Tw.flex, Tw.justify_between ] ]
                        [ viewCheckbox []
                            ("settings-source-" ++ SourceId.toString source.id)
                            [ span [] [ Icon.solid icon [ Tw.inline ], text source.name ] |> Tooltip.b labelTitle ]
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
                        [ span [ css [ Tu.text_muted ] ] [ text ((tables |> S.pluralizeL "table") ++ ", " ++ (views |> S.pluralizeL "view") ++ " & " ++ (source.relations |> S.pluralizeL "relation")) ]
                        , span [ css [ Tu.text_muted ] ] [ text (DateTime.formatDate zone updatedAt) ] |> Tooltip.tl (updatedAtText ++ DateTime.formatDatetime zone updatedAt)
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
    button [ type_ "button", onClick (ProjectSettingsMsg (PSSourceUploadOpen Nothing)), css [ Tw.inline_flex, Tw.items_center, Tw.px_3, Tw.py_2, Tw.w_full, Tw.text_left, Css.focus [ Tw.outline_none ] ] ]
        [ Icon.solid Plus [ Tw.inline ], text "Add source" ]


viewSchemasSection : Erd -> Html Msg
viewSchemasSection erd =
    let
        schemas : List ( SchemaName, List Table )
        schemas =
            erd.sources |> List.concatMap (.tables >> Dict.values) |> L.groupBy .schema |> Dict.toList |> List.map (\( name, tables ) -> ( name, tables )) |> List.sortBy Tuple.first
    in
    if List.length schemas > 1 then
        fieldset [ css [ Tw.mt_6 ] ]
            [ legend [ css [ Tw.font_medium, Tw.text_gray_900 ] ] [ text "Project schemas" ]
            , p [ css [ Tw.text_sm, Tw.text_gray_500 ] ] [ text "Allow you to enable or not SQL schemas in your project." ]
            , div [ class "list-group" ] (schemas |> List.map (viewSchema erd.settings.removedSchemas))
            ]

    else
        fieldset [] []


viewSchema : List SchemaName -> ( SchemaName, List Table ) -> Html Msg
viewSchema removedSchemas ( schema, tables ) =
    let
        ( views, realTables ) =
            tables |> List.partition .view
    in
    viewCheckbox [] ("settings-schema-" ++ schema) [ bText schema, text (" (" ++ (realTables |> S.pluralizeL "table") ++ " & " ++ (views |> S.pluralizeL "views") ++ ")") ] (removedSchemas |> List.member schema |> not) (ProjectSettingsMsg (PSToggleSchema schema))


viewDisplaySettingsSection : Erd -> Html Msg
viewDisplaySettingsSection erd =
    let
        viewsCount : Int
        viewsCount =
            erd.sources |> List.concatMap (.tables >> Dict.values) |> List.filter .view |> List.length
    in
    fieldset [ css [ Tw.mt_6 ] ]
        [ legend [ css [ Tw.font_medium, Tw.text_gray_900 ] ] [ text "Display options" ]
        , p [ css [ Tw.text_sm, Tw.text_gray_500 ] ] [ text "Configure global options for Azimutt ERD." ]
        , viewCheckbox [ Tu.when (viewsCount == 0) [ Tw.hidden ] ]
            "settings-no-views"
            [ bText "Remove views" |> Tooltip.tr "Check this if you don't want to have SQL views in Azimutt"
            , text (" (" ++ (viewsCount |> S.pluralize "view") ++ ")")
            ]
            erd.settings.removeViews
            (ProjectSettingsMsg PSToggleRemoveViews)
        , Input.textWithLabelAndHelp [ Tw.mt_3 ]
            "settings-removed-tables"
            "text"
            "Removed tables"
            "Add technical tables, ex: flyway_schema_history..."
            "Some tables are not useful and can clutter search, find path or even UI. Remove them by name or even regex."
            erd.settings.removedTables
            (PSUpdateRemovedTables >> ProjectSettingsMsg)
        , Input.textWithLabelAndHelp [ Tw.mt_3 ]
            "settings-hidden-columns"
            "text"
            "Hidden columns"
            "Add technical columns, ex: created_at..."
            "Some columns are less interesting, hide them by default when showing a table. Use name or regex."
            erd.settings.hiddenColumns
            (PSUpdateHiddenColumns >> ProjectSettingsMsg)
        , Input.selectWithLabelAndHelp [ Tw.mt_3 ]
            "settings-columns-order"
            "Columns order"
            "Select the default column order for tables, will also update order of tables already shown."
            (ColumnOrder.all |> List.map (\o -> ( ColumnOrder.toString o, ColumnOrder.show o )))
            (ColumnOrder.toString erd.settings.columnOrder)
            (ColumnOrder.fromString >> PSUpdateColumnOrder >> ProjectSettingsMsg)
        ]



-- generic


viewCheckbox : List Css.Style -> String -> List (Html msg) -> Bool -> msg -> Html msg
viewCheckbox styles fieldId fieldLabel value msg =
    div [ css ([ Tw.mt_3, Tw.relative, Tw.flex, Tw.items_start ] ++ styles) ]
        [ div [ css [ Tw.flex, Tw.items_center, Tw.h_5 ] ]
            [ input [ type_ "checkbox", id fieldId, checked value, onClick msg, css [ Tw.form_checkbox, Tw.h_4, Tw.w_4, Tw.text_indigo_600, Tw.border_gray_300, Tw.rounded, Css.focus [ Tw.ring_indigo_500 ] ] ] []
            ]
        , div [ css [ Tw.ml_3, Tw.text_sm ] ] [ label [ for fieldId, css [ Tw.text_gray_700 ] ] fieldLabel ]
        ]
