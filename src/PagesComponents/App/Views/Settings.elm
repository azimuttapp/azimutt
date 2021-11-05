module PagesComponents.App.Views.Settings exposing (viewSettings)

import Conf exposing (conf)
import Dict
import FontAwesome.Icon exposing (Icon, viewIcon)
import FontAwesome.Solid as Icon
import Html exposing (Html, br, button, div, fieldset, h5, input, label, legend, option, select, small, span, text)
import Html.Attributes exposing (checked, class, for, id, placeholder, selected, tabindex, title, type_, value)
import Html.Events exposing (onClick, onInput)
import Libs.Bootstrap exposing (Toggle(..), bsBackdrop, bsDismiss, bsScroll, bsToggle)
import Libs.DateTime exposing (formatDate, formatTime)
import Libs.Html exposing (bText)
import Libs.Html.Attributes exposing (ariaDescribedby, ariaLabel, ariaLabelledby)
import Libs.List as L
import Libs.Maybe as M
import Libs.Task exposing (send)
import Models.ColumnOrder as ColumnOrder
import Models.Project exposing (Project)
import Models.Project.ProjectId exposing (ProjectId)
import Models.Project.ProjectSettings exposing (ProjectSettings)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source exposing (Source)
import Models.Project.SourceKind exposing (SourceKind(..))
import PagesComponents.App.Models exposing (Msg(..), SettingsMsg(..), SourceMsg(..), TimeInfo)
import PagesComponents.App.Views.Modals.SchemaSwitch exposing (viewFileLoader)
import Time


viewSettings : TimeInfo -> Maybe Project -> Html Msg
viewSettings time project =
    project
        |> M.mapOrElse
            (\p ->
                div [ id conf.ids.settings, class "offcanvas offcanvas-end", bsScroll True, bsBackdrop "false", ariaLabelledby (conf.ids.settings ++ "-label"), tabindex -1 ]
                    [ div [ class "offcanvas-header" ]
                        [ h5 [ class "offcanvas-title", id (conf.ids.settings ++ "-label") ] [ text "Settings" ]
                        , button [ type_ "button", class "btn-close text-reset", bsDismiss Offcanvas, ariaLabel "Close" ] []
                        ]
                    , div [ class "offcanvas-body" ] [ viewSourcesSection time p, viewSchemasSection p, viewDisplaySettingsSection p.settings ]
                    ]
            )
            (div [] [])


viewSourcesSection : TimeInfo -> Project -> Html Msg
viewSourcesSection time project =
    fieldset []
        [ legend [] [ text "Project sources" ]
        , div [ class "list-group" ] ((project.sources |> List.map (viewSource project.id time)) ++ [ viewAddSource project.id ])
        ]


viewSource : ProjectId -> TimeInfo -> Source -> Html Msg
viewSource project time source =
    case source.kind of
        LocalFile path _ modified ->
            viewSourceHtml time Icon.fileUpload modified (path ++ " file") source (viewFileLoader "" (Just project) (Just source.id))

        RemoteFile url _ ->
            let
                msg : Msg
                msg =
                    OpenConfirm
                        { content = span [] [ text "Refresh ", bText source.name, text " source with ", bText url, text "?" ]
                        , cmd = send (SourceMsg (LoadRemoteFile (Just project) (Just source.id) url))
                        }
            in
            viewSourceHtml time Icon.cloudDownloadAlt source.updatedAt ("File from " ++ url) source (\html -> button [ type_ "button", class "link", onClick msg ] [ html ])

        UserDefined ->
            viewSourceHtml time Icon.user source.updatedAt "Created by you" source (\_ -> span [] [])


viewSourceHtml : TimeInfo -> Icon -> Time.Posix -> String -> Source -> (Html Msg -> Html Msg) -> Html Msg
viewSourceHtml time icon updatedAt labelTitle source refreshButton =
    div [ class "list-group-item d-flex justify-content-between align-items-center" ]
        [ label [ title labelTitle ]
            [ input [ type_ "checkbox", class "form-check-input me-2", checked source.enabled, onClick (SourceMsg (ToggleSource source)) ] []
            , viewIcon icon
            , text (" " ++ source.name)
            , br [] []
            , small [ class "text-muted" ] [ text ((source.tables |> Dict.size |> String.fromInt) ++ " tables & " ++ (source.relations |> List.length |> String.fromInt) ++ " relations") ]
            ]
        , span []
            [ small [ class "text-muted", title ("at " ++ formatTime time.zone updatedAt) ] [ text (formatDate time.zone updatedAt) ]
            , button
                [ type_ "button"
                , class "link ms-2"
                , title "remove this source"
                , onClick (OpenConfirm { content = span [] [ text "Delete ", bText source.name, text " source?" ], cmd = send (SourceMsg (DeleteSource source)) })
                ]
                [ viewIcon Icon.trash ]
            , span [ class "ms-2", title "refresh this source" ] [ refreshButton (viewIcon Icon.syncAlt) ]
            ]
        ]


viewAddSource : ProjectId -> Html Msg
viewAddSource project =
    viewFileLoader "list-group-item list-group-item-action" (Just project) Nothing (small [] [ viewIcon Icon.plus, text " ", text "Add source" ])


viewSchemasSection : Project -> Html Msg
viewSchemasSection project =
    let
        schemas : List SchemaName
        schemas =
            project.sources |> List.concatMap (.tables >> Dict.values) |> List.map .schema |> L.unique |> List.sort
    in
    if List.length schemas > 1 then
        fieldset []
            [ legend [ class "mt-3" ] [ text "Project schemas" ]
            , div [ class "list-group" ] (schemas |> List.map (viewSchema project.settings.removedSchemas))
            ]

    else
        fieldset [] []


viewSchema : List SchemaName -> SchemaName -> Html Msg
viewSchema removedSchemas schema =
    div [ class "list-group-item" ]
        [ label []
            [ input [ type_ "checkbox", class "form-check-input me-2", checked (removedSchemas |> List.member schema |> not), onClick (SettingsMsg (ToggleSchema schema)) ] []
            , text (" " ++ schema)
            ]
        ]


viewDisplaySettingsSection : ProjectSettings -> Html Msg
viewDisplaySettingsSection settings =
    fieldset []
        [ legend [ class "mt-3" ] [ text "Display options" ]
        , div [ class "mt-3 form-check" ]
            [ input [ type_ "checkbox", class "form-check-input me-2", id "settings-no-views", checked settings.removeViews, onClick (SettingsMsg ToggleRemoveViews) ] []
            , label [ for "settings-no-views", title "Check this if you don't want to have SQL views in Azimutt", bsToggle Tooltip ] [ text " Remove views" ]
            ]
        , div [ class "mt-3" ]
            [ label [ class "form-label", for "settings-removed-tables" ] [ text "Removed tables:" ]
            , input
                [ type_ "text"
                , class "form-control"
                , id "settings-removed-tables"
                , ariaDescribedby "settings-removed-tables-help"
                , placeholder "Add technical tables, ex: flyway_schema_history..."
                , value settings.removedTables
                , onInput (\v -> SettingsMsg (UpdateRemovedTables v))
                ]
                []
            , div [ class "form-text", id "settings-removed-tables-help" ] [ text "Some tables are not useful and can clutter search, find path or even UI. Remove them by name or even regex." ]
            ]
        , div [ class "mt-3" ]
            [ label [ class "form-label", for "settings-hidden-columns" ] [ text "Hidden columns:" ]
            , input
                [ type_ "text"
                , class "form-control"
                , id "settings-hidden-columns"
                , ariaDescribedby "settings-hidden-columns-help"
                , placeholder "Add technical columns, ex: created_at..."
                , value settings.hiddenColumns
                , onInput (\v -> SettingsMsg (UpdateHiddenColumns v))
                ]
                []
            , div [ class "form-text", id "settings-hidden-columns-help" ] [ text "Some columns are less interesting, hide them by default when showing a table. Use name or regex." ]
            ]
        , div [ class "mt-3" ]
            [ label [ class "form-label", for "settings-columns-order" ] [ text "Columns order:" ]
            , select [ class "form-select", id "settings-columns-order", ariaDescribedby "settings-columns-order-help", onInput (\v -> v |> ColumnOrder.fromString |> UpdateColumnOrder |> SettingsMsg) ]
                (ColumnOrder.all |> List.map (\o -> option [ value (ColumnOrder.toString o), selected (o == settings.columnOrder) ] [ text (ColumnOrder.show o) ]))
            , div [ class "form-text", id "settings-columns-order-help" ] [ text "Select the default column order when a table is shown." ]
            ]
        ]
