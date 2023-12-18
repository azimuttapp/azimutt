module PagesComponents.Organization_.Project_.Views.Modals.NewLayout exposing (GlobalModel, Model, Msg(..), update, view)

import Components.Molecules.Modal as Modal
import Components.Slices.NewLayoutBody as NewLayoutBody
import Components.Slices.ProPlan as ProPlan
import Conf
import Dict
import Html exposing (Html)
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Task as T
import Models.Project.LayoutName exposing (LayoutName)
import Models.ProjectRef exposing (ProjectRef)
import Models.UrlInfos exposing (UrlInfos)
import PagesComponents.Organization_.Project_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Organization_.Project_.Models.ErdLayout as ErdLayout
import PagesComponents.Organization_.Project_.Updates.Utils exposing (setDirtyCmd)
import Services.Lenses exposing (mapErdMCmd, mapLayouts, mapNewLayoutMCmd, setCurrentLayout, setNewLayout)
import Services.Toasts as Toasts
import Time
import Track


dialogId : HtmlId
dialogId =
    "new-layout-dialog"


type alias GlobalModel x =
    { x
        | conf : ErdConf
        , dirty : Bool
        , erd : Maybe Erd
        , newLayout : Maybe Model
    }


type alias Model =
    NewLayoutBody.Model


type Msg
    = Open NewLayoutBody.Mode
    | BodyMsg NewLayoutBody.Msg
    | Submit NewLayoutBody.Mode LayoutName
    | Cancel


update : (HtmlId -> msg) -> (Toasts.Msg -> msg) -> ((msg -> String -> Html msg) -> msg) -> Time.Posix -> UrlInfos -> Msg -> GlobalModel x -> ( GlobalModel x, Cmd msg )
update modalOpen toast customModalOpen now urlInfos msg model =
    case msg of
        Open from ->
            if model.erd |> Erd.canCreateLayout then
                ( model |> setNewLayout (Just (NewLayoutBody.init dialogId from)), Cmd.batch [ T.sendAfter 1 (modalOpen dialogId) ] )

            else
                ( model
                , Cmd.batch
                    [ model.erd |> Erd.getProjectRefM urlInfos |> ProPlan.layoutsModalBody |> customModalOpen |> T.send
                    , Track.planLimit .layouts model.erd
                    ]
                )

        BodyMsg m ->
            model |> mapNewLayoutMCmd (NewLayoutBody.update m)

        Submit mode name ->
            model |> setNewLayout Nothing |> mapErdMCmd (updateLayouts toast mode name now) |> setDirtyCmd

        Cancel ->
            ( model |> setNewLayout Nothing, Cmd.none )


updateLayouts : (Toasts.Msg -> msg) -> NewLayoutBody.Mode -> LayoutName -> Time.Posix -> Erd -> ( Erd, Cmd msg )
updateLayouts toast mode name now erd =
    case mode of
        NewLayoutBody.Create ->
            createLayout toast Nothing name now erd

        NewLayoutBody.Duplicate from ->
            createLayout toast (Just from) name now erd

        NewLayoutBody.Rename from ->
            renameLayout toast from name erd


createLayout : (Toasts.Msg -> msg) -> Maybe LayoutName -> LayoutName -> Time.Posix -> Erd -> ( Erd, Cmd msg )
createLayout toast from name now erd =
    (erd.layouts |> Dict.get name)
        |> Maybe.mapOrElse
            (\_ -> ( erd, "Layout " ++ name ++ " already exists" |> Toasts.error |> toast |> T.send ))
            ((from |> Maybe.andThen (\f -> erd.layouts |> Dict.get f) |> Maybe.withDefault (ErdLayout.empty now))
                |> (\layout -> ( erd |> mapLayouts (Dict.insert name layout) |> setCurrentLayout name, Track.layoutCreated erd.project layout ))
            )


renameLayout : (Toasts.Msg -> msg) -> LayoutName -> LayoutName -> Erd -> ( Erd, Cmd msg )
renameLayout toast from name erd =
    (erd.layouts |> Dict.get from)
        |> Maybe.map (\l -> ( erd |> mapLayouts (Dict.remove from >> Dict.insert name l) |> setCurrentLayout name, Track.layoutRenamed erd.project l ))
        |> Maybe.withDefault ( erd, "Layout " ++ from ++ " does not exist" |> Toasts.error |> toast |> T.send )


view : (Msg -> msg) -> (msg -> msg) -> ProjectRef -> List LayoutName -> Bool -> Model -> Html msg
view wrap modalClose projectRef layouts opened model =
    let
        titleId : HtmlId
        titleId =
            model.id ++ "-title"
    in
    Modal.modal
        { id = model.id
        , titleId = titleId
        , isOpen = opened
        , onBackgroundClick = Cancel |> wrap |> modalClose
        }
        [ NewLayoutBody.view (BodyMsg >> wrap) (Submit model.mode >> wrap >> modalClose) (Cancel |> wrap |> modalClose) titleId layouts projectRef model
        ]
