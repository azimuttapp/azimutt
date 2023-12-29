module PagesComponents.Organization_.Project_.Updates.Memo exposing (Model, handleMemo)

import Browser.Dom as Dom
import Components.Slices.ProPlan as ProPlan
import Conf
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Task as T
import Libs.Tuple as Tuple
import Models.ErdProps exposing (ErdProps)
import Models.Position as Position
import Models.UrlInfos exposing (UrlInfos)
import PagesComponents.Organization_.Project_.Models exposing (MemoEdit, MemoMsg(..), Msg(..))
import PagesComponents.Organization_.Project_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Organization_.Project_.Models.ErdLayout as ErdLayout exposing (ErdLayout)
import PagesComponents.Organization_.Project_.Models.Memo exposing (Memo)
import PagesComponents.Organization_.Project_.Models.MemoId as MemoId exposing (MemoId)
import PagesComponents.Organization_.Project_.Updates.Utils exposing (setHDirtyCmd, setHLDirty, setHLDirtyCmd)
import Ports
import Services.Lenses exposing (mapColorT, mapContentT, mapEditMemoM, mapErdM, mapErdMT, mapErdMTM, mapMemos, mapMemosLT, mapMemosLTL, mapMemosT, setContent, setEditMemo)
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


handleMemo : Time.Posix -> UrlInfos -> MemoMsg -> Model x -> ( Model x, Cmd Msg, List ( Msg, Msg ) )
handleMemo now urlInfos msg model =
    case msg of
        MCreate pos ->
            model.erd |> Maybe.mapOrElse (\erd -> model |> createMemo now pos urlInfos erd |> Tuple.append []) ( model, Cmd.none, [] )

        MEdit memo ->
            model |> editMemo False memo |> Tuple.append []

        MEditUpdate content ->
            ( model |> mapEditMemoM (setContent content), Cmd.none, [] )

        MEditSave edit ->
            model |> saveMemo now edit

        MSetColor id color ->
            model |> mapErdMT (Erd.mapCurrentLayoutTLWithTime now (mapMemosLTL .id id (mapColorT (\c -> ( color, [ ( MemoMsg (MSetColor id c), MemoMsg (MSetColor id color) ) ] ))))) |> setHLDirty

        MDelete id ->
            model |> deleteMemo now id False

        MUnDelete memo ->
            ( model |> mapErdM (Erd.mapCurrentLayoutWithTime now (mapMemos (List.append [ memo ] >> List.sortBy .id))), Ports.observeMemoSize memo.id, [] )


createMemo : Time.Posix -> Position.Grid -> UrlInfos -> Erd -> Model x -> ( Model x, Cmd Msg )
createMemo now position urlInfos erd model =
    if model.erd |> Erd.canCreateMemo then
        ErdLayout.createMemo (erd |> Erd.currentLayout) position
            |> (\memo ->
                    model
                        |> mapErdM (Erd.mapCurrentLayoutWithTime now (mapMemos (List.append [ memo ] >> List.sortBy .id)))
                        |> editMemo True memo
                        |> Tuple.mapSecond (\cmd -> Cmd.batch [ cmd, Ports.observeMemoSize memo.id ])
               )

    else
        ( model, Cmd.batch [ erd |> Erd.getProjectRef urlInfos |> ProPlan.memosModalBody |> CustomModalOpen |> T.send, Track.planLimit .memos (Just erd) ] )


editMemo : Bool -> Memo -> Model x -> ( Model x, Cmd Msg )
editMemo createMode memo model =
    ( model |> setEditMemo (Just { id = memo.id, content = memo.content, createMode = createMode }), memo.id |> MemoId.toInputId |> Dom.focus |> Task.attempt (\_ -> Noop "focus-memo-input") )


saveMemo : Time.Posix -> MemoEdit -> Model x -> ( Model x, Cmd Msg, List ( Msg, Msg ) )
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
        ( model |> setEditMemo Nothing, Cmd.none, [] )

    else
        model
            |> setEditMemo Nothing
            |> mapErdMTM
                (Erd.mapCurrentLayoutTMWithTime now
                    (mapMemosLT .id
                        edit.id
                        (\memo ->
                            memo
                                |> mapContentT
                                    (\c ->
                                        ( edit.content
                                        , ( Track.memoSaved edit.createMode edit.content model.erd
                                          , if edit.createMode then
                                                [ ( MemoMsg (MDelete edit.id), MemoMsg (MUnDelete { memo | content = edit.content }) ) ]

                                            else
                                                [ ( MemoMsg (MEditSave { edit | content = c }), MemoMsg (MEditSave edit) ) ]
                                          )
                                        )
                                    )
                        )
                    )
                )
            |> setHLDirtyCmd


deleteMemo : Time.Posix -> MemoId -> Bool -> Model x -> ( Model x, Cmd Msg, List ( Msg, Msg ) )
deleteMemo now id createMode model =
    model
        |> mapErdMTM
            (Erd.mapCurrentLayoutTWithTime now
                (mapMemosT
                    (\memos ->
                        case memos |> List.partition (\m -> m.id == id) of
                            ( deleted :: _, kept ) ->
                                ( kept, [ ( MemoMsg (MUnDelete deleted), MemoMsg (MDelete deleted.id) ) ] )

                            _ ->
                                ( memos, [] )
                    )
                )
            )
        |> (\( m, hist ) ->
                if createMode then
                    ( m, Cmd.none, [] )

                else
                    ( m, Track.memoDeleted model.erd ) |> setHDirtyCmd (hist |> Maybe.withDefault [])
           )
