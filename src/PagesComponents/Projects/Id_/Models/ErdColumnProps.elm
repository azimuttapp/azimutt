module PagesComponents.Projects.Id_.Models.ErdColumnProps exposing (ErdColumnProps, create, createAll)

import Dict exposing (Dict)
import Libs.Models.Position exposing (Position)
import Libs.Models.Size exposing (Size)
import Libs.Tailwind exposing (Color)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnRef as ColumnRef exposing (ColumnRef)
import Models.Project.TableId exposing (TableId)
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
    , notes : Maybe String
    }


createAll : TableId -> Position -> Size -> Color -> Set ColumnName -> Bool -> Bool -> Dict String String -> List ColumnName -> Dict ColumnName ErdColumnProps
createAll tableId position size color highlightedColumns selected collapsed notes columns =
    columns
        |> List.indexedMap (\i c -> ( c, create c i position size color highlightedColumns selected collapsed (notes |> Dict.get (ColumnRef tableId c |> ColumnRef.toString)) ))
        |> Dict.fromList


create : ColumnName -> Int -> Position -> Size -> Color -> Set ColumnName -> Bool -> Bool -> Maybe String -> ErdColumnProps
create column index position size color highlightedColumns selected collapsed notes =
    { column = column
    , index = index
    , position = position
    , size = size
    , color = color
    , highlighted = highlightedColumns |> Set.member column
    , selected = selected
    , collapsed = collapsed
    , notes = notes
    }
