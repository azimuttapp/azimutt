module Models.Project.SourceKind exposing (SourceKind(..), path)

import Libs.Models exposing (FileModified, FileName, FileSize, FileUrl)


type SourceKind
    = LocalFile FileName FileSize FileModified
    | RemoteFile FileUrl FileSize
    | UserDefined


path : SourceKind -> String
path sourceContent =
    case sourceContent of
        LocalFile name _ _ ->
            name

        RemoteFile url _ ->
            url

        UserDefined ->
            ""
