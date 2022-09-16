module PagesComponents.Projects.View exposing (viewProjects)

import Components.Atoms.Icon as Icon
import Components.Atoms.Link as Link
import Components.Molecules.Alert as Alert
import Components.Molecules.ItemList as ItemList
import Components.Molecules.Modal as Modal
import Components.Molecules.Tooltip as Tooltip
import Conf
import Dict
import Gen.Route as Route
import Html exposing (Html, a, button, div, h3, li, p, span, text, ul)
import Html.Attributes exposing (class, href, id, type_)
import Html.Events exposing (onClick)
import Html.Lazy as Lazy
import Libs.Html exposing (bText)
import Libs.Html.Attributes exposing (ariaHidden, css, role, track)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.DateTime exposing (formatDate)
import Libs.String as String
import Libs.Tailwind as Tw exposing (TwClass, focus, focus_ring_500, hover, lg, md, sm)
import Libs.Task as T
import Models.Organization exposing (Organization)
import Models.Project.ProjectStorage as ProjectStorage
import Models.ProjectInfo2 exposing (ProjectInfo2)
import PagesComponents.Helpers exposing (appShell)
import PagesComponents.Organization_.Project_.Models.ProjectInfo exposing (ProjectInfo)
import PagesComponents.Projects.Models exposing (Model, Msg(..))
import Services.Backend as Backend
import Services.Toasts as Toasts
import Shared exposing (StoredProjects(..))
import Time
import Track
import Url exposing (Url)


viewProjects : Url -> Shared.Model -> Model -> List (Html Msg)
viewProjects currentUrl shared model =
    appShell shared.conf.env
        currentUrl
        shared.user2
        (\link -> SelectMenu link.text)
        DropdownToggle
        model
        [ text model.selectedMenu ]
        [ viewContent currentUrl shared model ]
        [ viewModal model
        , Lazy.lazy2 Toasts.view Toast model.toasts
        ]


viewContent : Url -> Shared.Model -> Model -> Html Msg
viewContent currentUrl shared model =
    div [ css [ "p-8", sm [ "p-6" ] ] ]
        [ viewProjectList shared model
        , if model.projects /= Loading && shared.user2 == Nothing then
            div [ class "mt-3" ]
                [ Alert.withActions
                    { color = Tw.blue
                    , icon = Icon.InformationCircle
                    , title = "You are not signed in"
                    , actions =
                        [ Link.secondary3 Tw.blue [ href (Backend.loginUrl shared.conf.env currentUrl) ] [ text "Sign in now" ]
                        ]
                    }
                    [ text "Sign in to store your projects in your account, access them from anywhere and even share them with your team."
                    ]
                ]

          else
            div [] []
        ]


viewProjectList : Shared.Model -> Model -> Html Msg
viewProjectList shared model =
    div []
        [ h3 [ css [ "text-lg font-medium" ] ] [ text "Projects" ]
        , if not shared.projectsLoaded then
            div [ css [ "mt-6" ] ] [ projectList [ viewProjectPlaceholder ] ]

          else if List.isEmpty shared.projects2 then
            viewNoProjects

          else
            div [ css [ "mt-6" ] ] [ projectList ((shared.projects2 |> List.map (\p -> viewProjectCard shared.zone (Just p.organization) (legacyProjectInfo p))) ++ [ viewNewProject ]) ]
        , case model.projects of
            Loading ->
                div [] []

            Loaded projects ->
                let
                    legacyProjects : List ProjectInfo
                    legacyProjects =
                        projects |> List.filterNot (\p -> shared.projects2 |> List.memberBy .id p.id)
                in
                if List.isEmpty legacyProjects then
                    div [] []

                else
                    div []
                        [ h3 [ css [ "mt-6 text-lg font-medium" ] ] [ text "Legacy projects" ]
                        , div [ css [ "mt-6" ] ] [ projectList (legacyProjects |> List.map (viewProjectCard shared.zone Nothing)) ]
                        ]
        ]


viewNoProjects : Html Msg
viewNoProjects =
    div []
        [ p [ css [ "mt-1 text-sm text-gray-500" ] ]
            [ text "You haven’t created any project yet. Import your own schema." ]
        , viewFirstProject
        , div [ css [ "mt-6 text-sm font-medium text-primary-600" ] ]
            [ text "Or explore a sample one"
            , span [ ariaHidden True ] [ text " →" ]
            ]
        , ItemList.withIcons
            (Conf.schemaSamples
                |> Dict.values
                |> List.sortBy .tables
                |> List.map
                    (\s ->
                        { color = s.color
                        , icon = s.icon
                        , title = s.name ++ " (" ++ (s.tables |> String.fromInt) ++ " tables)"
                        , description = s.description
                        , active = True
                        , onClick = NavigateTo (Route.toHref Route.New ++ "?sample=" ++ s.key)
                        }
                    )
            )
        ]


viewFirstProject : Html msg
viewFirstProject =
    a [ href (Route.toHref Route.New), css [ "mt-6 relative block w-full border-2 border-gray-200 border-dashed rounded-lg py-12 text-center text-gray-400", hover [ "border-gray-400" ], focus [ "outline-none ring-2 ring-offset-2 ring-primary-500" ] ] ]
        [ Icon.outline2x Icon.DocumentAdd "mx-auto"
        , span [ css [ "mt-2 block text-sm font-medium" ] ] [ text "Create a new project" ]
        ]


projectList : List (Html msg) -> Html msg
projectList content =
    ul [ role "list", css [ "grid grid-cols-1 gap-6", sm [ "grid-cols-2" ], md [ "grid-cols-3" ], lg [ "grid-cols-4" ] ] ] content


viewProjectPlaceholder : Html msg
viewProjectPlaceholder =
    li [ class "az-project-placeholder", css [ "animate-pulse col-span-1 flex flex-col border border-gray-200 rounded-lg divide-y divide-gray-200", hover [ "shadow-lg" ] ] ]
        [ div [ css [ "p-6" ] ]
            [ h3 [ css [ "text-lg font-medium" ] ] [ viewTextPlaceholder "w-24 h-3" ]
            , ul [ css [ "mt-1 text-gray-500 text-sm" ] ]
                [ li [] [ viewTextPlaceholder "w-full" ]
                , li [] [ viewTextPlaceholder "w-full" ]
                ]
            ]
        , div [ css [ "flex divide-x divide-gray-200" ] ]
            [ button [ type_ "button", css [ "flex-grow-0 inline-flex items-center justify-center py-4 text-sm text-gray-700 font-medium px-4", hover [ "text-gray-500" ] ] ]
                [ viewIconPlaceholder "" ]
            , a [ href "#", css [ "flex-grow inline-flex items-center justify-center py-4 text-sm text-gray-700 font-medium", hover [ "text-gray-500" ] ] ]
                [ viewIconPlaceholder "", viewTextPlaceholder "ml-3 w-24" ]
            ]
        ]


viewTextPlaceholder : TwClass -> Html msg
viewTextPlaceholder styles =
    span [ css [ "inline-block h-2 bg-gray-300 rounded-full", styles ] ] []


viewIconPlaceholder : TwClass -> Html msg
viewIconPlaceholder styles =
    span [ css [ "h-6 w-6 rounded-full bg-gray-300", styles ] ] []


legacyProjectInfo : ProjectInfo2 -> ProjectInfo
legacyProjectInfo p =
    { id = p.id
    , name = p.name
    , tables = p.nbTables
    , relations = p.nbRelations
    , layouts = p.nbLayouts
    , storage = p.storage
    , createdAt = p.createdAt
    , updatedAt = p.updatedAt
    }


viewProjectCard : Time.Zone -> Maybe Organization -> ProjectInfo -> Html Msg
viewProjectCard zone organization project =
    li [ class "az-project", css [ "col-span-1 flex flex-col border border-gray-200 rounded-lg divide-y divide-gray-200", hover [ "shadow-lg" ] ] ]
        [ div [ css [ "p-6" ] ]
            [ h3 [ css [ "text-lg font-medium flex" ] ]
                [ if project.storage == ProjectStorage.Azimutt then
                    Icon.outline Icon.Cloud "" |> Tooltip.t "Sync in Azimutt"

                  else
                    Icon.outline Icon.Folder "" |> Tooltip.t "Local project"
                , span [ class "ml-1" ] [ text project.name ]
                ]
            , ul [ css [ "mt-1 text-gray-500 text-sm" ] ]
                [ li [] [ text ((project.tables |> String.pluralize "table") ++ ", " ++ (project.layouts |> String.pluralize "layout")) ]
                , li [] [ text ("Edited on " ++ formatDate zone project.createdAt) ]
                ]
            ]
        , div [ css [ "flex divide-x divide-gray-200" ] ]
            [ button [ type_ "button", onClick (confirmDeleteProject organization project), css [ "flex-grow-0 inline-flex items-center justify-center py-4 text-sm text-gray-700 font-medium px-4", hover [ "text-gray-500" ] ] ]
                [ Icon.outline Icon.Trash "text-gray-400" ]
                |> Tooltip.t "Delete this project"
            , a ([ href (Route.toHref (Route.Organization___Project_ { organization = organization |> Maybe.mapOrElse .id Conf.constants.tmpOrg, project = project.id })), css [ "flex-grow inline-flex items-center justify-center py-4 text-sm text-gray-700 font-medium", hover [ "text-gray-500" ] ] ] ++ track (Track.loadProject project))
                [ Icon.outline Icon.ArrowCircleRight "text-gray-400", span [ css [ "ml-3" ] ] [ text "Open project" ] ]
            ]
        ]


confirmDeleteProject : Maybe Organization -> ProjectInfo -> Msg
confirmDeleteProject organization project =
    ConfirmOpen
        { color = Tw.red
        , icon = Icon.Trash
        , title = "Delete project"
        , message = span [] [ text "Are you sure you want to delete ", bText project.name, text " project?" ]
        , confirm = "Delete " ++ project.name
        , cancel = "Cancel"
        , onConfirm = T.send (DeleteProject organization project)
        }


viewNewProject : Html msg
viewNewProject =
    li [ css [ "col-span-1" ] ]
        [ a [ href (Route.toHref Route.New), css [ "relative block w-full border-2 border-gray-200 border-dashed rounded-lg py-12 text-center text-gray-200", hover [ "border-gray-400 text-gray-400" ], focus_ring_500 Tw.primary ] ]
            [ Icon.outline2x Icon.DocumentAdd "mx-auto"
            , span [ css [ "mt-2 block text-sm font-medium" ] ] [ text "Create a new project" ]
            ]
        ]


viewModal : Model -> Html Msg
viewModal model =
    div [ class "az-modal", id Conf.ids.modal ]
        [ model.confirm
            |> Maybe.map
                (\c ->
                    Modal.confirm
                        { id = Conf.ids.confirmDialog
                        , icon = c.icon
                        , color = c.color
                        , title = c.title
                        , message = c.message
                        , confirm = c.confirm
                        , cancel = c.cancel
                        , onConfirm = ModalClose (ConfirmAnswer True c.onConfirm)
                        , onCancel = ModalClose (ConfirmAnswer False Cmd.none)
                        }
                        model.modalOpened
                )
            |> Maybe.withDefault (div [] [])
        ]
