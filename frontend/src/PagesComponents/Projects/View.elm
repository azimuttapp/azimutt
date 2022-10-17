module PagesComponents.Projects.View exposing (viewProjects)

import Components.Atoms.Icon as Icon
import Components.Atoms.Link as Link
import Components.Molecules.Alert as Alert
import Components.Molecules.Modal as Modal
import Components.Molecules.Tooltip as Tooltip
import Conf
import Gen.Route as Route
import Html exposing (Html, a, button, div, h3, h4, li, p, span, text, ul)
import Html.Attributes exposing (class, href, id, type_)
import Html.Events exposing (onClick)
import Html.Lazy as Lazy
import Libs.Html exposing (bText)
import Libs.Html.Attributes exposing (css, role, track)
import Libs.Models.DateTime exposing (formatDate)
import Libs.String as String
import Libs.Tailwind as Tw exposing (TwClass, hover, lg, md, sm)
import Libs.Task as T
import Models.OrganizationId exposing (OrganizationId)
import Models.Project.ProjectStorage as ProjectStorage
import Models.ProjectInfo as ProjectInfo exposing (ProjectInfo)
import PagesComponents.Helpers exposing (appShell)
import PagesComponents.Projects.Models exposing (Model, Msg(..))
import Services.Backend as Backend
import Services.Toasts as Toasts
import Shared exposing (StoredProjects(..))
import Time
import Track
import Url exposing (Url)


viewProjects : Shared.Model -> Url -> Maybe OrganizationId -> Model -> List (Html Msg)
viewProjects shared currentUrl urlOrganization model =
    appShell currentUrl
        urlOrganization
        shared.user
        (\link -> SelectMenu link.text)
        DropdownToggle
        model
        [ text model.selectedMenu ]
        [ viewContent shared ]
        [ viewModal model
        , Lazy.lazy2 Toasts.view Toast model.toasts
        ]


viewContent : Shared.Model -> Html Msg
viewContent shared =
    div [ css [ "p-8", sm [ "p-6" ] ] ]
        [ h3 [ css [ "text-lg font-medium" ] ] [ text "Legacy projects" ]
        , div [ class "mt-3" ]
            [ Alert.simple Tw.blue
                Icon.InformationCircle
                [ h4 [ class "font-medium text-blue-800" ] [ text "Azimutt has evolved!" ]
                , div [ class "mt-2 text-sm text-blue-700" ]
                    [ p [] [ text "You can now upload projects to our server and share them with other people!" ]
                    , p [] [ text "Of course ", bText "we continue to support local projects", text " but they need to be referenced in your account." ]
                    , p [] [ text "This allows us to know used version and warn you when we stop supporting old ones." ]
                    , p [ class "mt-2" ] [ bText "All you have to do is open your projects and save them." ]
                    ]
                ]
            ]
        , case shared.legacyProjects of
            Loading ->
                div [ css [ "mt-6" ] ] [ projectList [ viewProjectPlaceholder ] ]

            Loaded projects ->
                if List.isEmpty projects then
                    viewNoProjectsNew

                else
                    div [ css [ "mt-6" ] ] [ projectList (projects |> List.map (viewProjectCard shared.zone)) ]
        ]


viewNoProjectsNew : Html msg
viewNoProjectsNew =
    div [ class "mx-auto max-w-7xl py-12 px-4 sm:px-6 md:py-16 lg:px-8 lg:py-20" ]
        [ h4 [ class "text-3xl font-bold tracking-tight text-gray-900 sm:text-4xl" ]
            [ span [ class "block" ] [ text "No legacy projects!" ]
            , span [ class "block text-indigo-600" ] [ text "Well done!" ]
            ]
        , div [ class "mt-8 flex" ]
            [ div [ class "inline-flex" ] [ Link.primary4 Tw.primary [ href (Backend.organizationUrl Nothing) ] [ text "Back to dashboard!" ] ]
            ]
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
            [ h3 [ css [ "text-lg font-medium flex" ] ]
                [ if project.storage == ProjectStorage.Remote then
                    Icon.outline Icon.Cloud "" |> Tooltip.t "Sync in Azimutt"

                  else
                    Icon.outline Icon.Folder "" |> Tooltip.t "Local project"
                , span [ class "ml-1" ] [ text project.name ]
                ]
            , ul [ css [ "mt-1 text-gray-500 text-sm" ] ]
                [ li [] [ text ((project.nbTables |> String.pluralize "table") ++ ", " ++ (project.nbLayouts |> String.pluralize "layout")) ]
                , li [] [ text ("Edited on " ++ formatDate zone project.createdAt) ]
                ]
            ]
        , div [ css [ "flex divide-x divide-gray-200" ] ]
            [ button [ type_ "button", onClick (confirmDeleteProject project), css [ "flex-grow-0 inline-flex items-center justify-center py-4 text-sm text-gray-700 font-medium px-4", hover [ "text-gray-500" ] ] ]
                [ Icon.outline Icon.Trash "text-gray-400" ]
                |> Tooltip.t "Delete this project"
            , a ([ href (Route.toHref (Route.Organization___Project_ { organization = project |> ProjectInfo.organizationId, project = project.id })), css [ "flex-grow inline-flex items-center justify-center py-4 text-sm text-gray-700 font-medium", hover [ "text-gray-500" ] ] ] ++ track (Track.loadProject project))
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
