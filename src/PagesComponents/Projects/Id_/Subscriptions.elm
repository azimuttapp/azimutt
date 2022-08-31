module PagesComponents.Projects.Id_.Subscriptions exposing (subscriptions)

import Browser.Events
import Components.Molecules.Dropdown as Dropdown
import Html.Events.Extra.Mouse as Mouse
import Json.Decode as Decode
import Libs.Bool as B
import Libs.Maybe as Maybe
import Models.Position as Position
import PagesComponents.Projects.Id_.Models exposing (Model, Msg(..), VirtualRelationMsg(..))
import Ports


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        ([ Ports.onJsMessage JsMessage ]
            ++ Dropdown.subs model DropdownToggle (Noop "dropdown already opened")
            ++ B.cond (model.contextMenu == Nothing) [] [ Browser.Events.onClick (Decode.succeed ContextMenuClose) ]
            ++ (model.dragging
                    |> Maybe.mapOrElse
                        (\_ ->
                            [ Browser.Events.onMouseMove (Mouse.eventDecoder |> Decode.map (Position.fromEventViewport >> DragMove))
                            , Browser.Events.onMouseUp (Mouse.eventDecoder |> Decode.map (Position.fromEventViewport >> DragEnd))
                            ]
                        )
                        []
               )
            ++ (model.virtualRelation |> Maybe.mapOrElse (\_ -> [ Browser.Events.onMouseMove (Mouse.eventDecoder |> Decode.map (Position.fromEventViewport >> VRMove >> VirtualRelationMsg)) ]) [])
        )
