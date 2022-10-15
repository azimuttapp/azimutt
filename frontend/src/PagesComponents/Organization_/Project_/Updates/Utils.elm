module PagesComponents.Organization_.Project_.Updates.Utils exposing (Model, setDirty, setDirtyCmd)

import Ports


type alias Model x =
    { x | dirty : Bool }


setDirty : Model x -> ( Model x, Cmd msg )
setDirty model =
    if model.dirty then
        ( model, Cmd.none )

    else
        ( { model | dirty = True }, Ports.projectDirty True )


setDirtyCmd : ( Model x, Cmd msg ) -> ( Model x, Cmd msg )
setDirtyCmd ( model, cmd ) =
    if model.dirty then
        ( model, cmd )

    else
        ( { model | dirty = True }, Cmd.batch [ cmd, Ports.projectDirty True ] )
