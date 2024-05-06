module PagesComponents.Organization_.Project_.Components.ProjectSaveDialog exposing (Model, Msg(..), update, view)

import Components.Molecules.Modal as Modal
import Components.Slices.ProjectSaveDialogBody as ProjectSaveDialogBody
import Html exposing (Html)
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Task as T
import Libs.Url as Url
import Models.Organization exposing (Organization)
import Models.Project.ProjectName exposing (ProjectName)
import Models.Project.ProjectStorage exposing (ProjectStorage)
import Models.ProjectInfo exposing (ProjectInfo)
import Models.User exposing (User)
import PagesComponents.Organization_.Project_.Models.Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Updates.Extra as Extra exposing (Extra)
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


update : (HtmlId -> msg) -> Msg -> Maybe Model -> ( Maybe Model, Extra msg )
update modalOpen msg model =
    case msg of
        Open name orga ->
            ( ProjectSaveDialogBody.init dialogId name orga |> Just
            , modalOpen dialogId |> T.sendAfter 1 |> Extra.cmd
            )

        Close ->
            ( Nothing, Extra.none )

        BodyMsg m ->
            model |> Maybe.mapOrElse (ProjectSaveDialogBody.update m >> Tuple.mapFirst Just) ( model, Extra.none )


view : (Msg -> msg) -> (msg -> msg) -> (ProjectName -> Organization -> ProjectStorage -> msg) -> Url -> Maybe User -> List Organization -> List ProjectInfo -> Bool -> Erd -> Model -> Html msg
view wrap modalClose saveProject currentUrl user organizations projects opened erd model =
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
            |> Maybe.map (\_ -> ProjectSaveDialogBody.selectSave (BodyMsg >> wrap) close saveProject titleId organizations projects erd.project.name model)
            |> Maybe.withDefault (ProjectSaveDialogBody.signIn close (Backend.loginUrl (currentUrl |> Url.addQuery "save" "")) titleId)
        ]
