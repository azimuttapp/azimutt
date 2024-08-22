module PagesComponents.Organization_.Project_.Components.LlmGenerateSqlDialog exposing (Model, Msg(..), init, update, view)

import Components.Molecules.Modal as Modal
import Components.Slices.LlmGenerateSqlBody as LlmGenerateSqlBody
import Html exposing (Html)
import Libs.Bool as Bool
import Libs.List as List
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Task as T
import Models.Feature as Feature
import Models.Organization as Organization
import Models.Project.SourceId exposing (SourceId)
import Models.ProjectRef exposing (ProjectRef)
import Models.SqlQuery exposing (SqlQueryOrigin)
import PagesComponents.Organization_.Project_.Models.Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Updates.Extra as Extra exposing (Extra)
import Services.Lenses exposing (mapBodyT, mapMT)
import Shared exposing (Prompt)
import Track


dialogId : HtmlId
dialogId =
    "llm-generate-sql"


type alias Model =
    { id : HtmlId, body : LlmGenerateSqlBody.Model }


type Msg
    = Open (Maybe SourceId)
    | Close
    | BodyMsg LlmGenerateSqlBody.Msg


init : Erd -> Maybe SourceId -> Model
init erd source =
    { id = dialogId, body = LlmGenerateSqlBody.init dialogId erd source }


update : (HtmlId -> msg) -> (Prompt msg -> String -> msg) -> (String -> msg) -> ProjectRef -> Erd -> Msg -> Maybe Model -> ( Maybe Model, Extra msg )
update modalOpen openPrompt updateLlmKey projectRef erd msg model =
    case msg of
        Open source ->
            ( Just (init erd source)
            , [ modalOpen dialogId |> T.sendAfter 1
              , source |> Maybe.andThen (\id -> erd.sources |> List.findBy .id id) |> Track.generateSqlOpened erd.project
              ]
                ++ Bool.cond (Organization.canUseAi projectRef) [] [ Track.planLimit Feature.ai (Just erd) ]
                |> Extra.cmdL
            )

        Close ->
            ( Nothing, Extra.none )

        BodyMsg message ->
            model |> mapMT (mapBodyT (LlmGenerateSqlBody.update openPrompt updateLlmKey erd message >> Tuple.mapSecond Extra.cmd)) |> Extra.defaultT


view : (Msg -> msg) -> (Cmd msg -> msg) -> (List msg -> msg) -> (String -> msg) -> (SourceId -> SqlQueryOrigin -> msg) -> (msg -> msg) -> Bool -> ProjectRef -> Erd -> Model -> Html msg
view wrap send batch toastSuccess openDataExplorer modalClose opened projectRef erd model =
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
        [ LlmGenerateSqlBody.view (BodyMsg >> wrap) send batch toastSuccess openDataExplorer (Close |> wrap |> modalClose) titleId projectRef erd model.body
        ]
