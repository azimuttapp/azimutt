module PagesComponents.App.Views.Helpers exposing (columnRefAsHtmlId, dragAttrs, formatDate, onClickConfirm, placeAt, sizeAttr, withColumnName)

import Draggable
import Html exposing (Attribute, text)
import Html.Attributes exposing (attribute, style)
import Html.Events exposing (onClick)
import Libs.DateTime as DateTime
import Libs.Models exposing (HtmlId)
import Libs.Position exposing (Position)
import Libs.Size exposing (Size)
import Libs.Task as T
import Models.Project exposing (ColumnName, ColumnRef, tableIdAsHtmlId)
import PagesComponents.App.Models exposing (DragId, Msg(..), TimeInfo)
import Time


placeAt : Position -> Attribute msg
placeAt p =
    style "transform" ("translate(" ++ String.fromFloat p.left ++ "px, " ++ String.fromFloat p.top ++ "px)")


dragAttrs : DragId -> List (Attribute Msg)
dragAttrs id =
    Draggable.mouseTrigger id DragMsg :: Draggable.touchTriggers id DragMsg


sizeAttr : Size -> Attribute msg
sizeAttr size =
    attribute "data-size" (String.fromInt (round size.width) ++ "x" ++ String.fromInt (round size.height))


onClickConfirm : String -> Msg -> Attribute Msg
onClickConfirm content msg =
    onClick (OpenConfirm { content = text content, cmd = T.send msg })



-- formatters


withColumnName : ColumnName -> String -> String
withColumnName column table =
    table ++ "." ++ column


columnRefAsHtmlId : ColumnRef -> HtmlId
columnRefAsHtmlId ref =
    tableIdAsHtmlId ref.table |> withColumnName ref.column


formatDate : TimeInfo -> Time.Posix -> String
formatDate info date =
    DateTime.format "dd MMM yyyy" info.zone date
