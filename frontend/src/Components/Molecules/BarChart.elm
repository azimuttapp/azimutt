module Components.Molecules.BarChart exposing (Model, defaultBarChart, doc, view)

import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (text)
import Svg exposing (Svg)



--import Vectual.BarChart as BarChart exposing (defaultBarChartConfig)
--import Vectual.Types as Types
-- see https://vectual.org


type alias Model =
    { data : List ( String, Float ), width : Int, height : Int, title : String }


defaultBarChart : Model
defaultBarChart =
    { data = [ ( "/notifications", 2704659 ), ( "/about", 4499890 ), ( "/product", 2159981 ), ( "/blog", 3853788 ), ( "/shop", 14106543 ), ( "/profile", 8819342 ), ( "/", 612463 ), ( "/partners", 2540175 ), ( "/referral", 7048517 ), ( "/demo", 9630471 ) ]
    , width = 600
    , height = 300
    , title = "" -- defaultBarChartConfig.title
    }


view : Model -> Svg msg
view _ =
    --BarChart.viewBarChart { defaultBarChartConfig | width = model.width, height = model.height, title = model.title }
    --    (Types.KeyData (model.data |> List.take 1 |> List.map (\( key, value ) -> { key = key, value = value, offset = 0 })))
    text "TODO: BarChart.viewBarChart"



-- DOCUMENTATION


doc : Chapter x
doc =
    Chapter.chapter "BarChart"
        |> Chapter.renderComponentList
            [ ( "warning", text "Not sure why but even basic BarChart kills the browser :/" )

            --  ( "default", view defaultBarChart )
            --, ( "number of segments"
            --  , div []
            --        [ div [ class "flex" ] (List.range 1 3 |> List.map (\nb -> view { defaultBarChart | data = defaultBarChart.data |> List.take nb }))
            --        , div [ class "flex" ] (List.range 4 6 |> List.map (\nb -> view { defaultBarChart | data = defaultBarChart.data |> List.take nb }))
            --        , div [ class "flex" ] (List.range 7 9 |> List.map (\nb -> view { defaultBarChart | data = defaultBarChart.data |> List.take nb }))
            --        ]
            --  )
            --, ( "long labels", view { defaultBarChart | data = [ ( "21cf8706-7d28-4a52-b520-bcd5065807d9", 10 ), ( "54a00ec5-dc80-4760-8098-d79c899dc0f6", 10 ), ( "327a8ce3-a924-4a56-89c0-f968f597343b", 10 ) ] } )
            --, ( "empty", view { defaultBarChart | data = [] } )
            ]
