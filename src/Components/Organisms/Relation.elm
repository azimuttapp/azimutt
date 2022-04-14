module Components.Organisms.Relation exposing (Direction(..), RelationConf, curve, doc, line)

import ElmBook.Actions exposing (logAction)
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (div)
import Html.Attributes as Html
import Html.Events exposing (onMouseEnter, onMouseLeave)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.Position as Position exposing (Position)
import Libs.Svg.Attributes as Attributes exposing (css)
import Libs.Svg.Utils exposing (circle, curveTo, lineTo, moveTo)
import Libs.Tailwind as Tw exposing (Color, fill_500, stroke_500)
import Svg exposing (Attribute, Svg, svg, text)
import Svg.Attributes exposing (class, d, height, strokeDasharray, style, width, x1, x2, y1, y2)


type alias RelationConf =
    { hover : Bool }


type Direction
    = Right
    | Left
    | None


line : RelationConf -> Position -> Position -> Bool -> Maybe Color -> String -> Int -> (Bool -> msg) -> Svg msg
line conf src ref nullable color label index onHover =
    buildSvg { src = src, ref = ref, nullable = nullable, color = color, label = label, index = index, padding = 12 }
        (\origin -> drawLine conf (src |> Position.sub origin) (ref |> Position.sub origin) onHover)


curve : RelationConf -> ( Position, Direction ) -> ( Position, Direction ) -> Bool -> Maybe Color -> String -> Int -> (Bool -> msg) -> Svg msg
curve conf ( src, srcDir ) ( ref, refDir ) nullable color label index onHover =
    buildSvg { src = src, ref = ref, nullable = nullable, color = color, label = label, index = index, padding = 50 }
        (\origin -> drawCurve conf ( src |> Position.sub origin, srcDir ) ( ref |> Position.sub origin, refDir ) ( 10, 5 ) onHover)


type alias SvgParams =
    { src : Position, ref : Position, nullable : Bool, color : Maybe Color, label : String, index : Int, padding : Float }


buildSvg : SvgParams -> (Position -> Bool -> Maybe Color -> List (Svg msg)) -> Svg msg
buildSvg { src, ref, nullable, color, label, index, padding } svgContent =
    let
        origin : Position
        origin =
            { left = min src.left ref.left - padding, top = min src.top ref.top - padding }
    in
    svg
        [ class "az-relation absolute select-none"
        , width (String.fromFloat (abs (src.left - ref.left) + (padding * 2)))
        , height (String.fromFloat (abs (src.top - ref.top) + (padding * 2)))
        , style ("left: " ++ String.fromFloat origin.left ++ "px; top: " ++ String.fromFloat origin.top ++ "px; z-index: " ++ String.fromInt index ++ ";")

        --, style ("transform: translate(" ++ String.fromFloat origin.left ++ "px, " ++ String.fromFloat origin.top ++ "px); z-index: " ++ String.fromInt index ++ ";")
        --, style ("transform: translate3d(" ++ String.fromFloat origin.left ++ "px, " ++ String.fromFloat origin.top ++ "px, 0); z-index: " ++ String.fromInt index ++ ";")
        ]
        (text label :: svgContent origin nullable color)


drawLine : RelationConf -> Position -> Position -> (Bool -> msg) -> Bool -> Maybe Color -> List (Svg msg)
drawLine conf p1 p2 onHover nullable color =
    [ Svg.line
        ([ x1 (String.fromFloat p1.left)
         , y1 (String.fromFloat p1.top)
         , x2 (String.fromFloat p2.left)
         , y2 (String.fromFloat p2.top)
         , Attributes.when conf.hover (onMouseEnter (onHover True))
         , Attributes.when conf.hover (onMouseLeave (onHover False))
         ]
            ++ lineAttrs nullable color
        )
        []
    ]


drawCurve : RelationConf -> ( Position, Direction ) -> ( Position, Direction ) -> ( Float, Float ) -> (Bool -> msg) -> Bool -> Maybe Color -> List (Svg msg)
drawCurve conf ( p1, dir1 ) ( p2, dir2 ) ( arrowLength, arrowWidth ) onHover nullable color =
    let
        strength : Float
        strength =
            abs (p1.left - p2.left) / 2 |> max 15

        path : List String
        path =
            [ moveTo p1
            , lineTo (p1 |> add arrowLength dir1)
            , moveTo (p1 |> Position.add { left = 0, top = negate arrowWidth })
            , lineTo (p1 |> add arrowLength dir1)
            , moveTo (p1 |> Position.add { left = 0, top = arrowWidth })
            , lineTo (p1 |> add arrowLength dir1)
            , moveTo (p1 |> add arrowLength dir1)
            , curveTo (p1 |> add (arrowLength + strength) dir1) (p2 |> add strength dir2) p2
            ]

        hoverAttrs : List (Attribute msg)
        hoverAttrs =
            if conf.hover then
                [ onMouseEnter (onHover True), onMouseLeave (onHover False) ]

            else
                []
    in
    [ Svg.path ([ d (path |> String.join " ") ] ++ hoverAttrs ++ lineAttrs nullable color) []
    , circle (p2 |> add 2 dir2) 2.5 [ class (color |> Maybe.mapOrElse (\c -> fill_500 c) "fill-default-400") ]
    ]


add : Float -> Direction -> Position -> Position
add strength dir pos =
    case dir of
        Left ->
            pos |> Position.add { left = negate strength, top = 0 }

        Right ->
            pos |> Position.add { left = strength, top = 0 }

        None ->
            pos |> Position.add { left = 0, top = 0 }


lineAttrs : Bool -> Maybe Color -> List (Attribute msg)
lineAttrs nullable color =
    List.prependIf nullable
        (strokeDasharray "4")
        [ css [ "fill-transparent", color |> Maybe.mapOrElse (\c -> stroke_500 c ++ " stroke-2") "stroke-default-400 stroke-1" ]
        ]



-- DOCUMENTATION


doc : Chapter x
doc =
    Chapter.chapter "Relation"
        |> Chapter.renderComponentList
            ([ ( "line", line { hover = True } Position.zero (Position 50 50) False Nothing "relation" 10 (\_ -> logAction "hover relation") )
             , ( "curve", curve { hover = True } ( Position.zero, Right ) ( Position 50 50, Left ) False Nothing "relation" 10 (\_ -> logAction "hover relation") )
             , ( "green", line { hover = True } Position.zero (Position 50 50) False (Just Tw.green) "relation" 10 (\_ -> logAction "hover relation") )
             , ( "nullable", line { hover = True } Position.zero (Position 50 50) True Nothing "relation" 10 (\_ -> logAction "hover relation") )
             ]
                |> List.map (Tuple.mapSecond (\component -> div [ Html.style "height" "100px" ] [ component ]))
            )
