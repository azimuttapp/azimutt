module PagesComponents.Organization_.Project_.Updates.Notes exposing (Model, handleNotes)

import Conf
import Libs.String as String
import Libs.Task as T
import PagesComponents.Organization_.Project_.Models exposing (Msg(..), NotesDialog)
import PagesComponents.Organization_.Project_.Models.Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Organization_.Project_.Models.ErdNotes as ErdNotes
import PagesComponents.Organization_.Project_.Models.Notes exposing (Notes)
import PagesComponents.Organization_.Project_.Models.NotesMsg exposing (NotesMsg(..))
import PagesComponents.Organization_.Project_.Updates.Utils exposing (setDirtyCmd)
import Services.Lenses exposing (mapEditNotesM, mapErdM, mapNotes, setEditNotes, setNotes)
import Track


type alias Model x =
    { x
        | conf : ErdConf
        , dirty : Bool
        , erd : Maybe Erd
        , editNotes : Maybe NotesDialog
    }


handleNotes : NotesMsg -> Model x -> ( Model x, Cmd Msg )
handleNotes msg model =
    case msg of
        NOpen ref ->
            let
                notes : Notes
                notes =
                    model.erd |> Maybe.andThen (.notes >> ErdNotes.get ref) |> Maybe.withDefault ""
            in
            ( model |> setEditNotes (Just { id = Conf.ids.editNotesDialog, ref = ref, initialNotes = notes, notes = notes })
            , Cmd.batch [ T.sendAfter 1 (ModalOpen Conf.ids.editNotesDialog), Cmd.none ]
            )

        NEdit notes ->
            ( model |> mapEditNotesM (setNotes notes), Cmd.none )

        NSave ref initialNotes notes ->
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
            ( model |> setEditNotes Nothing |> mapErdM (mapNotes (ErdNotes.set ref (String.nonEmptyMaybe notes))), cmd ) |> setDirtyCmd

        NCancel ->
            ( model |> setEditNotes Nothing, Cmd.none )
