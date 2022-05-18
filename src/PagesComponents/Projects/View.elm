module PagesComponents.Projects.View exposing (viewProjects)

import Components.Atoms.Icon as Icon
import Components.Atoms.Link as Link
import Components.Molecules.Alert as Alert
import Components.Molecules.ItemList as ItemList
import Components.Molecules.Modal as Modal
import Components.Molecules.Tooltip as Tooltip
import Conf
import Dict
import Gen.Route as Route exposing (Route)
import Html exposing (Html, a, button, div, h3, li, p, span, text, ul)
import Html.Attributes exposing (class, href, id, type_)
import Html.Events exposing (onClick)
import Libs.Bool as Bool
import Libs.DateTime exposing (formatDate)
import Libs.Html exposing (bText)
import Libs.Html.Attributes exposing (ariaHidden, css, role, track)
import Libs.String as String
import Libs.Tailwind as Tw exposing (TwClass, focus, focus_ring_500, hover, lg, md, sm)
import Libs.Task as T
import Models.Project.ProjectStorage exposing (ProjectStorage(..))
import PagesComponents.Helpers exposing (appShell)
import PagesComponents.Projects.Id_.Models.ProjectInfo exposing (ProjectInfo)
import PagesComponents.Projects.Models exposing (Model, Msg(..))
import Router
import Shared exposing (StoredProjects(..))
import Time
import Track


viewProjects : Route -> Shared.Model -> Model -> List (Html Msg)
viewProjects currentRoute shared model =
    appShell shared.user
        currentRoute
        (\link -> SelectMenu link.text)
        DropdownToggle
        Logout
        model
        [ text model.selectedMenu ]
        [ viewContent shared model ]
        [ viewModal model ]


viewContent : Shared.Model -> Model -> Html Msg
viewContent shared model =
    div [ css [ "p-8", sm [ "p-6" ] ] ]
        [ viewProjectList shared model
        , if shared.user == Nothing then
            div [ class "mt-3" ]
                [ Alert.withActions
                    { color = Tw.blue
                    , icon = Icon.InformationCircle
                    , title = "You are not logged in"
                    , actions =
                        [ Link.secondary3 Tw.blue [ href (Router.login Route.Projects) ] [ text "Login or Signup" ]
                        ]
                    }
                    [ text "Login to access your cloud stored projects or store some projects in the cloud (instead of browser only)."
                    ]
                ]

          else
            div [] []
        ]


viewProjectList : Shared.Model -> Model -> Html Msg
viewProjectList shared model =
    div []
        [ h3 [ css [ "text-lg font-medium" ] ] [ text "Projects" ]
        , case model.projects of
            Loading ->
                div [ css [ "mt-6" ] ] [ projectList [ viewProjectPlaceholder ] ]

            Loaded [] ->
                viewNoProjects

            Loaded projects ->
                div [ css [ "mt-6" ] ] [ projectList ((projects |> List.map (viewProjectCard shared.zone)) ++ [ viewNewProject ]) ]
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
                        , onClick = NavigateTo (Route.toHref Route.Projects__New ++ "?sample=" ++ s.key)
                        }
                    )
            )
        ]


viewFirstProject : Html msg
viewFirstProject =
    a [ href (Route.toHref Route.Projects__New), css [ "mt-6 relative block w-full border-2 border-gray-200 border-dashed rounded-lg py-12 text-center text-gray-400", hover [ "border-gray-400" ], focus [ "outline-none ring-2 ring-offset-2 ring-primary-500" ] ] ]
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


viewProjectCard : Time.Zone -> ProjectInfo -> Html Msg
viewProjectCard zone project =
    li [ class "az-project", css [ "col-span-1 flex flex-col border border-gray-200 rounded-lg divide-y divide-gray-200", hover [ "shadow-lg" ] ] ]
        [ div [ css [ "p-6" ] ]
            [ h3 [ css [ "text-lg font-medium flex" ] ] [ Icon.outline (Bool.cond (project.storage == Cloud) Icon.Cloud Icon.Folder) "mr-1", text project.name ]
            , ul [ css [ "mt-1 text-gray-500 text-sm" ] ]
                [ li [] [ text ((project.tables |> String.pluralize "table") ++ ", " ++ (project.layouts |> String.pluralize "layout")) ]
                , li [] [ text ("Edited on " ++ formatDate zone project.createdAt) ]
                ]
            ]
        , div [ css [ "flex divide-x divide-gray-200" ] ]
            [ button [ type_ "button", onClick (confirmDeleteProject project), css [ "flex-grow-0 inline-flex items-center justify-center py-4 text-sm text-gray-700 font-medium px-4", hover [ "text-gray-500" ] ] ]
                [ Icon.outline Icon.Trash "text-gray-400" ]
                |> Tooltip.t "Delete this project"
            , a ([ href (Route.toHref (Route.Projects__Id_ { id = project.id })), css [ "flex-grow inline-flex items-center justify-center py-4 text-sm text-gray-700 font-medium", hover [ "text-gray-500" ] ] ] ++ track (Track.loadProject project))
                [ Icon.outline Icon.ArrowCircleRight "text-gray-400", span [ css [ "ml-3" ] ] [ text "Open project" ] ]
            ]
        ]


confirmDeleteProject : ProjectInfo -> Msg
confirmDeleteProject project =
    ConfirmOpen
        { color = Tw.red
        , icon = Icon.Trash
        , title = "Delete project"
        , message = span [] [ text "Are you sure you want to delete ", bText project.name, text " project?" ]
        , confirm = "Delete " ++ project.name
        , cancel = "Cancel"
        , onConfirm = T.send (DeleteProject project)
        }


viewNewProject : Html msg
viewNewProject =
    li [ css [ "col-span-1" ] ]
        [ a [ href (Route.toHref Route.Projects__New), css [ "relative block w-full border-2 border-gray-200 border-dashed rounded-lg py-12 text-center text-gray-200", hover [ "border-gray-400 text-gray-400" ], focus_ring_500 Tw.primary ] ]
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
