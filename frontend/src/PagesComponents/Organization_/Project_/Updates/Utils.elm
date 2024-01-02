module PagesComponents.Organization_.Project_.Updates.Utils exposing (DirtyModel, setHCmd, setHDirty, setHDirtyCmd, setHDirtyCmdM, setHL, setHLCmd, setHLDirty, setHLDirtyCmd, setHLDirtyCmdM)

import Libs.Maybe as Maybe
import PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Organization_.Project_.Updates.Extra exposing (Extra)
import Ports


type alias DirtyModel m =
    { m | conf : ErdConf, dirty : Bool }


setHL : ( a, Maybe (List ( msg, msg )) ) -> ( a, Extra msg )
setHL ( model, history ) =
    ( model, ( Cmd.none, history |> Maybe.withDefault [] ) )


setHCmd : ( a, Maybe (Cmd msg) ) -> ( a, Extra msg )
setHCmd ( model, cmd ) =
    ( model, ( cmd |> Maybe.withDefault Cmd.none, [] ) )


setHLCmd : ( a, Maybe (Extra msg) ) -> ( a, Extra msg )
setHLCmd ( model, extra ) =
    extra |> extract |> (\( cmd, history ) -> ( model, ( cmd, history ) ))


setHLDirty : ( DirtyModel m, Maybe (List ( msg, msg )) ) -> ( DirtyModel m, Extra msg )
setHLDirty ( model, history ) =
    if model.dirty || not model.conf.save then
        ( model, ( Cmd.none, history |> Maybe.mapOrElse identity [] ) )

    else
        ( { model | dirty = True }, ( Ports.projectDirty True, history |> Maybe.mapOrElse identity [] ) )


setHLDirtyCmd : ( DirtyModel m, Extra msg ) -> ( DirtyModel m, Extra msg )
setHLDirtyCmd ( model, extra ) =
    let
        ( cmd, history ) =
            extra
    in
    if model.dirty || not model.conf.save then
        ( model, ( cmd, history ) )

    else
        ( { model | dirty = True }, ( Cmd.batch [ cmd, Ports.projectDirty True ], history ) )


setHLDirtyCmdM : ( DirtyModel m, Maybe (Extra msg) ) -> ( DirtyModel m, Extra msg )
setHLDirtyCmdM ( model, extraM ) =
    let
        ( cmd, history ) =
            extract extraM
    in
    if model.dirty || not model.conf.save then
        ( model, ( cmd, history ) )

    else
        ( { model | dirty = True }, ( Cmd.batch [ cmd, Ports.projectDirty True ], history ) )


setHDirty : List ( msg, msg ) -> DirtyModel m -> ( DirtyModel m, Extra msg )
setHDirty history model =
    if model.dirty || not model.conf.save then
        ( model, ( Cmd.none, history ) )

    else
        ( { model | dirty = True }, ( Ports.projectDirty True, history ) )


setHDirtyCmd : List ( msg, msg ) -> ( DirtyModel m, Cmd msg ) -> ( DirtyModel m, Extra msg )
setHDirtyCmd history ( model, cmd ) =
    if model.dirty || not model.conf.save then
        ( model, ( cmd, history ) )

    else
        ( { model | dirty = True }, ( Cmd.batch [ cmd, Ports.projectDirty True ], history ) )


setHDirtyCmdM : List ( msg, msg ) -> ( DirtyModel m, Maybe (Cmd msg) ) -> ( DirtyModel m, Extra msg )
setHDirtyCmdM history ( model, cmd ) =
    if model.dirty || not model.conf.save then
        ( model, ( cmd |> Maybe.withDefault Cmd.none, history ) )

    else
        ( { model | dirty = True }, ( Cmd.batch [ cmd |> Maybe.withDefault Cmd.none, Ports.projectDirty True ], history ) )


extract : Maybe (Extra msg) -> Extra msg
extract extra =
    ( extra |> Maybe.mapOrElse Tuple.first Cmd.none, extra |> Maybe.map Tuple.second |> Maybe.withDefault [] )
