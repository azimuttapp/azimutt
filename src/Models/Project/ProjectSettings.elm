module Models.Project.ProjectSettings exposing (ProjectSettings)

import Models.Project.FindPathSettings exposing (FindPathSettings)


type alias ProjectSettings =
    { findPath : FindPathSettings }
