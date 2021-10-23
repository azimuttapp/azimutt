module PagesComponents.App.Views.Settings exposing (viewSettings)

import Conf exposing (conf)
import FontAwesome.Icon exposing (Icon, viewIcon)
import FontAwesome.Solid as Icon
import Html exposing (Html, button, div, h5, h6, input, label, span, text)
import Html.Attributes exposing (checked, class, id, tabindex, title, type_)
import Html.Events exposing (onClick)
import Libs.Bootstrap exposing (Toggle(..), bsBackdrop, bsDismiss, bsScroll)
import Libs.DateTime exposing (formatDatetime)
import Libs.Html.Attributes exposing (ariaLabel, ariaLabelledBy)
import Libs.Nel as Nel
import Models.Project exposing (Project, ProjectId, ProjectSource, ProjectSourceContent(..))
import PagesComponents.App.Models exposing (Msg(..), SourceMsg(..), TimeInfo)
import PagesComponents.App.Views.Modals.SchemaSwitch exposing (viewFileLoader)


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
                        , div [ class "list-group" ] ((p.sources |> Nel.toList |> List.map (viewProjectSource time)) ++ [ viewAddSource p.id ])
                        ]
                    ]
            )
        |> Maybe.withDefault (div [] [])


viewProjectSource : TimeInfo -> ProjectSource -> Html Msg
viewProjectSource time source =
    case source.source of
        LocalFile path _ modified ->
            viewProjectSourceHtml Icon.fileUpload (path ++ " file, last modified on " ++ formatDatetime time.zone modified) source

        RemoteFile url _ ->
            viewProjectSourceHtml Icon.cloudDownloadAlt ("File from " ++ url ++ ", last updated on " ++ formatDatetime time.zone source.updatedAt) source


viewProjectSourceHtml : Icon -> String -> ProjectSource -> Html Msg
viewProjectSourceHtml icon labelTitle source =
    div [ class "list-group-item d-flex justify-content-between align-items-center" ]
        [ label [ title labelTitle ]
            [ input [ type_ "checkbox", class "form-check-input me-2", checked source.enabled, onClick (SourceMsg (ToggleSource source.id)) ] []
            , viewIcon icon
            , text " "
            , text source.name
            ]
        , span [] [ button [ type_ "button", class "link", title ("refresh " ++ source.name) ] [ viewIcon Icon.syncAlt ] ]
        ]


viewAddSource : ProjectId -> Html Msg
viewAddSource project =
    viewFileLoader "list-group-item list-group-item-action" (Just project) (span [] [ viewIcon Icon.plus, text " ", text "Add source" ])
