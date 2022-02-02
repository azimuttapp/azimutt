module PagesComponents.Projects.View exposing (viewProjects)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.ItemList as ItemList
import Components.Molecules.Modal as Modal
import Components.Molecules.Tooltip as Tooltip
import Conf
import Dict
import Gen.Route as Route
import Html exposing (Html, a, button, div, h3, li, p, span, text, ul)
import Html.Attributes exposing (class, href, id, type_)
import Html.Events exposing (onClick)
import Html.Styled as Styled exposing (fromUnstyled, toUnstyled)
import Libs.DateTime exposing (formatDate)
import Libs.Html exposing (bText)
import Libs.Html.Attributes exposing (ariaHidden, classes, role, track)
import Libs.Models.Color as Color
import Libs.String as S
import Libs.Tailwind exposing (TwClass, focus, focusRing, hover, lg, md, ring_500, sm, text_600)
import Libs.Task as T
import Models.Project exposing (Project)
import PagesComponents.Helpers exposing (appShell)
import PagesComponents.Projects.Models exposing (Model, Msg(..))
import Shared exposing (StoredProjects(..))
import Tailwind.Utilities as Tw
import Time
import Track


viewProjects : Shared.Model -> Model -> List (Styled.Html Msg)
viewProjects shared model =
    appShell (\link -> SelectMenu link.text)
        ToggleMobileMenu
        model
        [ text model.selectedMenu |> fromUnstyled ]
        [ viewContent shared model |> fromUnstyled ]
        [ viewModal model |> fromUnstyled ]


viewContent : Shared.Model -> Model -> Html Msg
viewContent shared model =
    div [ classes [ "p-8", sm "p-6" ] ]
        [ viewProjectList shared model
        ]


viewProjectList : Shared.Model -> Model -> Html Msg
viewProjectList shared model =
    div []
        [ h3 [ classes [ "text-lg font-medium" ] ] [ text "Projects" ]
        , case model.projects of
            Loading ->
                div [ classes [ "mt-6" ] ] [ projectList [ viewProjectPlaceholder ] ]

            Loaded [] ->
                viewNoProjects

            Loaded projects ->
                div [ classes [ "mt-6" ] ] [ projectList ((projects |> List.map (viewProjectCard shared.zone)) ++ [ viewNewProject ]) ]
        ]


viewNoProjects : Html Msg
viewNoProjects =
    div []
        [ p [ classes [ "mt-1 text-sm text-gray-500" ] ]
            [ text "You haven’t created any project yet. Import your own schema." ]
        , viewFirstProject
        , div [ classes [ "mt-6 text-sm font-medium", text_600 Conf.theme.color ] ]
            [ text "Or explore a sample one"
            , span [ ariaHidden True ] [ text " →" ]
            ]
        , ItemList.withIcons Conf.theme
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
    a [ href (Route.toHref Route.Projects__New), classes [ "mt-6 relative block w-full border-2 border-gray-200 border-dashed rounded-lg py-12 text-center text-gray-400", hover "border-gray-400", focus ("outline-none ring-2 ring-offset-2 " ++ ring_500 Conf.theme.color) ] ]
        [ Icon.outline DocumentAdd [ Tw.mx_auto, Tw.h_12, Tw.w_12 ] |> toUnstyled
        , span [ classes [ "mt-2 block text-sm font-medium" ] ] [ text "Create a new project" ]
        ]


projectList : List (Html msg) -> Html msg
projectList content =
    ul [ role "list", classes [ "grid grid-cols-1 gap-6", lg "grid-cols-4", md "grid-cols-3", sm "grid-cols-2" ] ] content


viewProjectPlaceholder : Html msg
viewProjectPlaceholder =
    li [ class "tw-project-placeholder", classes [ "animate-pulse col-span-1 flex flex-col border border-gray-200 rounded-lg divide-y divide-gray-200", hover "shadow-lg" ] ]
        [ div [ classes [ "p-6" ] ]
            [ h3 [ classes [ "text-lg font-medium" ] ] [ viewTextPlaceholder "w-24 h-3" ]
            , ul [ classes [ "mt-1 text-gray-500 text-sm" ] ]
                [ li [] [ viewTextPlaceholder "" ]
                , li [] [ viewTextPlaceholder "" ]
                ]
            ]
        , div [ classes [ "flex divide-x divide-gray-200" ] ]
            [ button [ type_ "button", classes [ "flex-grow-0 inline-flex items-center justify-center py-4 text-sm text-gray-700 font-medium px-4", hover "text-gray-500" ] ]
                [ viewIconPlaceholder "" ]
            , a [ href "#", classes [ "flex-grow inline-flex items-center justify-center py-4 text-sm text-gray-700 font-medium", hover "text-gray-500" ] ]
                [ viewIconPlaceholder "", viewTextPlaceholder "ml-3 w-24" ]
            ]
        ]


viewTextPlaceholder : TwClass -> Html msg
viewTextPlaceholder styles =
    span [ classes [ "inline-block w-full max-w-full h-2 bg-gray-300 rounded-full", styles ] ] []


viewIconPlaceholder : TwClass -> Html msg
viewIconPlaceholder styles =
    span [ classes [ "h-6 w-6 rounded-full bg-gray-300", styles ] ] []


viewProjectCard : Time.Zone -> Project -> Html Msg
viewProjectCard zone project =
    li [ class "tw-project", classes [ "col-span-1 flex flex-col border border-gray-200 rounded-lg divide-y divide-gray-200", hover "shadow-lg" ] ]
        [ div [ classes [ "p-6" ] ]
            [ h3 [ classes [ "text-lg font-medium" ] ] [ text project.name ]
            , ul [ classes [ "mt-1 text-gray-500 text-sm" ] ]
                [ li [] [ text ((project.tables |> S.pluralizeD "table") ++ ", " ++ (project.layouts |> S.pluralizeD "layout")) ]
                , li [] [ text ("Edited on " ++ formatDate zone project.createdAt) ]
                ]
            ]
        , div [ classes [ "flex divide-x divide-gray-200" ] ]
            [ button [ type_ "button", onClick (confirmDeleteProject project), classes [ "flex-grow-0 inline-flex items-center justify-center py-4 text-sm text-gray-700 font-medium px-4", hover "text-gray-500" ] ]
                [ Icon.outline Trash [ Tw.text_gray_400 ] |> toUnstyled ]
                |> Tooltip.t "Delete this project"
            , a ([ href (Route.toHref (Route.Projects__Id_ { id = project.id })), classes [ "flex-grow inline-flex items-center justify-center py-4 text-sm text-gray-700 font-medium", hover "text-gray-500" ] ] ++ track (Track.loadProject project))
                [ Icon.outline ArrowCircleRight [ Tw.text_gray_400 ] |> toUnstyled, span [ classes [ "ml-3" ] ] [ text "Open project" ] ]
            ]
        ]


confirmDeleteProject : Project -> Msg
confirmDeleteProject project =
    ConfirmOpen
        { color = Color.red
        , icon = Trash
        , title = "Delete project"
        , message = span [] [ text "Are you sure you want to delete ", bText project.name, text " project?" ] |> fromUnstyled
        , confirm = "Delete " ++ project.name
        , cancel = "Cancel"
        , onConfirm = T.send (DeleteProject project)
        }


viewNewProject : Html msg
viewNewProject =
    li [ classes [ "col-span-1" ] ]
        [ a [ href (Route.toHref Route.Projects__New), classes [ "relative block w-full border-2 border-gray-200 border-dashed rounded-lg py-12 text-center text-gray-200", hover "border-gray-400 text-gray-400", focusRing ( Conf.theme.color, 500 ) ( Color.white, 500 ) ] ]
            [ Icon.outline DocumentAdd [ Tw.mx_auto, Tw.h_12, Tw.w_12 ] |> toUnstyled
            , span [ classes [ "mt-2 block text-sm font-medium" ] ] [ text "Create a new project" ]
            ]
        ]


viewModal : Model -> Html Msg
viewModal model =
    div [ class "tw-modal", id Conf.ids.modal ]
        [ model.confirm
            |> Maybe.map
                (\c ->
                    Modal.confirm
                        { id = Conf.ids.confirmDialog
                        , icon = c.icon
                        , color = c.color
                        , title = c.title
                        , message = c.message |> toUnstyled
                        , confirm = c.confirm
                        , cancel = c.cancel
                        , onConfirm = ModalClose (ConfirmAnswer True c.onConfirm)
                        , onCancel = ModalClose (ConfirmAnswer False Cmd.none)
                        }
                        model.modalOpened
                )
            |> Maybe.withDefault (div [] [])
        ]
