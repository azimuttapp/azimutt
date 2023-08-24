module Components.Molecules.PieChartCustom exposing (Model, defaultPieChartCustom, doc, paletteChartJs, paletteElmViz, paletteLearnui, paletteRetroMetro, paletteSpringPastels, view)

import Array exposing (Array)
import Color exposing (Color)
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, div)
import Html.Attributes exposing (class, style)
import Libs.Color as Color
import Libs.List as List
import Path
import Shape exposing (PieConfig)
import TypedSvg exposing (g, svg, text_)
import TypedSvg.Attributes exposing (dy, fill, stroke, textAnchor, transform, viewBox)
import TypedSvg.Core exposing (Svg, text)
import TypedSvg.Types exposing (AnchorAlignment(..), Paint(..), Transform(..), em)



-- see https://elm-visualization.netlify.app/piechart


type alias Model =
    { data : List ( String, Float ), width : Float, height : Float, colors : Array Color }


defaultPieChartCustom : Model
defaultPieChartCustom =
    { data = [ ( "/notifications", 2704659 ), ( "/about", 4499890 ), ( "/product", 2159981 ), ( "/blog", 3853788 ), ( "/shop", 14106543 ), ( "/profile", 8819342 ), ( "/", 612463 ), ( "/partners", 2540175 ), ( "/referral", 7048517 ), ( "/demo", 9630471 ) ]
    , width = 250
    , height = 250
    , colors = paletteSpringPastels
    }


view : Model -> Svg msg
view model =
    let
        radius : Float
        radius =
            min model.width model.height / 2

        conf : PieConfig ( String, Float )
        conf =
            { startAngle = 0
            , endAngle = 2 * pi
            , padAngle = 0
            , sortingFn = \( _, v1 ) ( _, v2 ) -> Basics.compare v2 v1
            , valueFn = Tuple.second
            , innerRadius = 0
            , outerRadius = radius
            , cornerRadius = 0
            , padRadius = 0
            }

        pieData : List ( Shape.Arc, ( String, Float ) )
        pieData =
            model.data |> Shape.pie conf |> List.zip model.data
    in
    svg [ viewBox 0 0 model.width model.height ]
        [ g [ transform [ Translate (model.width / 2) (model.height / 2) ] ]
            (if model.data |> List.isEmpty then
                [ text_ [] [ text "No data" ] ]

             else
                [ g [] (pieData |> List.indexedMap (viewSlice model.colors))
                , g [] (pieData |> List.map (viewLabel radius))
                ]
            )
        ]


viewSlice : Array Color -> Int -> ( Shape.Arc, ( String, Float ) ) -> Svg msg
viewSlice colors index ( datum, _ ) =
    Path.element (Shape.arc datum)
        [ fill (colors |> Array.get (modBy (colors |> Array.length) index) |> Maybe.withDefault Color.black |> Paint)
        , stroke (Paint Color.white)
        ]


viewLabel : Float -> ( Shape.Arc, ( String, Float ) ) -> Svg msg
viewLabel radius ( slice, ( label, _ ) ) =
    let
        ( x, y ) =
            Shape.centroid { slice | innerRadius = radius - 40, outerRadius = radius - 40 }
    in
    text_
        [ transform [ Translate x y ]
        , dy (em 0.35)
        , textAnchor AnchorMiddle
        ]
        [ text label ]


paletteElmViz : Array Color
paletteElmViz =
    -- 7 colors
    [ Color.rgb255 152 171 198, Color.rgb255 138 137 166, Color.rgb255 123 104 136, Color.rgb255 107 72 107, Color.rgb255 159 92 85, Color.rgb255 208 116 60, Color.rgb255 255 96 0 ] |> Array.fromList


paletteLearnui : Array Color
paletteLearnui =
    -- 8 colors: https://www.learnui.design/tools/data-color-picker.html
    [ "#003f5c", "#2f4b7c", "#665191", "#a05195", "#d45087", "#f95d6a", "#ff7c43", "#ffa600" ] |> List.filterMap Color.fromHex |> Array.fromList


paletteChartJs : Array Color
paletteChartJs =
    -- 7 colors https://www.chartjs.org/docs/latest/general/colors.html#default-color-palette
    [ "#36a2eb", "#ff6384", "#4bc0c0", "#ff9f40", "#9966ff", "#ffcd56", "#c9cbcf" ] |> List.filterMap Color.fromHex |> Array.fromList


paletteRetroMetro : Array Color
paletteRetroMetro =
    -- 9 colors: https://www.heavy.ai/blog/12-color-palettes-for-telling-better-stories-with-your-data
    [ "#ea5545", "#f46a9b", "#ef9b20", "#edbf33", "#ede15b", "#bdcf32", "#87bc45", "#27aeef", "#b33dc6" ] |> List.filterMap Color.fromHex |> Array.fromList


paletteSpringPastels : Array Color
paletteSpringPastels =
    -- 9 colors: https://www.heavy.ai/blog/12-color-palettes-for-telling-better-stories-with-your-data
    [ "#fd7f6f", "#7eb0d5", "#b2e061", "#bd7ebe", "#ffb55a", "#ffee65", "#beb9db", "#fdcce5", "#8bd3c7" ] |> List.filterMap Color.fromHex |> Array.fromList



-- DOCUMENTATION


doc : Chapter x
doc =
    Chapter.chapter "PieChartCustom"
        |> Chapter.renderComponentList
            [ ( "default", docPieChart defaultPieChartCustom )
            , ( "number of segments"
              , div []
                    [ div [ class "flex" ] (List.range 1 5 |> List.map (\nb -> docPieChart { defaultPieChartCustom | data = defaultPieChartCustom.data |> List.take nb }))
                    , div [ class "flex" ] (List.range 6 10 |> List.map (\nb -> docPieChart { defaultPieChartCustom | data = defaultPieChartCustom.data |> List.take nb }))
                    ]
              )
            , ( "color palettes"
              , div [ class "flex" ]
                    ([ ( paletteElmViz, "paletteElmViz" ), ( paletteLearnui, "paletteLearnui" ), ( paletteChartJs, "paletteChartJs" ), ( paletteRetroMetro, "paletteRetroMetro" ), ( paletteSpringPastels, "paletteSpringPastels" ) ]
                        |> List.map (\( colors, name ) -> div [ class "text-center" ] [ docPieChart { defaultPieChartCustom | colors = colors }, text name ])
                    )
              )
            , ( "long labels", docPieChart { defaultPieChartCustom | data = [ ( "21cf8706-7d28-4a52-b520-bcd5065807d9", 10 ), ( "54a00ec5-dc80-4760-8098-d79c899dc0f6", 10 ), ( "327a8ce3-a924-4a56-89c0-f968f597343b", 10 ) ] } )
            , ( "empty", docPieChart { defaultPieChartCustom | data = [] } )
            ]


docPieChart : Model -> Html msg
docPieChart model =
    div [ style "width" (String.fromFloat model.width ++ "px"), style "height" (String.fromFloat model.height ++ "px") ] [ view model ]
