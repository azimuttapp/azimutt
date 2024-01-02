module PagesComponents.Organization_.Project_.Updates.Tags exposing (Model, handleTags)

import Models.Project.Metadata as Metadata
import PagesComponents.Organization_.Project_.Models exposing (Msg(..))
import PagesComponents.Organization_.Project_.Models.Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Organization_.Project_.Models.TagsMsg exposing (TagsMsg(..))
import PagesComponents.Organization_.Project_.Updates.Extra as Extra exposing (Extra)
import PagesComponents.Organization_.Project_.Updates.Utils exposing (setDirty)
import Services.Lenses exposing (mapEditTagsM, mapErdM, mapMetadata, setEditTags)
import Track


type alias Model x =
    { x
        | conf : ErdConf
        , dirty : Bool
        , erd : Maybe Erd
        , editTags : Maybe String
    }


handleTags : TagsMsg -> Model x -> ( Model x, Extra Msg )
handleTags msg model =
    case msg of
        TEdit content ->
            ( model |> mapEditTagsM (\_ -> content), Extra.none )

        TSave table column initialTags tags ->
            let
                cmd : Cmd msg
                cmd =
                    if initialTags == tags then
                        Cmd.none

                    else if tags == [] then
                        Track.tagsDeleted model.erd

                    else if initialTags == [] then
                        Track.tagsCreated tags model.erd

                    else
                        Track.tagsUpdated tags model.erd
            in
            ( model |> setEditTags Nothing |> mapErdM (mapMetadata (Metadata.putTags table column tags))
            , Extra.new cmd ( TagsMsg (TSave table column tags initialTags), TagsMsg msg )
            )
                |> setDirty
