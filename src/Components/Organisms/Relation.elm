module Components.Organisms.Relation exposing (doc, line)

import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (div)
import Html.Attributes as Html
import Libs.List as L
import Libs.Maybe as M
import Libs.Models.Color as Color exposing (Color)
import Libs.Models.Position as Position exposing (Position)
import Libs.Svg.Attributes exposing (css)
import Libs.Tailwind exposing (stroke_500)
import Svg exposing (Svg, svg, text)
import Svg.Attributes exposing (height, strokeDasharray, style, width, x1, x2, y1, y2)


line : Position -> Position -> Bool -> Maybe Color -> String -> Int -> Svg msg
line src ref nullable color label index =
    let
        padding : Float
        padding =
            10

        origin : Position
        origin =
            { left = min src.left ref.left - padding, top = min src.top ref.top - padding }
    in
    svg
        [ css [ "tw-relation absolute" ]
        , width (String.fromFloat (abs (src.left - ref.left) + (padding * 2)))
        , height (String.fromFloat (abs (src.top - ref.top) + (padding * 2)))
        , style ("left: " ++ String.fromFloat origin.left ++ "px; top: " ++ String.fromFloat origin.top ++ "px; z-index: " ++ String.fromInt index ++ ";")

        --, style ("transform: translate(" ++ String.fromFloat origin.left ++ "px, " ++ String.fromFloat origin.top ++ "px); z-index: " ++ String.fromInt index ++ ";")
        --, style ("transform: translate3d(" ++ String.fromFloat origin.left ++ "px, " ++ String.fromFloat origin.top ++ "px, 0); z-index: " ++ String.fromInt index ++ ";")
        ]
        [ viewLine (src |> Position.sub origin) (ref |> Position.sub origin) nullable color
        , text label
        ]


viewLine : Position -> Position -> Bool -> Maybe Color -> Svg msg
viewLine p1 p2 nullable color =
    Svg.line
        (L.prependIf nullable
            (strokeDasharray "4")
            [ x1 (String.fromFloat p1.left)
            , y1 (String.fromFloat p1.top)
            , x2 (String.fromFloat p2.left)
            , y2 (String.fromFloat p2.top)
            , css (color |> M.mapOrElse (\c -> [ stroke_500 c, "stroke-3" ]) [ "stroke-default-400 stroke-2" ])
            ]
        )
        []



-- DOCUMENTATION


doc : Chapter x
doc =
    Chapter.chapter "Relation"
        |> Chapter.renderComponentList
            ([ ( "line", line Position.zero (Position 50 50) False Nothing "relation" 10 )
             , ( "green", line Position.zero (Position 50 50) False (Just Color.green) "relation" 10 )
             , ( "nullable", line Position.zero (Position 50 50) True Nothing "relation" 10 )
             ]
                |> List.map (Tuple.mapSecond (\component -> div [ Html.style "height" "100px" ] [ component ]))
            )
