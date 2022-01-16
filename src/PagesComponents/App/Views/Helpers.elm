module PagesComponents.App.Views.Helpers exposing (columnRefAsHtmlId, onClickConfirm, onDrag, placeAt, size, withColumnName)

import Html exposing (Attribute, text)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)
import Html.Events.Extra.Mouse as Mouse
import Libs.Models.DragId exposing (DragId)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Position as Position exposing (Position)
import Libs.Models.Size exposing (Size)
import Libs.Task as T
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.TableId as TableId
import PagesComponents.App.Models exposing (Msg(..))


placeAt : Position -> Attribute msg
placeAt p =
    style "transform" ("translate(" ++ String.fromFloat p.left ++ "px, " ++ String.fromFloat p.top ++ "px)")


size : Size -> List (Attribute msg)
size s =
    [ style "width" (String.fromFloat s.width ++ "px"), style "height" (String.fromFloat s.height ++ "px") ]


onDrag : DragId -> Attribute Msg
onDrag id =
    Mouse.onDown (.pagePos >> Position.fromTuple >> DragStart id)


onClickConfirm : String -> Msg -> Attribute Msg
onClickConfirm content msg =
    onClick (OpenConfirm { content = text content, cmd = T.send msg })



-- formatters


withColumnName : ColumnName -> String -> String
withColumnName column table =
    table ++ "." ++ column


columnRefAsHtmlId : ColumnRef -> HtmlId
columnRefAsHtmlId ref =
    TableId.toHtmlId ref.table |> withColumnName ref.column
