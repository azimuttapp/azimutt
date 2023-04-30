module PagesComponents.Organization_.Project_.Models.NotesMsg exposing (NotesMsg(..))

import Libs.Models.Notes exposing (Notes)
import Models.Project.ColumnPath exposing (ColumnPath)
import Models.Project.TableId exposing (TableId)


type NotesMsg
    = NOpen TableId (Maybe ColumnPath)
    | NEdit Notes
    | NSave TableId (Maybe ColumnPath) Notes Notes
    | NCancel
