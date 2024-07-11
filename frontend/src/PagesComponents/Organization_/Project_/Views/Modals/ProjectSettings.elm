module PagesComponents.Organization_.Project_.Views.Modals.ProjectSettings exposing (viewProjectSettings)

import Components.Atoms.Badge as Badge
import Components.Atoms.Icon as Icon exposing (Icon)
import Components.Atoms.Icons as Icons
import Components.Atoms.Input as Input
import Components.Molecules.Slideover as Slideover
import Components.Molecules.Tooltip as Tooltip
import Dict
import Html exposing (Html, button, div, fieldset, input, label, legend, p, span, text)
import Html.Attributes exposing (checked, class, for, id, name, placeholder, type_, value)
import Html.Events exposing (onClick, onInput)
import Libs.Bool as B
import Libs.Html exposing (bText, iText)
import Libs.Html.Attributes exposing (ariaDescribedby, css)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.DateTime as DateTime
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.String as String
import Libs.Tailwind as Tw exposing (TwClass, focus, sm)
import Models.ColumnOrder as ColumnOrder
import Models.OpenAIModel as OpenAIModel
import Models.Project.DatabaseUrlStorage as DatabaseUrlStorage
import Models.Project.ProjectId exposing (ProjectId)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source as Source exposing (Source)
import Models.Project.SourceId as SourceId
import Models.Project.SourceKind exposing (SourceKind(..))
import Models.Project.Table exposing (Table)
import Models.RelationStyle as RelationStyle
import PagesComponents.Organization_.Project_.Components.SourceUpdateDialog as SourceUpdateDialog
import PagesComponents.Organization_.Project_.Models exposing (AmlSidebarMsg(..), Msg(..), ProjectSettingsDialog, ProjectSettingsMsg(..), confirm)
import PagesComponents.Organization_.Project_.Models.Erd exposing (Erd)
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
        (div [ class "pb-32" ]
            [ viewSourcesSection (model.id ++ "-sources") zone erd
            , viewSchemasSection (model.id ++ "-schemas") erd
            , viewDisplaySettingsSection (model.id ++ "-display") erd
            , viewLllSettingsSection (model.id ++ "-llm") erd
            ]
        )


viewSourcesSection : HtmlId -> Time.Zone -> Erd -> Html Msg
viewSourcesSection htmlId zone erd =
    fieldset []
        [ legend [ class "font-medium text-gray-900" ] [ text "Project sources" ]
        , p [ class "text-sm text-gray-500" ] [ text "Active sources are merged to create your current schema." ]
        , div [ class "mt-1 border border-gray-300 rounded-md shadow-sm divide-y divide-gray-300" ]
            ((erd.sources |> List.map (\s -> viewSource htmlId erd.project.id zone s)) ++ [ viewAddSource (htmlId ++ "-new") erd.project.id ])
        ]


viewSource : HtmlId -> ProjectId -> Time.Zone -> Source -> Html Msg
viewSource htmlId _ zone source =
    let
        ( views, tables ) =
            source.tables |> Dict.values |> List.partition .view

        view : Icon -> String -> Time.Posix -> Html Msg
        view =
            \icon updatedAtText updatedAt ->
                div [ class "px-4 py-2" ]
                    [ div [ class "flex justify-between" ]
                        [ viewCheckbox ""
                            (htmlId ++ "-" ++ SourceId.toString source.id)
                            [ span [ class "truncate max-w-xs" ] [ Icon.solid icon "inline", text source.name ]
                            , source |> Source.databaseUrlStorage |> Maybe.mapOrElse (\s -> Badge.basic Tw.blue [ class "ml-1" ] [ text (DatabaseUrlStorage.toString s) ] |> Tooltip.b ("Url stored in " ++ DatabaseUrlStorage.toString s)) (text "")
                            ]
                            source.enabled
                            (source |> PSSourceToggle |> ProjectSettingsMsg)
                        , div []
                            [ button [ type_ "button", onClick (Batch [ ModalClose (ProjectSettingsMsg PSClose), AmlSidebarMsg (AOpen (Just source.id)) ]), css [ focus [ "outline-none" ], B.cond (source.kind == AmlEditor) "" "hidden" ] ]
                                [ Icon.solid Icon.Terminal "inline" ]
                                |> Tooltip.bl "Edit AML"
                            , button [ type_ "button", onClick (source |> Just |> SourceUpdateDialog.Open |> PSSourceUpdate |> ProjectSettingsMsg), css [ focus [ "outline-none" ], B.cond (source.fromSample == Nothing) "" "hidden" ] ]
                                [ Icon.solid Icon.Pencil "inline" ]
                                |> Tooltip.bl "Update source"
                            , button [ type_ "button", onClick (source.id |> PSSourceDelete |> ProjectSettingsMsg |> confirm ("Delete " ++ source.name ++ " source?") (text "Are you really sure?")), css [ focus [ "outline-none" ] ] ]
                                [ Icon.solid Icon.Trash "inline" ]
                                |> Tooltip.bl "Delete this source"
                            ]
                        ]
                    , div [ class "flex justify-between" ]
                        [ span [ class "text-sm text-gray-500" ] [ text ((tables |> String.pluralizeL "table") ++ ", " ++ (views |> String.pluralizeL "view") ++ " & " ++ (source.relations |> String.pluralizeL "relation")) ]
                        , span [ class "text-sm text-gray-500" ] [ text (DateTime.formatDate zone updatedAt) ] |> Tooltip.tl (updatedAtText ++ DateTime.formatDatetime zone updatedAt)
                        ]
                    ]
    in
    case source.kind of
        DatabaseConnection _ ->
            view Icons.sources.database "Last fetched on " source.updatedAt

        SqlLocalFile file ->
            view Icons.sources.sql "File last modified on " file.modified

        SqlRemoteFile _ ->
            view Icons.sources.remote "Last fetched on " source.updatedAt

        PrismaLocalFile file ->
            view Icons.sources.prisma "File last modified on " file.modified

        PrismaRemoteFile _ ->
            view Icons.sources.remote "Last fetched on " source.updatedAt

        JsonLocalFile file ->
            view Icons.sources.json "File last modified on " file.modified

        JsonRemoteFile _ ->
            view Icons.sources.remote "Last fetched on " source.updatedAt

        AmlEditor ->
            view Icons.sources.aml "Last edited on " source.updatedAt


viewAddSource : HtmlId -> ProjectId -> Html Msg
viewAddSource _ _ =
    button [ type_ "button", onClick (Nothing |> SourceUpdateDialog.Open |> PSSourceUpdate |> ProjectSettingsMsg), css [ "inline-flex items-center px-3 py-2 w-full text-left", focus [ "outline-none" ] ] ]
        [ Icon.solid Icon.Plus "inline", text "Add source" ]


viewSchemasSection : HtmlId -> Erd -> Html Msg
viewSchemasSection htmlId erd =
    let
        schemas : List ( SchemaName, List Table )
        schemas =
            erd.sources |> List.concatMap (.tables >> Dict.values) |> List.groupBy .schema |> Dict.toList |> List.map (\( name, tables ) -> ( name, tables )) |> List.sortBy Tuple.first
    in
    fieldset [ class "mt-6" ]
        [ legend [ class "font-medium text-gray-900" ] [ text "Project schemas" ]
        , p [ class "text-sm text-gray-500" ] [ text "Allow you to enable or not SQL schemas in your project." ]
        , div [ class "list-group" ] (schemas |> List.map (viewSchema htmlId erd.settings.removedSchemas))
        , Input.textWithLabelAndHelp "mt-3"
            (htmlId ++ "-default-schema")
            "Default schema"
            "Hide it in diagram to make it cleaner."
            "ex: public, dto..."
            erd.settings.defaultSchema
            (PSDefaultSchemaUpdate >> ProjectSettingsMsg)
        ]


viewSchema : HtmlId -> List SchemaName -> ( SchemaName, List Table ) -> Html Msg
viewSchema htmlId removedSchemas ( schema, tables ) =
    let
        ( views, realTables ) =
            tables |> List.partition .view
    in
    viewCheckbox "mt-3"
        (htmlId ++ "-" ++ schema)
        [ if schema == "" then
            iText "empty"

          else
            bText schema
        , text (" (" ++ (realTables |> String.pluralizeL "table") ++ " & " ++ (views |> String.pluralizeL "view") ++ ")")
        ]
        (removedSchemas |> List.member schema |> not)
        (ProjectSettingsMsg (PSSchemaToggle schema))


viewDisplaySettingsSection : HtmlId -> Erd -> Html Msg
viewDisplaySettingsSection htmlId erd =
    let
        viewsCount : Int
        viewsCount =
            erd.sources |> List.concatMap (.tables >> Dict.values) |> List.filter .view |> List.length
    in
    fieldset [ class "mt-6" ]
        [ legend [ class "font-medium text-gray-900" ] [ text "Display options" ]
        , p [ class "text-sm text-gray-500" ] [ text "Configure global options for this project." ]
        , viewCheckbox (B.cond (viewsCount == 0) "mt-3 hidden" "mt-3")
            (htmlId ++ "-no-views")
            [ bText "Remove views" |> Tooltip.tr "Check this if you don't want to have SQL views in Azimutt"
            , text (" (" ++ (viewsCount |> String.pluralize "view") ++ ")")
            ]
            erd.settings.removeViews
            (ProjectSettingsMsg PSRemoveViewsToggle)
        , Input.textWithLabelAndHelp "mt-3"
            (htmlId ++ "-remove-tables")
            "Remove tables"
            "Some tables are not useful, remove them."
            "ex: flyway_.+, versions, env"
            erd.settings.removedTables
            (PSRemovedTablesUpdate >> ProjectSettingsMsg)
        , (htmlId ++ "-hide-columns-list")
            |> (\fieldId ->
                    div [ class "mt-3" ]
                        [ label [ for fieldId, class "block" ]
                            [ span [ class "text-sm font-medium text-gray-700" ] [ text "Hide columns" ]
                            , p [ id (fieldId ++ "-help"), class "text-sm text-gray-500" ] [ text "Some columns are not interesting, hide them by default." ]
                            ]
                        , div [ class "mt-1 -space-y-px" ]
                            [ div [] [ input [ type_ "text", name fieldId, id fieldId, value erd.settings.hiddenColumns.list, onInput (PSHiddenColumnsListUpdate >> ProjectSettingsMsg), placeholder "ex: created_at, updated_.+", ariaDescribedby (fieldId ++ "-help"), css [ "shadow-sm block w-full border-gray-300 rounded-none rounded-t-md", focus [ "relative z-10 ring-indigo-500 border-indigo-500" ], sm [ "text-sm" ] ] ] [] ]
                            , (htmlId ++ "-hide-columns-max")
                                |> (\fieldIdMax ->
                                        div [ class "flex shadow-sm" ]
                                            [ label [ for fieldIdMax, class "sr-only" ] [ text "Max columns" ]
                                            , span [ css [ "inline-flex items-center px-3 rounded-none rounded-bl-md border border-r-0 border-gray-300 bg-gray-50 text-gray-500", sm [ "text-sm" ] ] ] [ text "Show max:" |> Tooltip.br "Maximum default column shown when show a table" ]
                                            , input [ type_ "number", name fieldIdMax, id fieldIdMax, value (String.fromInt erd.settings.hiddenColumns.max), onInput (PSHiddenColumnsMaxUpdate >> ProjectSettingsMsg), placeholder "Max columns to show when adding a table", css [ "flex-1 min-w-0 block w-full px-3 py-2 rounded-none rounded-br-md border-gray-300", sm [ "text-sm" ], focus [ "ring-indigo-500 border-indigo-500" ] ] ] []
                                            ]
                                   )
                            ]
                        ]
               )
        , viewCheckbox "mt-1" (htmlId ++ "-hide-columns-props") [ text "Hide columns without special property" ] erd.settings.hiddenColumns.props (PSHiddenColumnsPropsToggle |> ProjectSettingsMsg)
        , viewCheckbox "mt-1" (htmlId ++ "-hide-columns-relation") [ text "Hide columns without relation" ] erd.settings.hiddenColumns.relations (PSHiddenColumnsRelationsToggle |> ProjectSettingsMsg)
        , Input.selectWithLabelAndHelp "mt-3"
            (htmlId ++ "-columns-order")
            "Columns order"
            "Choose the default column order for tables."
            (ColumnOrder.all |> List.map (\o -> ( ColumnOrder.toString o, ColumnOrder.show o )))
            (ColumnOrder.toString erd.settings.columnOrder)
            (ColumnOrder.fromString >> PSColumnOrderUpdate >> ProjectSettingsMsg)
        , Input.selectWithLabelAndHelp "mt-3"
            (htmlId ++ "-relation-style")
            "Relation style"
            "What relation style fits you best ;)"
            (RelationStyle.all |> List.map (\s -> ( RelationStyle.toString s, RelationStyle.show s )))
            (RelationStyle.toString erd.settings.relationStyle)
            (RelationStyle.fromString >> PSRelationStyleUpdate >> ProjectSettingsMsg)
        , Input.checkboxWithLabelAndHelp "mt-3"
            (htmlId ++ "-basic-types")
            "Column types"
            ""
            "Use basic types for columns to gain some space"
            erd.settings.columnBasicTypes
            (PSColumnBasicTypesToggle |> ProjectSettingsMsg)
        , Input.checkboxWithLabelAndHelp "mt-3"
            (htmlId ++ "-collapsed-columns")
            "Table display"
            ""
            "Collapse table columns by default"
            erd.settings.collapseTableColumns
            (PSCollapseTableOnShowToggle |> ProjectSettingsMsg)
        ]


viewLllSettingsSection : HtmlId -> Erd -> Html Msg
viewLllSettingsSection htmlId erd =
    fieldset [ class "mt-6" ]
        [ legend [ class "font-medium text-gray-900" ] [ text "LLM options" ]
        , p [ class "text-sm text-gray-500" ] [ text "Configure these to use AI features in Azimutt." ]
        , Input.textWithLabelAndHelp "mt-3"
            (htmlId ++ "-key")
            "OpenAI key"
            "Get it from https://platform.openai.com/api-keys"
            "ex: sk-proj-.........."
            (erd.settings.llm |> Maybe.mapOrElse .key "")
            (PSLlmKeyUpdate >> ProjectSettingsMsg)
        , erd.settings.llm
            |> Maybe.map
                (\llm ->
                    Input.selectWithLabelAndHelp "mt-3"
                        (htmlId ++ "-model")
                        "OpenAI model"
                        "Choose wisely on https://platform.openai.com/docs/models"
                        (OpenAIModel.all |> List.map (\m -> ( OpenAIModel.toString m, OpenAIModel.toLabel m )))
                        (llm.model |> OpenAIModel.toString)
                        (OpenAIModel.fromString >> Maybe.withDefault OpenAIModel.default >> PSLlmModelUpdate >> ProjectSettingsMsg)
                )
            |> Maybe.withDefault (text "")
        ]



-- generic


viewCheckbox : TwClass -> String -> List (Html msg) -> Bool -> msg -> Html msg
viewCheckbox styles fieldId fieldLabel value msg =
    div [ css [ "relative flex items-start", styles ] ]
        [ div [ class "flex items-center h-5" ]
            [ input [ type_ "checkbox", id fieldId, checked value, onClick msg, css [ "h-4 w-4 text-indigo-600 border-gray-300 rounded", focus [ "ring-indigo-500" ] ] ] []
            ]
        , div [ class "ml-3 text-sm" ] [ label [ for fieldId, class "text-gray-700" ] fieldLabel ]
        ]
