module Components.Organisms.Relation exposing (Direction(..), RelationConf, bezier, doc, show, steps, straight)

import ElmBook.Actions exposing (logAction)
import ElmBook.Chapter as Chapter exposing (Chapter)
import ElmBook.Custom exposing (Msg)
import Html exposing (Html, div)
import Html.Events exposing (onMouseEnter, onMouseLeave)
import Libs.Bool as Bool
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.Position as Position exposing (Position)
import Libs.Svg.Attributes as Attributes exposing (css)
import Libs.Svg.Utils exposing (circle, curveTo, lineTo, moveTo)
import Libs.Tailwind as Tw exposing (Color, fill_500, stroke_500)
import Models.RelationStyle as RelationStyle exposing (RelationStyle)
import Svg exposing (Attribute, Svg, svg, text)
import Svg.Attributes exposing (class, d, height, strokeDasharray, style, width, x1, x2, y1, y2)


type alias RelationConf =
    { hover : Bool }


type Direction
    = Right
    | Left
    | None


show : RelationStyle -> RelationConf -> ( Position, Direction ) -> ( Position, Direction ) -> Bool -> Maybe Color -> String -> Int -> (Bool -> msg) -> Svg msg
show style conf src ref nullable color label index onHover =
    case style of
        RelationStyle.Bezier ->
            bezier conf src ref nullable color label index onHover

        RelationStyle.Straight ->
            straight conf src ref nullable color label index onHover

        RelationStyle.Steps ->
            steps conf src ref nullable color label index onHover


straight : RelationConf -> ( Position, Direction ) -> ( Position, Direction ) -> Bool -> Maybe Color -> String -> Int -> (Bool -> msg) -> Svg msg
straight conf ( src, _ ) ( ref, _ ) nullable color label index onHover =
    buildSvg { src = src, ref = ref, nullable = nullable, color = color, label = label, index = index, padding = 12 }
        (\origin -> drawLine conf (src |> Position.sub origin) (ref |> Position.sub origin) onHover)


bezier : RelationConf -> ( Position, Direction ) -> ( Position, Direction ) -> Bool -> Maybe Color -> String -> Int -> (Bool -> msg) -> Svg msg
bezier conf ( src, srcDir ) ( ref, refDir ) nullable color label index onHover =
    buildSvg { src = src, ref = ref, nullable = nullable, color = color, label = label, index = index, padding = 50 }
        (\origin -> drawCurve conf ( src |> Position.sub origin, srcDir ) ( ref |> Position.sub origin, refDir ) onHover)


steps : RelationConf -> ( Position, Direction ) -> ( Position, Direction ) -> Bool -> Maybe Color -> String -> Int -> (Bool -> msg) -> Svg msg
steps conf ( src, srcDir ) ( ref, refDir ) nullable color label index onHover =
    buildSvg { src = src, ref = ref, nullable = nullable, color = color, label = label, index = index, padding = 50 }
        (\origin -> drawSteps conf ( src |> Position.sub origin, srcDir ) ( ref |> Position.sub origin, refDir ) onHover)


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


drawCurve : RelationConf -> ( Position, Direction ) -> ( Position, Direction ) -> (Bool -> msg) -> Bool -> Maybe Color -> List (Svg msg)
drawCurve conf ( p1, dir1 ) ( p2, dir2 ) onHover nullable color =
    let
        strength : Float
        strength =
            abs (p1.left - p2.left) / 2 |> max 15

        path : List String
        path =
            [ moveTo p1
            , lineTo (p1 |> add arrowSize dir1)
            , moveTo (p1 |> Position.add { left = 0, top = negate (arrowSize / 2) })
            , lineTo (p1 |> add arrowSize dir1)
            , moveTo (p1 |> Position.add { left = 0, top = arrowSize / 2 })
            , lineTo (p1 |> add arrowSize dir1)
            , moveTo (p1 |> add arrowSize dir1)
            , curveTo (p1 |> add (arrowSize + strength) dir1) (p2 |> add strength dir2) p2
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


drawSteps : RelationConf -> ( Position, Direction ) -> ( Position, Direction ) -> (Bool -> msg) -> Bool -> Maybe Color -> List (Svg msg)
drawSteps conf ( p1, dir1 ) ( p2, dir2 ) onHover nullable color =
    let
        break1 : Position
        break1 =
            case ( p1.left < p2.left, dir1, dir2 ) of
                ( True, Right, Left ) ->
                    p1 |> add ((p2.left - p1.left) / 2) dir1

                ( True, Right, Right ) ->
                    p1 |> add (p2.left - p1.left + arrowSize * 2) dir1

                ( True, Left, Left ) ->
                    p1 |> add (arrowSize * 2) dir1

                ( True, Left, Right ) ->
                    -- FIXME
                    p1 |> add (arrowSize * 2) dir1

                ( False, Right, Left ) ->
                    -- FIXME
                    p1 |> add (arrowSize * 2) dir1

                ( False, Right, Right ) ->
                    p1 |> add (arrowSize * 2) dir1

                ( False, Left, Left ) ->
                    p1 |> add (p1.left - p2.left + arrowSize * 2) dir1

                ( False, Left, Right ) ->
                    p1 |> add ((p1.left - p2.left) / 2) dir1

                _ ->
                    p1

        ( break1a, break1b ) =
            ( break1 |> Position.sub { left = arrowSize / 2 * apply dir1, top = 0 }
            , break1 |> Position.sub { left = 0, top = arrowSize / 2 * Bool.cond (p1.top > p2.top) 1 -1 }
            )

        break2 : Position
        break2 =
            { left = break1.left, top = p2.top }

        ( break2a, break2b ) =
            ( break2 |> Position.sub { left = 0, top = arrowSize / 2 * Bool.cond (p1.top < p2.top) 1 -1 }
            , break2 |> Position.sub { left = arrowSize / 2 * apply dir2, top = 0 }
            )

        path : List String
        path =
            [ moveTo (p1 |> Position.add { left = 0, top = negate (arrowSize / 2) })
            , lineTo (p1 |> add arrowSize dir1)
            , moveTo (p1 |> Position.add { left = 0, top = arrowSize / 2 })
            , lineTo (p1 |> add arrowSize dir1)
            , moveTo p1
            , lineTo break1a
            , curveTo break1a break1 break1b
            , lineTo break2a
            , curveTo break2a break2 break2b
            , lineTo p2
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


arrowSize : Float
arrowSize =
    10


add : Float -> Direction -> Position -> Position
add strength dir pos =
    pos |> Position.add { left = strength * apply dir, top = 0 }


apply : Direction -> Float
apply dir =
    case dir of
        Left ->
            -1

        Right ->
            1

        None ->
            0


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
            [ ( "straight", samples straight )
            , ( "bezier", samples bezier )
            , ( "steps", samples steps )
            , ( "green", div [ class "h-12" ] [ straight { hover = True } ( Position.zero, Right ) ( Position 50 50, Left ) False (Just Tw.green) "relation" 10 (\_ -> logAction "hover relation") ] )
            , ( "nullable", div [ class "h-12" ] [ straight { hover = True } ( Position.zero, Right ) ( Position 50 50, Left ) True Nothing "relation" 10 (\_ -> logAction "hover relation") ] )
            ]


samples : (RelationConf -> ( Position, Direction ) -> ( Position, Direction ) -> Bool -> Maybe Color -> String -> Int -> (Bool -> Msg state) -> Svg (Msg state)) -> Html (Msg state)
samples displayRelation =
    let
        ( p0, p55 ) =
            ( Position 0 0, Position 50 50 )

        ( p05, p50 ) =
            ( Position 0 50, Position 50 0 )

        dirs : List ( Direction, Direction )
        dirs =
            [ ( Right, Left )
            , ( Right, Right )
            , ( Left, Left )
            , ( Left, Right )
            ]
    in
    div []
        [ div [ class "flex flex-row h-12" ]
            ([ ( p0, p55 ), ( p05, p50 ) ]
                |> List.concatMap (\( src, ref ) -> dirs |> List.map (\( dir1, dir2 ) -> ( ( src, dir1 ), ( ref, dir2 ) )))
                |> List.map (\( src, ref ) -> div [ class "relative w-28" ] [ displayRelation { hover = True } src ref False Nothing "relation" 10 (\_ -> logAction "hover relation") ])
            )
        , div [ class "flex flex-row h-12 mt-6" ]
            ([ ( p55, p0 ), ( p50, p05 ) ]
                |> List.concatMap (\( src, ref ) -> dirs |> List.map (\( dir1, dir2 ) -> ( ( src, dir1 ), ( ref, dir2 ) )))
                |> List.map (\( src, ref ) -> div [ class "relative w-28" ] [ displayRelation { hover = True } src ref False Nothing "relation" 10 (\_ -> logAction "hover relation") ])
            )
        ]
