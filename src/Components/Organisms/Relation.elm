module Components.Organisms.Relation exposing (doc, line)

import ElmBook.Chapter as Chapter
import ElmBook.ElmCSS exposing (Chapter)
import Libs.List as L
import Libs.Maybe as M
import Libs.Models.Color as Color exposing (Color)
import Libs.Models.Position as Position exposing (Position)
import Libs.Tailwind.Utilities as Tu
import Svg.Styled as Svg exposing (Svg, svg, text)
import Svg.Styled.Attributes exposing (class, css, height, strokeDasharray, width, x1, x2, y1, y2)
import Tailwind.Utilities as Tw


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
        [ class "tw-relation"
        , width (String.fromFloat (abs (src.left - ref.left) + (padding * 2)))
        , height (String.fromFloat (abs (src.top - ref.top) + (padding * 2)))
        , css [ Tw.absolute, Tw.transform, Tu.translate_x_y origin.left origin.top "px", Tu.z index ]
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
            , css (color |> M.mapOrElse (\c -> [ Color.stroke c 500, Tu.stroke_3 ]) [ Color.stroke Color.default 400, Tw.stroke_2 ])
            ]
        )
        []



-- DOCUMENTATION


doc : Chapter x
doc =
    Chapter.chapter "Relation"
        |> Chapter.renderComponentList
            [ ( "line", line Position.zero (Position 50 50) False Nothing "relation" 10 )
            ]
