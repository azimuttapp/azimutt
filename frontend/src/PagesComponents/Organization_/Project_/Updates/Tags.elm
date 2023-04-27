module PagesComponents.Organization_.Project_.Updates.Tags exposing (Model, handleTags)

import Dict exposing (Dict)
import Models.Project.TableMeta as TableMeta exposing (TableMeta)
import PagesComponents.Organization_.Project_.Models exposing (Msg(..))
import PagesComponents.Organization_.Project_.Models.Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Organization_.Project_.Models.TagsMsg exposing (TagsMsg(..))
import PagesComponents.Organization_.Project_.Updates.Utils exposing (setDirtyCmd)
import Services.Lenses exposing (mapEditTagsM, mapErdM, mapMetadata, setEditTags)


type alias Model x =
    { x
        | conf : ErdConf
        , dirty : Bool
        , erd : Maybe Erd
        , editTags : Maybe String
    }


handleTags : TagsMsg -> Model x -> ( Model x, Cmd Msg )
handleTags msg model =
    case msg of
        TEdit content ->
            ( model |> mapEditTagsM (\_ -> content), Cmd.none )

        TSave table column initialTags tags ->
            let
                cmd : Cmd msg
                cmd =
                    if initialTags == tags then
                        Cmd.none

                    else if tags == [] then
                        -- Track.notesDeleted model.erd
                        Cmd.none

                    else if initialTags == [] then
                        -- Track.notesCreated tags model.erd
                        Cmd.none

                    else
                        -- Track.notesUpdated tags model.erd
                        Cmd.none
            in
            ( model |> setEditTags Nothing |> mapErdM (mapMetadata (Dict.update table (TableMeta.upsertTags column tags >> Just))), cmd ) |> setDirtyCmd
