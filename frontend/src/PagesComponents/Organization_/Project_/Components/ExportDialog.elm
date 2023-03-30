module PagesComponents.Organization_.Project_.Components.ExportDialog exposing (Model, Msg(..), init, update, view)

import Components.Molecules.Modal as Modal
import Components.Slices.ExportDialogBody as ExportDialogBody
import Html exposing (Html)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Task as T
import Models.Organization exposing (Organization)
import Models.OrganizationId exposing (OrganizationId)
import PagesComponents.Organization_.Project_.Models.Erd exposing (Erd)
import Services.Lenses exposing (mapBodyCmd, mapMCmd)


dialogId : HtmlId
dialogId =
    "export-dialog"


type alias Model =
    { id : HtmlId, body : ExportDialogBody.Model }


type Msg
    = Open
    | Close
    | BodyMsg ExportDialogBody.Msg


init : Model
init =
    { id = dialogId, body = ExportDialogBody.init dialogId }


update : (Msg -> msg) -> (HtmlId -> msg) -> Maybe OrganizationId -> Erd -> Msg -> Maybe Model -> ( Maybe Model, Cmd msg )
update wrap modalOpen urlOrganization erd msg model =
    case msg of
        Open ->
            ( Just init, Cmd.batch [ T.sendAfter 1 (modalOpen dialogId) ] )

        Close ->
            ( Nothing, Cmd.none )

        BodyMsg message ->
            model |> mapMCmd (mapBodyCmd (ExportDialogBody.update (BodyMsg >> wrap) urlOrganization erd message))


view : (Msg -> msg) -> (Cmd msg -> msg) -> (msg -> msg) -> Bool -> Organization -> Model -> Html msg
view wrap send modalClose opened organization model =
    let
        titleId : HtmlId
        titleId =
            model.id ++ "-title"
    in
    Modal.modal
        { id = model.id
        , titleId = titleId
        , isOpen = opened
        , onBackgroundClick = Close |> wrap |> modalClose
        }
        [ ExportDialogBody.view (BodyMsg >> wrap) send (Close |> wrap |> modalClose) titleId organization model.body
        ]
