module PagesComponents.Projects.Id_.Views.Modals.ProjectSettings exposing (viewProjectSettings)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Atoms.Input as Input
import Components.Molecules.Slideover as Slideover
import Components.Molecules.Tooltip2 as Tooltip
import Dict
import Html exposing (Html, button, div, fieldset, input, label, legend, p, span, text)
import Html.Attributes exposing (checked, class, for, id, type_, value)
import Html.Events exposing (onClick)
import Html.Styled as Styled exposing (toUnstyled)
import Libs.Bool as B
import Libs.DateTime as DateTime
import Libs.Html exposing (bText)
import Libs.Html.Attributes exposing (classes)
import Libs.List as L
import Libs.String as S
import Libs.Tailwind exposing (TwClass)
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
        [ legend [ class "font-medium text-gray-900" ] [ text "Project sources" ]
        , div [ class "mt-1 border border-gray-300 rounded-md shadow-sm divide-y divide-gray-300" ]
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
                div [ class "px-4 py-2" ]
                    [ div [ class "flex justify-between" ]
                        [ viewCheckbox ""
                            ("settings-source-" ++ SourceId.toString source.id)
                            [ span [] [ Icon.solid icon [ Tw.inline ] |> toUnstyled, text source.name ] |> Tooltip.b labelTitle ]
                            source.enabled
                            (ProjectSettingsMsg (PSToggleSource source))
                        , div []
                            [ button [ type_ "button", onClick (ProjectSettingsMsg (PSSourceUploadOpen (Just source))), classes [ "focus:outline-none", B.cond (source.kind == UserDefined || source.fromSample /= Nothing) "hidden" "" ] ]
                                [ Icon.solid Refresh [ Tw.inline ] |> toUnstyled ]
                                |> Tooltip.bl "Refresh this source"
                            , button [ type_ "button", onClick (ProjectSettingsMsg (PSDeleteSource source) |> confirm ("Delete " ++ source.name ++ " source?") (Styled.text "Are you really sure?")), class "focus:outline-none" ]
                                [ Icon.solid Trash [ Tw.inline ] |> toUnstyled ]
                                |> Tooltip.bl "Delete this source"
                            ]
                        ]
                    , div [ class "flex justify-between" ]
                        [ span [ class "tw-text-muted" ] [ text ((tables |> S.pluralizeL "table") ++ ", " ++ (views |> S.pluralizeL "view") ++ " & " ++ (source.relations |> S.pluralizeL "relation")) ]
                        , span [ class "tw-text-muted" ] [ text (DateTime.formatDate zone updatedAt) ] |> Tooltip.tl (updatedAtText ++ DateTime.formatDatetime zone updatedAt)
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
    button [ type_ "button", onClick (ProjectSettingsMsg (PSSourceUploadOpen Nothing)), class "inline-flex items-center px-3 py-2 w-full text-left focus:outline-none" ]
        [ Icon.solid Plus [ Tw.inline ] |> toUnstyled, text "Add source" ]


viewSchemasSection : Erd -> Html Msg
viewSchemasSection erd =
    let
        schemas : List ( SchemaName, List Table )
        schemas =
            erd.sources |> List.concatMap (.tables >> Dict.values) |> L.groupBy .schema |> Dict.toList |> List.map (\( name, tables ) -> ( name, tables )) |> List.sortBy Tuple.first
    in
    if List.length schemas > 1 then
        fieldset [ class "mt-6" ]
            [ legend [ class "font-medium text-gray-900" ] [ text "Project schemas" ]
            , p [ class "text-sm text-gray-500" ] [ text "Allow you to enable or not SQL schemas in your project." ]
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
    viewCheckbox "" ("settings-schema-" ++ schema) [ bText schema, text (" (" ++ (realTables |> S.pluralizeL "table") ++ " & " ++ (views |> S.pluralizeL "views") ++ ")") ] (removedSchemas |> List.member schema |> not) (ProjectSettingsMsg (PSToggleSchema schema))


viewDisplaySettingsSection : Erd -> Html Msg
viewDisplaySettingsSection erd =
    let
        viewsCount : Int
        viewsCount =
            erd.sources |> List.concatMap (.tables >> Dict.values) |> List.filter .view |> List.length
    in
    fieldset [ class "mt-6" ]
        [ legend [ class "font-medium text-gray-900" ] [ text "Display options" ]
        , p [ class "text-sm text-gray-500" ] [ text "Configure global options for Azimutt ERD." ]
        , viewCheckbox (B.cond (viewsCount == 0) "hidden" "")
            "settings-no-views"
            [ bText "Remove views" |> Tooltip.tr "Check this if you don't want to have SQL views in Azimutt"
            , text (" (" ++ (viewsCount |> S.pluralize "view") ++ ")")
            ]
            erd.settings.removeViews
            (ProjectSettingsMsg PSToggleRemoveViews)
        , Input.textWithLabelAndHelp "mt-3"
            "settings-removed-tables"
            "text"
            "Removed tables"
            "Add technical tables, ex: flyway_schema_history..."
            "Some tables are not useful and can clutter search, find path or even UI. Remove them by name or even regex."
            erd.settings.removedTables
            (PSUpdateRemovedTables >> ProjectSettingsMsg)
        , Input.textWithLabelAndHelp "mt-3"
            "settings-hidden-columns"
            "text"
            "Hidden columns"
            "Add technical columns, ex: created_at..."
            "Some columns are less interesting, hide them by default when showing a table. Use name or regex."
            erd.settings.hiddenColumns
            (PSUpdateHiddenColumns >> ProjectSettingsMsg)
        , Input.selectWithLabelAndHelp "mt-3"
            "settings-columns-order"
            "Columns order"
            "Select the default column order for tables, will also update order of tables already shown."
            (ColumnOrder.all |> List.map (\o -> ( ColumnOrder.toString o, ColumnOrder.show o )))
            (ColumnOrder.toString erd.settings.columnOrder)
            (ColumnOrder.fromString >> PSUpdateColumnOrder >> ProjectSettingsMsg)
        ]



-- generic


viewCheckbox : TwClass -> String -> List (Html msg) -> Bool -> msg -> Html msg
viewCheckbox styles fieldId fieldLabel value msg =
    div [ classes [ "mt-3 relative flex items-start", styles ] ]
        [ div [ class "flex items-center h-5" ]
            [ input [ type_ "checkbox", id fieldId, checked value, onClick msg, class "h-4 w-4 text-indigo-600 border-gray-300 rounded focus:ring-indigo-500" ] []
            ]
        , div [ class "ml-3 text-sm" ] [ label [ for fieldId, class "text-gray-700" ] fieldLabel ]
        ]
