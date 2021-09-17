module PagesComponents.App.Views.Helpers exposing (columnRefAsHtmlId, dragUpdate, formatDate, onClickConfirm, onDrag, placeAt, size, sizeAttr, withColumnName)

import Html exposing (Attribute, text)
import Html.Attributes exposing (attribute, style)
import Html.Events exposing (onClick)
import Html.Events.Extra.Pointer as Pointer
import Libs.DateTime as DateTime
import Libs.Models exposing (HtmlId)
import Libs.Position as Position exposing (Position)
import Libs.Size exposing (Size)
import Libs.Task as T
import Models.Project exposing (ColumnName, ColumnRef, tableIdAsHtmlId)
import PagesComponents.App.Models exposing (DragId, DragState, Msg(..), TimeInfo)
import Time


placeAt : Position -> Attribute msg
placeAt p =
    style "transform" ("translate(" ++ String.fromFloat p.left ++ "px, " ++ String.fromFloat p.top ++ "px)")


size : Size -> List (Attribute msg)
size s =
    [ style "width" (String.fromFloat s.width ++ "px"), style "height" (String.fromFloat s.height ++ "px") ]


onDrag : DragId -> Attribute Msg
onDrag id =
    Pointer.onDown (\e -> e.pointer.pagePos |> Position.fromTuple |> DragStart id)


dragUpdate : Maybe DragState -> List (Attribute Msg)
dragUpdate dragState =
    -- should have only one in the drag container
    dragState
        |> Maybe.map
            (\_ ->
                [ Pointer.onMove (\e -> e.pointer.pagePos |> Position.fromTuple |> DragMove)
                , Pointer.onUp (\e -> e.pointer.pagePos |> Position.fromTuple |> DragEnd)
                , Pointer.onCancel (\e -> e.pointer.pagePos |> Position.fromTuple |> DragEnd)
                ]
            )
        |> Maybe.withDefault []


sizeAttr : Size -> Attribute msg
sizeAttr s =
    attribute "data-size" (String.fromInt (round s.width) ++ "x" ++ String.fromInt (round s.height))


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
