module Components.Organisms.Relation exposing (Direction(..), curve, doc, line)

import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (div)
import Html.Attributes as Html
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.Position as Position exposing (Position)
import Libs.Svg.Attributes exposing (css)
import Libs.Svg.Utils exposing (circle, curveTo, lineTo, moveTo)
import Libs.Tailwind as Tw exposing (Color, fill_500, stroke_500)
import Svg exposing (Attribute, Svg, svg, text)
import Svg.Attributes exposing (class, d, height, strokeDasharray, style, width, x1, x2, y1, y2)


type Direction
    = Right
    | Left
    | None


line : Position -> Position -> Bool -> Maybe Color -> String -> Int -> Svg msg
line src ref nullable color label index =
    buildSvg { src = src, ref = ref, nullable = nullable, color = color, label = label, index = index, padding = 12 }
        (\origin -> drawLine (src |> Position.sub origin) (ref |> Position.sub origin))


curve : ( Position, Direction ) -> ( Position, Direction ) -> Bool -> Maybe Color -> String -> Int -> Svg msg
curve ( src, srcDir ) ( ref, refDir ) nullable color label index =
    buildSvg { src = src, ref = ref, nullable = nullable, color = color, label = label, index = index, padding = 50 }
        (\origin -> drawCurve ( src |> Position.sub origin, srcDir ) ( ref |> Position.sub origin, refDir ) ( 10, 5 ))


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


drawLine : Position -> Position -> Bool -> Maybe Color -> List (Svg msg)
drawLine p1 p2 nullable color =
    [ Svg.line
        ([ x1 (String.fromFloat p1.left)
         , y1 (String.fromFloat p1.top)
         , x2 (String.fromFloat p2.left)
         , y2 (String.fromFloat p2.top)
         ]
            ++ lineAttrs nullable color
        )
        []
    ]


drawCurve : ( Position, Direction ) -> ( Position, Direction ) -> ( Float, Float ) -> Bool -> Maybe Color -> List (Svg msg)
drawCurve ( p1, dir1 ) ( p2, dir2 ) ( arrowLength, arrowWidth ) nullable color =
    let
        strength : Float
        strength =
            abs (p1.left - p2.left) / 2 |> max 15
    in
    [ Svg.path
        (d
            ([ moveTo p1
             , lineTo (p1 |> add arrowLength dir1)
             , moveTo (p1 |> Position.add { left = 0, top = negate arrowWidth })
             , lineTo (p1 |> add arrowLength dir1)
             , moveTo (p1 |> Position.add { left = 0, top = arrowWidth })
             , lineTo (p1 |> add arrowLength dir1)
             , moveTo (p1 |> add arrowLength dir1)
             , curveTo (p1 |> add (arrowLength + strength) dir1) (p2 |> add strength dir2) p2
             ]
                |> String.join " "
            )
            :: lineAttrs nullable color
        )
        []
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
            ([ ( "line", line Position.zero (Position 50 50) False Nothing "relation" 10 )
             , ( "curve", curve ( Position.zero, Right ) ( Position 50 50, Left ) False Nothing "relation" 10 )
             , ( "green", line Position.zero (Position 50 50) False (Just Tw.green) "relation" 10 )
             , ( "nullable", line Position.zero (Position 50 50) True Nothing "relation" 10 )
             ]
                |> List.map (Tuple.mapSecond (\component -> div [ Html.style "height" "100px" ] [ component ]))
            )
