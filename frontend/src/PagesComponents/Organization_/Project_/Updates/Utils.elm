module PagesComponents.Organization_.Project_.Updates.Utils exposing (DirtyModel, HistoryModel, addHistory, addHistoryCmd, addHistoryM, addHistoryT, addHistoryTCmd, setDirty, setDirtyCmd)

import PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf)
import Ports


type alias DirtyModel m =
    { m | conf : ErdConf, dirty : Bool }


setDirty : DirtyModel m -> ( DirtyModel m, Cmd msg )
setDirty model =
    if model.dirty || not model.conf.save then
        ( model, Cmd.none )

    else
        ( { model | dirty = True }, Ports.projectDirty True )


setDirtyCmd : ( DirtyModel m, Cmd msg ) -> ( DirtyModel m, Cmd msg )
setDirtyCmd ( model, cmd ) =
    if model.dirty || not model.conf.save then
        ( model, cmd )

    else
        ( { model | dirty = True }, Cmd.batch [ cmd, Ports.projectDirty True ] )


type alias HistoryModel m msg =
    { m | history : List ( msg, msg ), future : List ( msg, msg ) }


addHistory : String -> ( msg, msg ) -> HistoryModel m msg -> HistoryModel m msg
addHistory doCmd msg model =
    if doCmd == "undo" || doCmd == "redo" then
        model

    else
        { model | history = msg :: model.history, future = [] }


addHistoryCmd : String -> ( msg, msg ) -> ( HistoryModel m msg, Cmd msg ) -> ( HistoryModel m msg, Cmd msg )
addHistoryCmd doCmd msg ( model, cmd ) =
    ( addHistory doCmd msg model, cmd )


addHistoryM : String -> Maybe ( msg, msg ) -> HistoryModel m msg -> HistoryModel m msg
addHistoryM doCmd msg model =
    msg |> Maybe.map (\m -> addHistory doCmd m model) |> Maybe.withDefault model


addHistoryT : String -> ( HistoryModel m msg, Maybe ( msg, msg ) ) -> HistoryModel m msg
addHistoryT doCmd ( model, msg ) =
    addHistoryM doCmd msg model


addHistoryTCmd : String -> ( HistoryModel m msg, Maybe ( Maybe ( msg, msg ), Cmd msg ) ) -> ( HistoryModel m msg, Cmd msg )
addHistoryTCmd doCmd ( model, res ) =
    res |> Maybe.map (\( msg, cmd ) -> ( addHistoryM doCmd msg model, cmd )) |> Maybe.withDefault ( model, Cmd.none )
