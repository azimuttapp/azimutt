module PagesComponents.App.Views.Settings exposing (viewSettings)

import Conf exposing (conf)
import FontAwesome.Icon exposing (viewIcon)
import FontAwesome.Solid as Icon
import Html exposing (Html, button, div, h5, h6, span, text)
import Html.Attributes exposing (class, id, tabindex, title, type_)
import Libs.Bootstrap exposing (Toggle(..), bsBackdrop, bsDismiss, bsScroll)
import Libs.DateTime exposing (formatDatetime)
import Libs.Html.Attributes exposing (ariaLabel, ariaLabelledBy)
import Libs.Nel as Nel
import Models.Project exposing (Project, ProjectSource, ProjectSourceContent(..))
import PagesComponents.App.Models exposing (Msg(..), TimeInfo)


viewSettings : TimeInfo -> Maybe Project -> Html Msg
viewSettings time project =
    project
        |> Maybe.map
            (\p ->
                div [ id conf.ids.settings, class "offcanvas offcanvas-end", bsScroll True, bsBackdrop "false", ariaLabelledBy (conf.ids.settings ++ "-label"), tabindex -1 ]
                    [ div [ class "offcanvas-header" ]
                        [ h5 [ class "offcanvas-title", id (conf.ids.settings ++ "-label") ] [ text "Settings" ]
                        , button [ type_ "button", class "btn-close text-reset", bsDismiss Offcanvas, ariaLabel "Close" ] []
                        ]
                    , div [ class "offcanvas-body" ]
                        [ h6 [] [ text "Project sources" ]
                        , div [ class "list-group" ] ((p.sources |> Nel.toList |> List.map (viewProjectSource time)) ++ [ viewAddSource ])
                        ]
                    ]
            )
        |> Maybe.withDefault (div [] [])


viewProjectSource : TimeInfo -> ProjectSource -> Html Msg
viewProjectSource time source =
    case source.source of
        LocalFile path _ modified ->
            div [ class "list-group-item d-flex justify-content-between align-items-center" ]
                [ span [ title (path ++ " file, last modified on " ++ formatDatetime time.zone modified) ] [ viewIcon Icon.fileUpload, text " ", text source.name ]
                , span [] [ button [ type_ "button", class "link" ] [ viewIcon Icon.syncAlt ] ]
                ]

        RemoteFile url _ ->
            div [ class "list-group-item d-flex justify-content-between align-items-center" ]
                [ span [ title ("File from " ++ url ++ ", last updated on " ++ formatDatetime time.zone source.updatedAt) ] [ viewIcon Icon.cloudDownloadAlt, text " ", text source.name ]
                , span [] [ button [ type_ "button", class "link" ] [ viewIcon Icon.syncAlt ] ]
                ]


viewAddSource : Html Msg
viewAddSource =
    button [ type_ "button", class "list-group-item list-group-item-action" ] [ viewIcon Icon.plus, text " ", text "Add source" ]
