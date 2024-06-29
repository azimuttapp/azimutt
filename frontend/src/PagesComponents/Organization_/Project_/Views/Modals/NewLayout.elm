module PagesComponents.Organization_.Project_.Views.Modals.NewLayout exposing (GlobalModel, Model, Msg(..), update, view)

import Components.Molecules.Modal as Modal
import Components.Slices.NewLayoutBody as NewLayoutBody
import Components.Slices.ProPlan as ProPlan
import Dict
import Html exposing (Html)
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Task as T
import Models.Feature as Feature
import Models.Project.LayoutName exposing (LayoutName)
import Models.ProjectRef exposing (ProjectRef)
import Models.UrlInfos exposing (UrlInfos)
import PagesComponents.Organization_.Project_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Organization_.Project_.Models.ErdLayout as ErdLayout
import PagesComponents.Organization_.Project_.Updates.Extra as Extra exposing (Extra)
import PagesComponents.Organization_.Project_.Updates.Utils exposing (setDirtyM)
import Services.Lenses exposing (mapErdMT, mapLayouts, mapNewLayoutMT, setCurrentLayout, setNewLayout)
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


update : (Msg -> msg) -> (List msg -> msg) -> (HtmlId -> msg) -> (Toasts.Msg -> msg) -> ((msg -> String -> Html msg) -> msg) -> (LayoutName -> msg) -> (LayoutName -> msg) -> Time.Posix -> UrlInfos -> Msg -> GlobalModel x -> ( GlobalModel x, Extra msg )
update wrap batch modalOpen toast customModalOpen loadLayout deleteLayout now urlInfos msg model =
    case msg of
        Open from ->
            if model.erd |> Erd.canCreateLayout then
                ( model |> setNewLayout (Just (NewLayoutBody.init dialogId from)), modalOpen dialogId |> T.sendAfter 1 |> Extra.cmd )

            else
                ( model, Extra.cmdL [ model.erd |> Erd.getProjectRefM urlInfos |> ProPlan.layoutsModalBody |> customModalOpen |> T.send, Track.planLimit Feature.projectLayouts model.erd ] )

        BodyMsg m ->
            model |> mapNewLayoutMT (NewLayoutBody.update m) |> Extra.defaultT

        Submit mode name ->
            model |> setNewLayout Nothing |> mapErdMT (updateLayouts wrap batch toast loadLayout deleteLayout mode name now) |> setDirtyM

        Cancel ->
            ( model |> setNewLayout Nothing, Extra.none )


updateLayouts : (Msg -> msg) -> (List msg -> msg) -> (Toasts.Msg -> msg) -> (LayoutName -> msg) -> (LayoutName -> msg) -> NewLayoutBody.Mode -> LayoutName -> Time.Posix -> Erd -> ( Erd, Extra msg )
updateLayouts wrap batch toast loadLayout deleteLayout mode name now erd =
    case mode of
        NewLayoutBody.Create ->
            createLayout wrap batch toast loadLayout deleteLayout Nothing name now erd

        NewLayoutBody.Duplicate from ->
            createLayout wrap batch toast loadLayout deleteLayout (Just from) name now erd

        NewLayoutBody.Rename from ->
            renameLayout wrap toast from name erd


createLayout : (Msg -> msg) -> (List msg -> msg) -> (Toasts.Msg -> msg) -> (LayoutName -> msg) -> (LayoutName -> msg) -> Maybe LayoutName -> LayoutName -> Time.Posix -> Erd -> ( Erd, Extra msg )
createLayout wrap batch toast loadLayout deleteLayout from name now erd =
    (erd.layouts |> Dict.get name)
        |> Maybe.map (\_ -> ( erd, "'" ++ name ++ "' layout already exists" |> Toasts.error |> toast |> Extra.msg ))
        |> Maybe.withDefault
            ((from |> Maybe.andThen (\f -> erd.layouts |> Dict.get f) |> Maybe.withDefault (ErdLayout.empty now))
                |> (\layout ->
                        ( erd |> mapLayouts (Dict.insert name layout) |> setCurrentLayout name
                        , Extra.new
                            (Track.layoutCreated erd.project layout)
                            ( batch [ deleteLayout name, loadLayout erd.currentLayout ], wrap (Submit (from |> Maybe.mapOrElse NewLayoutBody.Duplicate NewLayoutBody.Create) name) )
                        )
                   )
            )


renameLayout : (Msg -> msg) -> (Toasts.Msg -> msg) -> LayoutName -> LayoutName -> Erd -> ( Erd, Extra msg )
renameLayout wrap toast from name erd =
    (erd.layouts |> Dict.get from)
        |> Maybe.map
            (\l ->
                ( erd |> mapLayouts (Dict.remove from >> Dict.insert name l) |> setCurrentLayout name
                , Extra.new (Track.layoutRenamed erd.project l) ( wrap (Submit (NewLayoutBody.Rename name) from), wrap (Submit (NewLayoutBody.Rename from) name) )
                )
            )
        |> Maybe.withDefault ( erd, "'" ++ from ++ "' layout does not exist" |> Toasts.error |> toast |> Extra.msg )


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
