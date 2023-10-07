module PagesComponents.Organization_.Project_.Components.ProjectSaveDialog exposing (Model, Msg(..), update, view)

import Components.Molecules.Modal as Modal
import Components.Slices.ProjectSaveDialogBody as ProjectSaveDialogBody
import Html exposing (Html)
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Task as T
import Libs.Url as Url exposing (UrlPath)
import Models.Organization exposing (Organization)
import Models.Project.ProjectName exposing (ProjectName)
import Models.Project.ProjectStorage exposing (ProjectStorage)
import Models.User exposing (User)
import PagesComponents.Organization_.Project_.Models.Erd exposing (Erd)
import Services.Backend as Backend
import Url exposing (Url)


dialogId : HtmlId
dialogId =
    "project-save-dialog"


type alias Model =
    ProjectSaveDialogBody.Model


type Msg
    = Open ProjectName (Maybe Organization)
    | Close
    | BodyMsg ProjectSaveDialogBody.Msg


update : (HtmlId -> msg) -> Msg -> Maybe Model -> ( Maybe Model, Cmd msg )
update modalOpen msg model =
    case msg of
        Open name orga ->
            ( ProjectSaveDialogBody.init dialogId name orga |> Just
            , Cmd.batch [ T.sendAfter 1 (modalOpen dialogId) ]
            )

        Close ->
            ( Nothing, Cmd.none )

        BodyMsg m ->
            model |> Maybe.mapOrElse (ProjectSaveDialogBody.update m >> Tuple.mapFirst Just) ( model, Cmd.none )


view : (Msg -> msg) -> (msg -> msg) -> (ProjectName -> Organization -> ProjectStorage -> msg) -> UrlPath -> Url -> Maybe User -> List Organization -> Bool -> Erd -> Model -> Html msg
view wrap modalClose saveProject basePath currentUrl user organizations opened erd model =
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
            |> Maybe.map (\_ -> ProjectSaveDialogBody.selectSave (BodyMsg >> wrap) close saveProject titleId organizations erd.project.name model)
            |> Maybe.withDefault (ProjectSaveDialogBody.signIn close (Backend.loginUrl basePath (currentUrl |> Url.addQuery "save" "")) titleId)
        ]
