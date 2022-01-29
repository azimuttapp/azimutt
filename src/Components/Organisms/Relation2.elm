module Components.Organisms.Relation2 exposing (doc, line)

import ElmBook.Chapter as Chapter
import ElmBook.ElmCSS exposing (Chapter)
import Html exposing (div)
import Html.Attributes exposing (style)
import Libs.List as L
import Libs.Maybe as M
import Libs.Models.Color as Color exposing (Color)
import Libs.Models.Position as Position exposing (Position)
import Svg exposing (Svg, svg, text)
import Svg.Attributes exposing (class, height, strokeDasharray, width, x1, x2, y1, y2)
import Svg.Styled as Styled


line : Position -> Position -> Bool -> Maybe Color -> String -> Int -> Svg msg
line src ref nullable color label _ =
    let
        padding : Float
        padding =
            10

        origin : Position
        origin =
            { left = min src.left ref.left - padding, top = min src.top ref.top - padding }
    in
    svg
        [ width (String.fromFloat (abs (src.left - ref.left) + (padding * 2)))
        , height (String.fromFloat (abs (src.top - ref.top) + (padding * 2)))
        , class "tw-relation absolute transform"

        -- , css [ Tw.absolute, Tw.transform, Tu.translate_x_y origin.left origin.top "px", Tu.z index ]
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

            -- , css (color |> M.mapOrElse (\c -> [ Color.stroke c 500, Tu.stroke_3 ]) [ Color.stroke Color.default 400, Tw.stroke_2 ])
            -- , class (color |> M.mapOrElse (\c -> "stroke-" ++ c.name ++ "-500 stroke-3") ("stroke-" ++ Color.default.name ++ "-400 stroke-2"))
            , class (color |> M.mapOrElse (\_ -> "stroke-green-500 stroke-3") "stroke-slate-400 stroke-2")
            ]
        )
        []



-- DOCUMENTATION


doc : Chapter x
doc =
    Chapter.chapter "Relation2"
        |> Chapter.renderComponentList
            [ ( "line", Styled.fromUnstyled (div [ style "height" "100px" ] [ line Position.zero (Position 50 50) False Nothing "relation" 10 ]) )
            , ( "green", Styled.fromUnstyled (div [ style "height" "100px" ] [ line Position.zero (Position 50 50) False (Just Color.green) "relation" 10 ]) )
            ]
