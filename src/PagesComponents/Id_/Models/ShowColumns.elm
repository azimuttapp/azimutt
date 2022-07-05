module PagesComponents.Id_.Models.ShowColumns exposing (ShowColumns(..))

import Models.Project.ColumnName exposing (ColumnName)


type ShowColumns
    = All
    | Relations
    | List (List ColumnName)
