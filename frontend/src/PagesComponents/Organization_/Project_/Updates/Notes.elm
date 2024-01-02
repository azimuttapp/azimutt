module PagesComponents.Organization_.Project_.Updates.Notes exposing (Model, handleNotes)

import Conf
import Libs.Models.Notes exposing (Notes)
import Libs.String as String
import Libs.Task as T
import Models.Project.Metadata as Metadata
import PagesComponents.Organization_.Project_.Models exposing (Msg(..), NotesDialog)
import PagesComponents.Organization_.Project_.Models.Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Organization_.Project_.Models.NotesMsg exposing (NotesMsg(..))
import PagesComponents.Organization_.Project_.Updates.Extra as Extra exposing (Extra)
import PagesComponents.Organization_.Project_.Updates.Utils exposing (setHDirtyCmd)
import Services.Lenses exposing (mapEditNotesM, mapErdM, mapMetadata, setEditNotes, setNotes)
import Track


type alias Model x =
    { x
        | conf : ErdConf
        , dirty : Bool
        , erd : Maybe Erd
        , editNotes : Maybe NotesDialog
    }


handleNotes : NotesMsg -> Model x -> ( Model x, Extra Msg )
handleNotes msg model =
    case msg of
        NOpen table column ->
            let
                notes : Notes
                notes =
                    model.erd |> Maybe.andThen (.metadata >> Metadata.getNotes table column) |> Maybe.withDefault ""
            in
            ( model |> setEditNotes (Just { id = Conf.ids.editNotesDialog, table = table, column = column, initialNotes = notes, notes = notes })
            , ModalOpen Conf.ids.editNotesDialog |> T.sendAfter 1 |> Extra.cmd
            )

        NEdit notes ->
            ( model |> mapEditNotesM (setNotes notes), Extra.none )

        NSave table column initialNotes notes ->
            let
                cmd : Cmd msg
                cmd =
                    if initialNotes == notes then
                        Cmd.none

                    else if notes == "" then
                        Track.notesDeleted model.erd

                    else if initialNotes == "" then
                        Track.notesCreated notes model.erd

                    else
                        Track.notesUpdated notes model.erd
            in
            ( model |> setEditNotes Nothing |> mapErdM (mapMetadata (Metadata.putNotes table column (String.nonEmptyMaybe notes))), cmd )
                |> setHDirtyCmd [ ( NotesMsg (NSave table column notes initialNotes), NotesMsg msg ) ]

        NCancel ->
            ( model |> setEditNotes Nothing, Extra.none )
