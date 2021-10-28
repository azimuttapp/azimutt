module PagesComponents.App.Views.Settings exposing (viewSettings)

import Conf exposing (conf)
import Dict
import FontAwesome.Icon exposing (Icon, viewIcon)
import FontAwesome.Solid as Icon
import Html exposing (Html, br, button, div, h5, h6, input, label, small, span, text)
import Html.Attributes exposing (checked, class, id, tabindex, title, type_)
import Html.Events exposing (onClick)
import Libs.Bootstrap exposing (Toggle(..), bsBackdrop, bsDismiss, bsScroll)
import Libs.DateTime exposing (formatDate, formatTime)
import Libs.Html exposing (bText)
import Libs.Html.Attributes exposing (ariaLabel, ariaLabelledBy)
import Libs.Maybe as M
import Libs.Task exposing (send)
import Models.Project exposing (Project)
import Models.Project.ProjectId exposing (ProjectId)
import Models.Project.Source exposing (Source)
import Models.Project.SourceKind exposing (SourceKind(..))
import PagesComponents.App.Models exposing (Msg(..), SourceMsg(..), TimeInfo)
import PagesComponents.App.Views.Modals.SchemaSwitch exposing (viewFileLoader)
import Time


viewSettings : TimeInfo -> Maybe Project -> Html Msg
viewSettings time project =
    project
        |> M.mapOrElse
            (\p ->
                div [ id conf.ids.settings, class "offcanvas offcanvas-end", bsScroll True, bsBackdrop "false", ariaLabelledBy (conf.ids.settings ++ "-label"), tabindex -1 ]
                    [ div [ class "offcanvas-header" ]
                        [ h5 [ class "offcanvas-title", id (conf.ids.settings ++ "-label") ] [ text "Settings" ]
                        , button [ type_ "button", class "btn-close text-reset", bsDismiss Offcanvas, ariaLabel "Close" ] []
                        ]
                    , div [ class "offcanvas-body" ]
                        [ h6 [] [ text "Project sources" ]
                        , div [ class "list-group" ] ((p.sources |> List.map (viewSource p.id time)) ++ [ viewAddSource p.id ])
                        ]
                    ]
            )
            (div [] [])


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
