module PagesComponents.Projects.Id_.Updates.Notes exposing (Model, handleNotes)

import Conf
import Dict
import Libs.Dict as Dict
import Libs.Maybe as Maybe
import Libs.Task as T
import PagesComponents.Projects.Id_.Models exposing (Msg(..), NotesDialog, NotesMsg(..))
import PagesComponents.Projects.Id_.Models.Erd exposing (Erd)
import PagesComponents.Projects.Id_.Models.Notes as NoteRef exposing (NotesRef(..))
import Ports
import Services.Lenses exposing (mapColumnProps, mapEditNotesM, mapErdMCmd, mapNotes, mapTableProps, setEditNotes, setNotes)
import Track


type alias Model x =
    { x
        | editNotes : Maybe NotesDialog
        , erd : Maybe Erd
    }


handleNotes : NotesMsg -> Model x -> ( Model x, Cmd Msg )
handleNotes msg model =
    case msg of
        NOpen ref ->
            ( model
                |> setEditNotes
                    (Just
                        { id = Conf.ids.editNotesDialog
                        , ref = ref
                        , notes = model.erd |> Maybe.andThen (\erd -> erd.notes |> Dict.get (ref |> NoteRef.asKey)) |> Maybe.withDefault ""
                        }
                    )
            , Cmd.batch [ T.sendAfter 1 (ModalOpen Conf.ids.editNotesDialog), Ports.track Track.openEditNotes ]
            )

        NEdit notes ->
            ( model |> mapEditNotesM (setNotes notes), Cmd.none )

        NSave key notes ->
            model |> setEditNotes Nothing |> mapErdMCmd (updateNotes key (Just notes |> Maybe.filter (\n -> n /= "")))

        NCancel ->
            ( model |> setEditNotes Nothing, Cmd.none )


updateNotes : NotesRef -> Maybe String -> Erd -> ( Erd, Cmd Msg )
updateNotes ref notes erd =
    case ref of
        TableNote t ->
            ( erd
                |> mapNotes (Dict.set (ref |> NoteRef.asKey) notes)
                |> mapTableProps (Dict.alter t (setNotes notes))
            , Cmd.none
            )

        ColumnNote c ->
            ( erd
                |> mapNotes (Dict.set (ref |> NoteRef.asKey) notes)
                |> mapTableProps (Dict.alter c.table (mapColumnProps (Dict.alter c.column (setNotes notes))))
            , Cmd.none
            )
