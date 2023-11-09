module PagesComponents.Organization_.Project_.Updates.Memo exposing (Model, handleMemo)

import Browser.Dom as Dom
import Components.Slices.ProPlan as ProPlan
import Conf
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Task as T
import Libs.Url exposing (UrlPath)
import Models.ErdProps exposing (ErdProps)
import Models.Position as Position
import Models.UrlInfos exposing (UrlInfos)
import PagesComponents.Organization_.Project_.Models exposing (MemoEdit, MemoMsg(..), Msg(..))
import PagesComponents.Organization_.Project_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Organization_.Project_.Models.ErdLayout as ErdLayout
import PagesComponents.Organization_.Project_.Models.Memo exposing (Memo)
import PagesComponents.Organization_.Project_.Models.MemoId as MemoId exposing (MemoId)
import PagesComponents.Organization_.Project_.Updates.Utils exposing (setDirty, setDirtyCmd)
import Ports
import Services.Lenses exposing (mapEditMemoM, mapErdM, mapMemos, mapMemosL, setColor, setContent, setEditMemo)
import Services.Toasts as Toasts
import Task
import Time
import Track


type alias Model x =
    { x
        | conf : ErdConf
        , erdElem : ErdProps
        , dirty : Bool
        , erd : Maybe Erd
        , editMemo : Maybe MemoEdit
    }


handleMemo : Time.Posix -> UrlPath -> UrlInfos -> MemoMsg -> Model x -> ( Model x, Cmd Msg )
handleMemo now basePath urlInfos msg model =
    case msg of
        MCreate pos ->
            model.erd |> Maybe.mapOrElse (\erd -> model |> createMemo now basePath pos urlInfos erd) ( model, Cmd.none )

        MEdit memo ->
            model |> editMemo False memo

        MEditUpdate content ->
            ( model |> mapEditMemoM (setContent content), Cmd.none )

        MEditSave ->
            model.editMemo |> Maybe.mapOrElse (\edit -> model |> saveMemo now edit) ( model, "No memo to save" |> Toasts.create "warning" |> Toast |> T.send )

        MSetColor id color ->
            model |> mapErdM (Erd.mapCurrentLayoutWithTime now (mapMemosL .id id (setColor color))) |> setDirty

        MDelete id ->
            model |> deleteMemo now id False


createMemo : Time.Posix -> UrlPath -> Position.Canvas -> UrlInfos -> Erd -> Model x -> ( Model x, Cmd Msg )
createMemo now basePath position urlInfos erd model =
    if model.erd |> Erd.canCreateMemo then
        ErdLayout.createMemo (erd |> Erd.currentLayout) position
            |> (\memo ->
                    model
                        |> mapErdM (Erd.mapCurrentLayoutWithTime now (mapMemos (List.append [ memo ])))
                        |> editMemo True memo
                        |> Tuple.mapSecond (\cmd -> Cmd.batch [ cmd, Ports.observeMemoSize memo.id ])
               )

    else
        ( model, Cmd.batch [ erd |> Erd.getProjectRef urlInfos |> ProPlan.memosModalBody basePath |> CustomModalOpen |> T.send, Track.planLimit .memos (Just erd) ] )


editMemo : Bool -> Memo -> Model x -> ( Model x, Cmd Msg )
editMemo createMode memo model =
    ( model |> setEditMemo (Just { id = memo.id, content = memo.content, createMode = createMode }), memo.id |> MemoId.toInputId |> Dom.focus |> Task.attempt (\_ -> Noop "focus-memo-input") )


saveMemo : Time.Posix -> MemoEdit -> Model x -> ( Model x, Cmd Msg )
saveMemo now edit model =
    let
        memoContent : String
        memoContent =
            model.erd |> Maybe.andThen (\erd -> erd |> Erd.currentLayout |> .memos |> List.findBy .id edit.id) |> Maybe.mapOrElse .content ""
    in
    if String.trim edit.content == "" then
        model |> setEditMemo Nothing |> deleteMemo now edit.id edit.createMode

    else if edit.content == memoContent then
        -- no change, don't save
        ( model |> setEditMemo Nothing, Cmd.none )

    else
        ( model |> setEditMemo Nothing |> mapErdM (Erd.mapCurrentLayoutWithTime now (mapMemosL .id edit.id (setContent edit.content))), Track.memoSaved edit.createMode edit.content model.erd ) |> setDirtyCmd


deleteMemo : Time.Posix -> MemoId -> Bool -> Model x -> ( Model x, Cmd Msg )
deleteMemo now id createMode model =
    model
        |> mapErdM (Erd.mapCurrentLayoutWithTime now (mapMemos (List.filter (\m -> m.id /= id))))
        |> (\m ->
                if createMode then
                    ( m, Cmd.none )

                else
                    ( m, Track.memoDeleted model.erd ) |> setDirtyCmd
           )
