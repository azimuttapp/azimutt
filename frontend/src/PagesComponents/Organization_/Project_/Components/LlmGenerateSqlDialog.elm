module PagesComponents.Organization_.Project_.Components.LlmGenerateSqlDialog exposing (Model, Msg(..), init, update, view)

import Components.Molecules.Modal as Modal
import Components.Slices.LlmGenerateSqlBody as LlmGenerateSqlBody
import Html exposing (Html)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Task as T
import Models.Project.SourceId exposing (SourceId)
import Models.SqlQuery exposing (SqlQueryOrigin)
import PagesComponents.Organization_.Project_.Models.Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Updates.Extra as Extra exposing (Extra)
import Services.Lenses exposing (mapBodyT, mapMT)
import Shared exposing (Prompt)


dialogId : HtmlId
dialogId =
    "generate-sql"


type alias Model =
    { id : HtmlId, body : LlmGenerateSqlBody.Model }


type Msg
    = Open (Maybe SourceId)
    | Close
    | BodyMsg LlmGenerateSqlBody.Msg


init : Erd -> Maybe SourceId -> Model
init erd source =
    { id = dialogId, body = LlmGenerateSqlBody.init dialogId erd source }


update : (HtmlId -> msg) -> (Prompt msg -> String -> msg) -> (String -> msg) -> Erd -> Msg -> Maybe Model -> ( Maybe Model, Extra msg )
update modalOpen openPrompt updateLlmKey erd msg model =
    case msg of
        Open source ->
            ( Just (init erd source), modalOpen dialogId |> T.sendAfter 1 |> Extra.cmd )

        Close ->
            ( Nothing, Extra.none )

        BodyMsg message ->
            model |> mapMT (mapBodyT (LlmGenerateSqlBody.update openPrompt updateLlmKey erd message >> Tuple.mapSecond Extra.cmd)) |> Extra.defaultT


view : (Msg -> msg) -> (List msg -> msg) -> (SourceId -> SqlQueryOrigin -> msg) -> (msg -> msg) -> Bool -> Model -> Html msg
view wrap batch openDataExplorer modalClose opened model =
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
        [ LlmGenerateSqlBody.view (BodyMsg >> wrap) batch openDataExplorer (Close |> wrap |> modalClose) titleId model.body
        ]
