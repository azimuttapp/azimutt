module PagesComponents.Projects.Id_.Components.ProjectUploadDialog exposing (Model, Msg(..), update, view)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Atoms.Link as Link
import Components.Molecules.Alert as Alert
import Components.Molecules.Modal as Modal
import Components.Molecules.Tooltip as Tooltip
import Html exposing (Html, br, div, h3, p, text)
import Html.Attributes exposing (class, disabled, href, id)
import Html.Events exposing (onClick)
import Libs.Bool as Bool
import Libs.Html exposing (bText)
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Tailwind as Tw
import Libs.Task as T
import Models.Project.ProjectId as ProjectId
import Models.Project.ProjectStorage as ProjectStorage exposing (ProjectStorage)
import Models.User exposing (User)
import Models.User2 exposing (User2)
import PagesComponents.Projects.Id_.Components.ProjectTeam as ProjectTeam
import PagesComponents.Projects.Id_.Models.Erd exposing (Erd)
import PagesComponents.Projects.Id_.Models.ProjectInfo exposing (ProjectInfo)
import Ports
import Router
import Services.Lenses exposing (mapMTeamCmd)
import Shared exposing (Confirm)
import Track
import Url exposing (Url)


dialogId : HtmlId
dialogId =
    "project-upload-dialog"


type alias Model =
    { id : HtmlId
    , movingProject : Bool
    , team : ProjectTeam.Model
    }


type Msg
    = Open
    | Close
    | ProjectTeamMsg ProjectTeam.Msg


update : (HtmlId -> msg) -> Maybe Erd -> Msg -> Maybe Model -> ( Maybe Model, Cmd msg )
update modalOpen erd msg model =
    case msg of
        Open ->
            ( Just { id = dialogId, movingProject = False, team = ProjectTeam.init }
            , Cmd.batch
                ([ T.sendAfter 1 (modalOpen dialogId), Ports.track Track.openProjectUploadDialog ]
                    ++ (erd |> Maybe.mapOrElse (\e -> Bool.cond (e.project.storage == ProjectStorage.Azimutt) [ Ports.getOwners e.project.id ] []) [])
                )
            )

        Close ->
            ( Nothing, Cmd.none )

        ProjectTeamMsg message ->
            model |> mapMTeamCmd (ProjectTeam.update message)


view : (Confirm msg -> msg) -> Cmd msg -> (Msg -> msg) -> (ProjectStorage -> msg) -> (msg -> msg) -> Url -> Maybe User2 -> Bool -> ProjectInfo -> Model -> Html msg
view confirm onDelete wrap moveProject modalClose currentUrl user opened project model =
    let
        titleId : HtmlId
        titleId =
            model.id ++ "-title"

        close : msg
        close =
            Close |> wrap |> modalClose
    in
    Modal.modal
        { id = model.id
        , titleId = titleId
        , isOpen = opened
        , onBackgroundClick = close
        }
        [ user
            |> Maybe.mapOrElse
                (\u ->
                    if project.storage == ProjectStorage.Local then
                        uploadModal close moveProject titleId model.movingProject project

                    else
                        cloudModal confirm onDelete wrap moveProject model.id titleId u model.team model.movingProject project
                )
                (signInModal close currentUrl titleId project)
        ]


signInModal : msg -> Url -> HtmlId -> ProjectInfo -> Html msg
signInModal modalClose currentUrl titleId project =
    div [ class "px-4 pt-5 pb-4 sm:max-w-md sm:p-6" ]
        [ div []
            [ div [ class "mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-emerald-100" ]
                [ Icon.outline CloudUpload "text-emerald-600"
                ]
            , div [ class "mt-3 text-center sm:mt-5" ]
                [ h3 [ id titleId, class "text-lg leading-6 font-medium text-gray-900" ]
                    [ text ("Sign in to sync " ++ project.name) ]
                , div [ class "mt-2" ]
                    [ p [ class "text-sm text-gray-500" ]
                        [ text "Azimutt has "
                        , bText "upgraded"
                        , text "! You can now create an account and privately upload your diagram. After that, you will be able to find it anywhere and even share it with your colleagues."
                        ]
                    ]
                ]
            ]
        , div [ class "mt-5 sm:mt-6 sm:grid sm:grid-cols-2 sm:gap-3 sm:grid-flow-row-dense" ]
            [ Button.white3 Tw.default [ onClick modalClose ] [ text "No thanks" ]
            , Link.primary3 Tw.emerald [ href (Router.login currentUrl), class "w-full" ] [ text "Sign in to sync" ]
            ]
        ]


uploadModal : msg -> (ProjectStorage -> msg) -> HtmlId -> Bool -> ProjectInfo -> Html msg
uploadModal modalClose moveProjectTo titleId movingProject project =
    div [ class "px-4 pt-5 pb-4 sm:max-w-md sm:p-6" ]
        [ div []
            [ div [ class "mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-emerald-100" ]
                [ Icon.outline CloudUpload "text-emerald-600"
                ]
            , div [ class "mt-3 text-center sm:mt-5" ]
                [ h3 [ id titleId, class "text-lg leading-6 font-medium text-gray-900" ]
                    [ text ("Sync " ++ project.name ++ " in your account") ]
                , div [ class "mt-2" ]
                    [ p [ class "text-sm text-gray-500" ]
                        [ text "With Azimutt sync you can access your project from anywhere and anytime, privately. But this is just a start, you can already "
                        , bText "share it with your colleagues"
                        , text "."
                        ]
                    , div [ class "mt-5" ] [ Alert.simple Tw.blue InformationCircle [ text "This is a BETA feature. It's here so you can try it but it may change at any time." ] ]
                    ]
                ]
            ]
        , div [ class "mt-5 sm:grid sm:grid-cols-2 sm:gap-3 sm:grid-flow-row-dense" ]
            [ Button.white3 Tw.default [ onClick modalClose ] [ text "No thanks" ]
            , if movingProject then
                Button.primary3 Tw.emerald [ disabled True ] [ Icon.loading "animate-spin mr-3", text "Upload to Azimutt" ]

              else if ProjectId.isSample project.id then
                Button.primary3 Tw.emerald [ disabled True ] [ text "Can't upload samples" ]

              else
                Button.primary3 Tw.emerald [ onClick (moveProjectTo ProjectStorage.Azimutt) ] [ text "Upload to Azimutt" ]
            ]
        , p [ class "mt-2 text-xs text-right text-gray-500" ] [ text "You can revert this decision at any time." ]
        ]


cloudModal : (Confirm msg -> msg) -> Cmd msg -> (Msg -> msg) -> (ProjectStorage -> msg) -> HtmlId -> HtmlId -> User2 -> ProjectTeam.Model -> Bool -> ProjectInfo -> Html msg
cloudModal confirm onDelete wrap moveProject htmlId titleId user team movingProject project =
    div [ class "px-4 pt-5 pb-4 sm:max-w-3xl sm:p-6" ]
        [ div []
            [ div [ class "mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-emerald-100" ]
                [ Icon.outline Cloud "text-emerald-600"
                ]
            , div [ class "mt-3 sm:mt-5" ]
                [ h3 [ id titleId, class "text-lg text-center leading-6 font-medium text-gray-900" ]
                    [ text (project.name ++ " is stored in Azimutt 👍️") ]
                ]
            , div [ class "mt-8" ]
                [ ProjectTeam.view confirm onDelete (ProjectTeamMsg >> wrap) htmlId user project team
                ]
            ]
        , div [ class "mt-3 w-full border-t border-gray-300" ] []
        , moveToLocal moveProject movingProject team.owners
        ]


moveToLocal : (ProjectStorage -> msg) -> Bool -> List User -> Html msg
moveToLocal moveProjectTo movingProject owners =
    div [ class "mt-2 sm:flex sm:justify-between" ]
        [ div [ class "max-w-xl text-sm text-gray-500" ]
            [ p [] [ text "You can bring back your project to local storage only.", br [] [], text "Your project will be saved in your browser and then deleted from Azimutt servers." ]
            ]
        , div [ class "mt-5 sm:mt-0 sm:ml-6 sm:flex-shrink-0 sm:flex sm:items-center" ]
            [ if List.length owners > 1 then
                Button.primary1 Tw.red [ disabled True ] [ text "Go local only" ] |> Tooltip.tl "You need to remove all other owners before you can go local."

              else if movingProject then
                Button.primary1 Tw.red [ disabled True ] [ Icon.loading "animate-spin mr-3", text "Go local only" ]

              else
                Button.primary1 Tw.red [ onClick (moveProjectTo ProjectStorage.Local), class "ml-8" ] [ text "Go local only" ]
            ]
        ]
