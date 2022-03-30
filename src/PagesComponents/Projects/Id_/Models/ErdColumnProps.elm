module PagesComponents.Projects.Id_.Models.ErdColumnProps exposing (ErdColumnProps, create, createAll)

import Dict exposing (Dict)
import Libs.Models.Position exposing (Position)
import Libs.Models.Size exposing (Size)
import Libs.Tailwind exposing (Color)
import Models.Project.ColumnName exposing (ColumnName)
import Set exposing (Set)


type alias ErdColumnProps =
    { column : ColumnName
    , index : Int
    , position : Position
    , size : Size
    , color : Color
    , highlighted : Bool
    , selected : Bool
    , collapsed : Bool
    }


createAll : Position -> Size -> Color -> Set ColumnName -> Bool -> Bool -> List ColumnName -> Dict ColumnName ErdColumnProps
createAll position size color highlightedColumns selected collapsed columns =
    columns
        |> List.indexedMap (\i c -> ( c, create c i position size color highlightedColumns selected collapsed ))
        |> Dict.fromList


create : ColumnName -> Int -> Position -> Size -> Color -> Set ColumnName -> Bool -> Bool -> ErdColumnProps
create column index position size color highlightedColumns selected collapsed =
    { column = column
    , index = index
    , position = position
    , size = size
    , color = color
    , highlighted = highlightedColumns |> Set.member column
    , selected = selected
    , collapsed = collapsed
    }
