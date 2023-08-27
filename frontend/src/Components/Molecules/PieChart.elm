module Components.Molecules.PieChart exposing (Model, defaultPieChart, doc, view)

import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (div)
import Html.Attributes exposing (class)
import Svg exposing (Svg, text)



--import Vectual.PieChart as PieChart exposing (defaultPieChartConfig)
--import Vectual.Types
-- see https://vectual.org
-- `elm install adius/vectual` => version 4.0.0 has incompatibilities with `elm-explorations/test` :/
-- `elm-json uninstall adius/vectual`
-- TODO: callback on slice click


type alias Model =
    { data : List ( String, Float ), width : Int, height : Int, title : String }


defaultPieChart : Model
defaultPieChart =
    { data = [ ( "/notifications", 2704659 ), ( "/about", 4499890 ), ( "/product", 2159981 ), ( "/blog", 3853788 ), ( "/shop", 14106543 ), ( "/profile", 8819342 ), ( "/", 612463 ), ( "/partners", 2540175 ), ( "/referral", 7048517 ), ( "/demo", 9630471 ) ]
    , width = 600
    , height = 300
    , title = "" -- defaultPieChartConfig.title
    }


view : Model -> Svg msg
view _ =
    --PieChart.viewPieChart { defaultPieChartConfig | width = model.width, height = model.height, title = model.title, showAnimations = True }
    --    (Vectual.Types.KeyData (model.data |> List.map (\( key, value ) -> { key = key, value = value, offset = 0 })))
    text "TODO: PieChart.viewPieChart"



-- DOCUMENTATION


doc : Chapter x
doc =
    Chapter.chapter "PieChart"
        |> Chapter.renderComponentList
            [ ( "default", view defaultPieChart )
            , ( "number of segments"
              , div []
                    [ div [ class "flex" ] (List.range 1 3 |> List.map (\nb -> view { defaultPieChart | data = defaultPieChart.data |> List.take nb }))
                    , div [ class "flex" ] (List.range 4 6 |> List.map (\nb -> view { defaultPieChart | data = defaultPieChart.data |> List.take nb }))
                    , div [ class "flex" ] (List.range 7 9 |> List.map (\nb -> view { defaultPieChart | data = defaultPieChart.data |> List.take nb }))
                    ]
              )
            , ( "long labels", view { defaultPieChart | data = [ ( "21cf8706-7d28-4a52-b520-bcd5065807d9", 10 ), ( "54a00ec5-dc80-4760-8098-d79c899dc0f6", 10 ), ( "327a8ce3-a924-4a56-89c0-f968f597343b", 10 ) ] } )
            , ( "empty", view { defaultPieChart | data = [] } )
            ]
