module PagesComponents.Organization_.Project_.Views.Erd.LinkLayout exposing (viewLink)

import Components.Atoms.Icon as Icon
import Conf
import Html exposing (Attribute, Html, div, span, text)
import Html.Attributes exposing (class, classList, id)
import Html.Events exposing (onClick)
import Html.Events.Extra.Mouse exposing (Button(..))
import Libs.Bool as Bool
import Libs.Html.Attributes exposing (css)
import Libs.Html.Events exposing (PointerEvent, onContextMenu, onPointerDown)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Platform exposing (Platform)
import Libs.Tailwind as Tw
import Models.Area as Area
import PagesComponents.Organization_.Project_.Models exposing (LayoutMsg(..), Msg(..))
import PagesComponents.Organization_.Project_.Models.CursorMode as CursorMode exposing (CursorMode)
import PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Organization_.Project_.Models.LinkLayout exposing (LinkLayout)
import PagesComponents.Organization_.Project_.Models.LinkLayoutId as LinkLayoutId
import PagesComponents.Organization_.Project_.Views.Modals.LinkLayoutContextMenu as LinkLayoutContextMenu


viewLink : Platform -> ErdConf -> CursorMode -> Bool -> String -> LinkLayout -> Html Msg
viewLink platform conf cursorMode dragging otherLayouts link =
    let
        htmlId : HtmlId
        htmlId =
            LinkLayoutId.toHtmlId link.id

        color : Tw.Color
        color =
            link.color |> Maybe.withDefault Tw.gray

        resizeLink : List (Attribute Msg)
        resizeLink =
            Bool.cond (cursorMode == CursorMode.Drag || not conf.move) [] [ onPointerDown (\_ -> Noop "no drag on link resize") platform ]

        dragAttrs : List (Attribute Msg)
        dragAttrs =
            Bool.cond (cursorMode == CursorMode.Drag || not conf.move) [] [ onPointerDown (handlePointerDown htmlId) platform ]

        clickAttrs : List (Attribute Msg)
        clickAttrs =
            Bool.cond dragging [] [ onClick (link.target |> LLoad "fit" |> LayoutMsg) ]
    in
    div
        ([ id htmlId
         , css
            [ "select-none absolute overflow-hidden hover:resize"
            , "group flex items-center justify-center rounded-lg border-2 border-b-4 border-r-4"
            , Tw.bg_100 color
            , Tw.border_500 color
            ]
         , classList [ ( "ring-2 " ++ Tw.ring_700 (link.color |> Maybe.withDefault Tw.gray), link.selected ) ]
         ]
            ++ Bool.cond conf.layout [ onContextMenu (ContextMenuCreate (LinkLayoutContextMenu.view conf otherLayouts link)) platform ] []
            ++ Area.stylesGrid link
            ++ resizeLink
        )
        [ span [ class "absolute w-0 h-0 transition-all duration-300 ease-out bg-white rounded-full group-hover:w-96 group-hover:h-96 opacity-25" ] []
        , span ([ class "relative w-full h-full flex items-center justify-center text-sm cursor-pointer" ] ++ dragAttrs ++ clickAttrs) [ Icon.solid Icon.ExternalLink "inline mr-1", text link.target ]
        ]


handlePointerDown : HtmlId -> PointerEvent -> Msg
handlePointerDown htmlId e =
    if e.button == MainButton then
        e |> .clientPos |> DragStart htmlId

    else if e.button == MiddleButton then
        e |> .clientPos |> DragStart Conf.ids.erd

    else
        Noop "No match on link pointer down"
