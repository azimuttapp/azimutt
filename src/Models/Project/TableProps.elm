module Models.Project.TableProps exposing (TableProps)

import Libs.Models exposing (Color)
import Libs.Position exposing (Position)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.TableId exposing (TableId)


type alias TableProps =
    { id : TableId, position : Position, color : Color, columns : List ColumnName, selected : Bool }
