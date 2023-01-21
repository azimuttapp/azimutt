module PagesComponents.Organization_.Project_.Models.NotesMsg exposing (NotesMsg(..))

import PagesComponents.Organization_.Project_.Models.Notes exposing (Notes, NotesRef)


type NotesMsg
    = NOpen NotesRef
    | NEdit Notes
    | NSave NotesRef Notes Notes
    | NCancel
