module Components.Organisms.Relation exposing (Model, doc, relation)

import ElmBook.Chapter as Chapter
import ElmBook.ElmCSS exposing (Chapter)
import Libs.List as L
import Libs.Maybe as M
import Libs.Models.Color as Color exposing (Color)
import Libs.Models.Position as Position exposing (Position)
import Libs.Tailwind.Utilities as Tu
import Svg.Styled exposing (Svg, line, svg, text)
import Svg.Styled.Attributes exposing (class, css, height, strokeDasharray, width, x1, x2, y1, y2)
import Tailwind.Utilities as Tw


type alias Model =
    { src : Position
    , ref : Position
    , nullable : Bool
    , color : Maybe Color
    , label : String
    , index : Int
    }


relation : Model -> Svg msg
relation model =
    let
        padding : Float
        padding =
            10

        origin : Position
        origin =
            { left = min model.src.left model.ref.left - padding, top = min model.src.top model.ref.top - padding }
    in
    svg
        [ class "tw-relation"
        , width (String.fromFloat (abs (model.src.left - model.ref.left) + (padding * 2)))
        , height (String.fromFloat (abs (model.src.top - model.ref.top) + (padding * 2)))
        , css [ Tw.absolute, Tw.transform, Tu.translate_x_y origin.left origin.top "px", Tu.z model.index ]
        ]
        [ viewLine (model.src |> Position.sub origin) (model.ref |> Position.sub origin) model.nullable model.color
        , text model.label
        ]


viewLine : Position -> Position -> Bool -> Maybe Color -> Svg msg
viewLine p1 p2 nullable color =
    line
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
            [ ( "relation"
              , relation
                    { src = Position 0 0
                    , ref = Position 50 50
                    , nullable = False
                    , color = Nothing
                    , label = "relation"
                    , index = 10
                    }
              )
            ]
