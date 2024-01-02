module PagesComponents.Organization_.Project_.Updates.Utils exposing (DirtyModel, setDirty, setDirtyHCmdM, setDirtyM, setHDirty)

import Libs.Maybe as Maybe
import PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Organization_.Project_.Updates.Extra as Extra exposing (Extra)
import Ports


type alias DirtyModel m =
    { m | conf : ErdConf, dirty : Bool }


setDirty : ( DirtyModel m, Extra msg ) -> ( DirtyModel m, Extra msg )
setDirty ( model, ( cmd, history ) ) =
    if model.dirty || not model.conf.save then
        ( model, ( cmd, history ) )

    else
        ( { model | dirty = True }, ( Cmd.batch [ cmd, Ports.projectDirty True ], history ) )


setDirtyM : ( DirtyModel m, Maybe (Extra msg) ) -> ( DirtyModel m, Extra msg )
setDirtyM ( model, extraM ) =
    ( model, extraM |> Maybe.withDefault Extra.none ) |> setDirty


setHDirty : ( DirtyModel m, Maybe (List ( msg, msg )) ) -> ( DirtyModel m, Extra msg )
setHDirty ( model, history ) =
    if model.dirty || not model.conf.save then
        ( model, ( Cmd.none, history |> Maybe.mapOrElse identity [] ) )

    else
        ( { model | dirty = True }, ( Ports.projectDirty True, history |> Maybe.mapOrElse identity [] ) )


setDirtyHCmdM : List ( msg, msg ) -> ( DirtyModel m, Maybe (Cmd msg) ) -> ( DirtyModel m, Extra msg )
setDirtyHCmdM history ( model, cmd ) =
    if model.dirty || not model.conf.save then
        ( model, ( cmd |> Maybe.withDefault Cmd.none, history ) )

    else
        ( { model | dirty = True }, ( Cmd.batch [ cmd |> Maybe.withDefault Cmd.none, Ports.projectDirty True ], history ) )
