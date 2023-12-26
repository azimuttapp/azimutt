module PagesComponents.Organization_.Project_.Updates.Utils exposing (DirtyModel, setDirty, setDirtyCmd, setHDirty, setHDirtyCmd, setHL, setHLDirty, setHLDirtyCmd)

import Libs.Maybe as Maybe
import PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf)
import Ports


type alias DirtyModel m =
    { m | conf : ErdConf, dirty : Bool }


setHL : ( a, Maybe (List ( msg, msg )) ) -> ( a, Cmd msg, List ( msg, msg ) )
setHL ( model, history ) =
    ( model, Cmd.none, history |> Maybe.withDefault [] )


setHLDirty : ( DirtyModel m, Maybe (List ( msg, msg )) ) -> ( DirtyModel m, Cmd msg, List ( msg, msg ) )
setHLDirty ( model, history ) =
    if model.dirty || not model.conf.save then
        ( model, Cmd.none, history |> Maybe.mapOrElse identity [] )

    else
        ( { model | dirty = True }, Ports.projectDirty True, history |> Maybe.mapOrElse identity [] )


setHLDirtyCmd : ( DirtyModel m, Maybe ( Cmd msg, List ( msg, msg ) ) ) -> ( DirtyModel m, Cmd msg, List ( msg, msg ) )
setHLDirtyCmd ( model, meta ) =
    let
        cmd : Cmd msg
        cmd =
            meta |> Maybe.mapOrElse Tuple.first Cmd.none

        history : List ( msg, msg )
        history =
            meta |> Maybe.map Tuple.second |> Maybe.withDefault []
    in
    if model.dirty || not model.conf.save then
        ( model, cmd, history )

    else
        ( { model | dirty = True }, Cmd.batch [ cmd, Ports.projectDirty True ], history )


setHDirty : List ( msg, msg ) -> DirtyModel m -> ( DirtyModel m, Cmd msg, List ( msg, msg ) )
setHDirty history model =
    if model.dirty || not model.conf.save then
        ( model, Cmd.none, history )

    else
        ( { model | dirty = True }, Ports.projectDirty True, history )


setHDirtyCmd : List ( msg, msg ) -> ( DirtyModel m, Cmd msg ) -> ( DirtyModel m, Cmd msg, List ( msg, msg ) )
setHDirtyCmd history ( model, cmd ) =
    if model.dirty || not model.conf.save then
        ( model, cmd, history )

    else
        ( { model | dirty = True }, Cmd.batch [ cmd, Ports.projectDirty True ], history )


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
