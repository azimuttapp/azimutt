module PagesComponents.App.Views.Helpers exposing (columnRefAsHtmlId, dragAttrs, dragAttrs2, formatDate, onClickConfirm, placeAt, size, sizeAttr, withColumnName)

import Draggable
import Html exposing (Attribute, text)
import Html.Attributes exposing (attribute, style)
import Html.Events exposing (onClick)
import Html.Events.Extra.Pointer as Pointer
import Libs.DateTime as DateTime
import Libs.Maybe as M
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


dragAttrs : DragId -> List (Attribute Msg)
dragAttrs id =
    Draggable.mouseTrigger id DragMsg :: Draggable.touchTriggers id DragMsg


dragAttrs2 : DragId -> Maybe DragState -> List (Attribute Msg)
dragAttrs2 id dragState =
    Pointer.onDown (\e -> DragStart2 id (Position.fromTuple e.pointer.pagePos))
        :: (dragState
                |> M.filter (\s -> s.id == id)
                |> Maybe.map
                    (\_ ->
                        [ Pointer.onMove (\e -> DragMove2 id (Position.fromTuple e.pointer.pagePos))
                        , Pointer.onUp (\e -> DragEnd2 id (Position.fromTuple e.pointer.pagePos))
                        ]
                    )
                |> Maybe.withDefault []
           )


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
