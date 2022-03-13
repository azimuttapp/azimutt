module PagesComponents.Projects.Id_.Subscriptions exposing (subscriptions)

import Browser.Events
import Html.Events.Extra.Mouse as Mouse
import Json.Decode as Decode exposing (Decoder)
import Libs.Bool as B
import Libs.Json.Decode as Decode
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Position as Position
import PagesComponents.Projects.Id_.Models exposing (Model, Msg(..), VirtualRelationMsg(..))
import Ports


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        ([ Ports.onJsMessage JsMessage ]
            ++ B.cond (model.openedDropdown == "") [] [ Browser.Events.onClick (targetIdDecoder |> Decode.map (\id -> B.cond (id == model.openedDropdown) (Noop "dropdown opened twice") (DropdownToggle id))) ]
            ++ B.cond (model.contextMenu == Nothing) [] [ Browser.Events.onClick (Decode.succeed ContextMenuClose) ]
            ++ (model.dragging
                    |> Maybe.mapOrElse
                        (\_ ->
                            [ Browser.Events.onMouseMove (Mouse.eventDecoder |> Decode.map (.pagePos >> Position.fromTuple >> DragMove))
                            , Browser.Events.onMouseUp (Mouse.eventDecoder |> Decode.map (.pagePos >> Position.fromTuple >> DragEnd))
                            ]
                        )
                        []
               )
            ++ (model.virtualRelation |> Maybe.mapOrElse (\_ -> [ Browser.Events.onMouseMove (Mouse.eventDecoder |> Decode.map (.pagePos >> Position.fromTuple >> VRMove >> VirtualRelationMsg)) ]) [])
        )


targetIdDecoder : Decoder HtmlId
targetIdDecoder =
    Decode.field "target"
        (Decode.oneOf
            [ Decode.at [ "id" ] Decode.string |> Decode.filter (\id -> id /= "")
            , Decode.at [ "parentElement", "id" ] Decode.string |> Decode.filter (\id -> id /= "")
            , Decode.at [ "parentElement", "parentElement", "id" ] Decode.string |> Decode.filter (\id -> id /= "")
            , Decode.at [ "parentElement", "parentElement", "parentElement", "id" ] Decode.string |> Decode.filter (\id -> id /= "")
            , Decode.at [ "parentElement", "parentElement", "parentElement", "parentElement", "id" ] Decode.string |> Decode.filter (\id -> id /= "")
            , Decode.at [ "parentElement", "parentElement", "parentElement", "parentElement", "parentElement", "id" ] Decode.string |> Decode.filter (\id -> id /= "")
            , Decode.succeed ""
            ]
        )
