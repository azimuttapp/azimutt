module PagesComponents.Id_.Updates.Notes exposing (Model, handleNotes)

import Conf
import Libs.String as String
import Libs.Task as T
import PagesComponents.Id_.Models exposing (Msg(..), NotesDialog, NotesMsg(..))
import PagesComponents.Id_.Models.Erd exposing (Erd)
import PagesComponents.Id_.Models.ErdTableNotes as ErdTableNotes
import Ports
import Services.Lenses exposing (mapEditNotesM, mapErdM, mapNotes, setEditNotes, setNotes)
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
                        , notes = model.erd |> Maybe.andThen (.notes >> ErdTableNotes.get ref) |> Maybe.withDefault ""
                        }
                    )
            , Cmd.batch [ T.sendAfter 1 (ModalOpen Conf.ids.editNotesDialog), Ports.track Track.openEditNotes ]
            )

        NEdit notes ->
            ( model |> mapEditNotesM (setNotes notes), Cmd.none )

        NSave ref notes ->
            ( model |> setEditNotes Nothing |> mapErdM (mapNotes (ErdTableNotes.set ref (String.maybeNonEmpty notes))), Cmd.none )

        NCancel ->
            ( model |> setEditNotes Nothing, Cmd.none )
