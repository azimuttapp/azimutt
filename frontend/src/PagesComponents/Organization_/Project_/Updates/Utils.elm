module PagesComponents.Organization_.Project_.Updates.Utils exposing (DirtyModel, setDirty, setDirtyM)

import PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Organization_.Project_.Updates.Extra as Extra exposing (Extra)
import Ports


type alias DirtyModel m =
    { m | conf : ErdConf, dirty : Bool }


setDirty : ( DirtyModel m, Extra msg ) -> ( DirtyModel m, Extra msg )
setDirty ( model, e ) =
    if model.dirty || not model.conf.save then
        ( model, e )

    else
        ( { model | dirty = True }, e |> Extra.addCmd (Ports.projectDirty True) )


setDirtyM : ( DirtyModel m, Maybe (Extra msg) ) -> ( DirtyModel m, Extra msg )
setDirtyM ( model, extraM ) =
    ( model, extraM |> Maybe.withDefault Extra.none ) |> setDirty
