module Models.Project.Origin exposing (Origin)

import Libs.Models exposing (FileLineIndex)
import Models.Project.SourceId exposing (SourceId)


type alias Origin =
    { id : SourceId, lines : List FileLineIndex }
