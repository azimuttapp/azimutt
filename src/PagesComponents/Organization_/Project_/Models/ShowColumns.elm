module PagesComponents.Organization_.Project_.Models.ShowColumns exposing (ShowColumns(..))

import Models.Project.ColumnName exposing (ColumnName)


type ShowColumns
    = All
    | Relations
    | List (List ColumnName)
