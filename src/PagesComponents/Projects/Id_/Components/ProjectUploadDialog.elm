module PagesComponents.Projects.Id_.Components.ProjectUploadDialog exposing (close, open, update, view)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Atoms.Link as Link
import Components.Molecules.Modal as Modal
import Components.Molecules.Tooltip as Tooltip
import Gen.Route as Route
import Html exposing (Html, br, div, h3, p, text)
import Html.Attributes exposing (class, disabled, href, id, value)
import Html.Events exposing (onClick)
import Libs.Bool as Bool
import Libs.Html exposing (bText)
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Tailwind as Tw
import Libs.Task as T
import Models.Project.ProjectStorage as ProjectStorage
import Models.User exposing (User)
import PagesComponents.Projects.Id_.Components.ProjectTeam as ProjectTeam
import PagesComponents.Projects.Id_.Models exposing (Msg(..), ProjectUploadDialog, ProjectUploadDialogMsg(..))
import PagesComponents.Projects.Id_.Models.Erd exposing (Erd)
import PagesComponents.Projects.Id_.Models.ProjectInfo exposing (ProjectInfo)
import Ports
import Router
import Track


dialogId : HtmlId
dialogId =
    "project-upload-dialog"


open : Msg
open =
    ProjectUploadDialogMsg PUOpen


close : Msg
close =
    ProjectUploadDialogMsg PUClose |> ModalClose


update : Maybe Erd -> ProjectUploadDialogMsg -> Maybe ProjectUploadDialog -> ( Maybe ProjectUploadDialog, Cmd Msg )
update erd msg model =
    case msg of
        PUOpen ->
            ( Just { id = dialogId, shareInput = "", shareUser = Nothing, owners = [] }
            , Cmd.batch
                ([ T.sendAfter 1 (ModalOpen dialogId), Ports.track Track.openProjectUploadDialog ]
                    ++ (erd |> Maybe.mapOrElse (\e -> Bool.cond (e.project.storage == ProjectStorage.Cloud) [ Ports.getOwners e.project.id ] []) [])
                )
            )

        PUClose ->
            ( Nothing, Cmd.none )

        PUShareUpdate value ->
            ( model |> Maybe.map (\m -> { m | shareInput = value }), Cmd.none )


view : Maybe User -> Bool -> ProjectInfo -> ProjectUploadDialog -> Html Msg
view user opened project model =
    let
        titleId : HtmlId
        titleId =
            model.id ++ "-title"
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
                    if project.storage == ProjectStorage.Browser then
                        uploadModal titleId project

                    else
                        cloudModal model.id titleId u model.shareInput model.shareUser model.owners project
                )
                (signInModal titleId project)
        ]


signInModal : HtmlId -> ProjectInfo -> Html Msg
signInModal titleId project =
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
            [ Button.white3 Tw.default [ onClick close ] [ text "No thanks" ]
            , Link.primary3 Tw.emerald [ href (Router.login (Route.Projects__Id_ { id = project.id })), class "w-full" ] [ text "Sign in to sync" ]
            ]
        ]


uploadModal : HtmlId -> ProjectInfo -> Html Msg
uploadModal titleId project =
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
                    ]
                ]
            ]
        , div [ class "mt-5 sm:mt-6 sm:grid sm:grid-cols-2 sm:gap-3 sm:grid-flow-row-dense" ]
            [ Button.white3 Tw.default [ onClick close ] [ text "No thanks" ]
            , Button.primary3 Tw.emerald [ onClick (MoveProjectTo ProjectStorage.Cloud) ] [ text "Upload to Azimutt" ]
            ]
        , p [ class "mt-2 text-xs text-right text-gray-500" ] [ text "You can revert this decision at any time." ]
        ]


cloudModal : HtmlId -> HtmlId -> User -> String -> Maybe ( String, Maybe User ) -> List User -> ProjectInfo -> Html Msg
cloudModal htmlId titleId user shareInput shareUser owners project =
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
                [ ProjectTeam.view htmlId user shareInput shareUser owners project
                ]
            ]
        , div [ class "mt-3 w-full border-t border-gray-300" ] []
        , moveToLocal owners
        ]


moveToLocal : List User -> Html Msg
moveToLocal owners =
    div [ class "mt-2 sm:flex sm:justify-between" ]
        [ div [ class "max-w-xl text-sm text-gray-500" ]
            [ p [] [ text "You can bring back your project to local storage only.", br [] [], text "Your project will be saved in your browser and then deleted from Azimutt servers." ]
            ]
        , div [ class "mt-5 sm:mt-0 sm:ml-6 sm:flex-shrink-0 sm:flex sm:items-center" ]
            [ if List.length owners > 1 then
                Button.primary1 Tw.red [ disabled True ] [ text "Go local only" ] |> Tooltip.tl "You need to remove all other owners before you can go local."

              else
                Button.primary1 Tw.red [ onClick (MoveProjectTo ProjectStorage.Browser) ] [ text "Go local only" ]
            ]
        ]
