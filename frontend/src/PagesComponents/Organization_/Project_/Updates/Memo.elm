module PagesComponents.Organization_.Project_.Updates.Memo exposing (Model, handleMemo)

import Browser.Dom as Dom
import Libs.Task as T
import Models.ErdProps exposing (ErdProps)
import PagesComponents.Organization_.Project_.Models exposing (MemoEdit, MemoMsg(..), Msg(..))
import PagesComponents.Organization_.Project_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Organization_.Project_.Models.ErdLayout as ErdLayout
import PagesComponents.Organization_.Project_.Models.MemoId as MemoId
import PagesComponents.Organization_.Project_.Updates.Utils exposing (setDirty)
import Services.Lenses exposing (mapEditMemoM, mapErdM, mapMemos, mapMemosL, setContent, setEditMemo)
import Services.Toasts as Toasts
import Task
import Time


type alias Model x =
    { x
        | conf : ErdConf
        , erdElem : ErdProps
        , dirty : Bool
        , erd : Maybe Erd
        , editMemo : Maybe MemoEdit
    }


handleMemo : Time.Posix -> MemoMsg -> Model x -> ( Model x, Cmd Msg )
handleMemo now msg model =
    case msg of
        MCreate e ->
            model |> mapErdM (Erd.mapCurrentLayoutWithTime now (\l -> l |> mapMemos (List.append [ e |> ErdLayout.createMemo model.erdElem l ]))) |> setDirty

        MEdit m ->
            ( model |> setEditMemo (Just { id = m.id, content = m.content }), m.id |> MemoId.toHtmlId |> Dom.focus |> Task.attempt (\_ -> Noop "focus-memo-input") )

        MUpdate content ->
            ( model |> mapEditMemoM (setContent content), Cmd.none )

        MSave ->
            model.editMemo
                |> Maybe.map (\memo -> model |> setEditMemo Nothing |> mapErdM (Erd.mapCurrentLayoutWithTime now (mapMemosL .id memo.id (setContent memo.content))) |> setDirty)
                |> Maybe.withDefault ( model, "No memo to save" |> Toasts.create "warning" |> Toast |> T.send )

        MCancel ->
            ( model |> setEditMemo Nothing, Cmd.none )
