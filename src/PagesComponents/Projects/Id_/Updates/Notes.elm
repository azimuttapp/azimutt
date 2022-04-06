module PagesComponents.Projects.Id_.Updates.Notes exposing (Model, handleNotes)

import Conf
import Dict
import Libs.Dict as Dict
import Libs.Maybe as Maybe
import Libs.Task as T
import Models.Project.ColumnRef as ColumnRef
import PagesComponents.Projects.Id_.Models exposing (Msg(..), NoteRef(..), NotesDialog, NotesMsg(..))
import PagesComponents.Projects.Id_.Models.Erd exposing (Erd)
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
        NOpen noteKey ->
            ( model
                |> setEditNotes
                    (Just
                        { id = Conf.ids.editNotesDialog
                        , ref = noteKey
                        , notes = model.erd |> Maybe.andThen (\erd -> erd.notes |> Dict.get (refAsString noteKey)) |> Maybe.withDefault ""
                        }
                    )
            , Cmd.batch [ T.sendAfter 1 (ModalOpen Conf.ids.editNotesDialog), Ports.track Track.openEditNotes ]
            )

        NEdit notes ->
            ( model |> mapEditNotesM (setNotes notes), Cmd.none )

        NSave noteKey notes ->
            model |> setEditNotes Nothing |> mapErdMCmd (updateNotes noteKey (Just notes |> Maybe.filter (\n -> n /= "")))

        NCancel ->
            ( model |> setEditNotes Nothing, Cmd.none )


refAsString : NoteRef -> String
refAsString ref =
    case ref of
        ColumnNote c ->
            ColumnRef.toString c


updateNotes : NoteRef -> Maybe String -> Erd -> ( Erd, Cmd Msg )
updateNotes ref notes erd =
    case ref of
        ColumnNote c ->
            ( erd
                |> mapNotes (Dict.set (refAsString ref) notes)
                |> mapTableProps (Dict.alter c.table (mapColumnProps (Dict.alter c.column (setNotes notes))))
            , Cmd.none
            )
