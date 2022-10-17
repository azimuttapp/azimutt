module PagesComponents.Organization_.Project_.Updates.Utils exposing (Model, setDirty, setDirtyCmd)

import PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf)
import Ports


type alias Model x =
    { x | conf : ErdConf, dirty : Bool }


setDirty : Model x -> ( Model x, Cmd msg )
setDirty model =
    if model.dirty || not model.conf.save then
        ( model, Cmd.none )

    else
        ( { model | dirty = True }, Ports.projectDirty True )


setDirtyCmd : ( Model x, Cmd msg ) -> ( Model x, Cmd msg )
setDirtyCmd ( model, cmd ) =
    if model.dirty || not model.conf.save then
        ( model, cmd )

    else
        ( { model | dirty = True }, Cmd.batch [ cmd, Ports.projectDirty True ] )
