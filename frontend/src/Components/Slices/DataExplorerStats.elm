module Components.Slices.DataExplorerStats exposing (doc, view)

import Components.Atoms.Icon as Icon
import Components.Molecules.PieChart as PieChart exposing (defaultPieChart)
import Components.Molecules.PieChartCustom as PieChartCustom exposing (defaultPieChartCustom)
import Dict exposing (Dict)
import ElmBook
import ElmBook.Actions exposing (logAction)
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, button, div, h3, p, span, text)
import Html.Attributes exposing (class, id, style, type_)
import Html.Events exposing (onClick)
import Libs.Bool as Bool
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Nel as Nel exposing (Nel)
import Libs.String as String
import Models.DbValue as DbValue exposing (DbValue(..))
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPathStr)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.TableName exposing (TableName)
import Models.QueryResult exposing (QueryResultColumn, QueryResultColumnTarget, QueryResultRow)
import Round


view : QueryResultColumnTarget -> List DbValue -> msg -> HtmlId -> Html msg
view column values close htmlId =
    let
        ( ( strings, ints, floats ), ( bools, arrays, objects ), nulls ) =
            values |> partitionByType
    in
    div [ class "flex min-h-full items-end justify-center p-4 text-center sm:items-center sm:p-0" ]
        [ div [ class "p-4 relative overflow-hidden rounded-lg bg-white text-left shadow-xl" ]
            [ div [ class "absolute right-0 top-0 hidden pr-4 pt-4 sm:block" ]
                [ button [ type_ "button", onClick close, class "rounded-md bg-white text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2" ]
                    [ span [ class "sr-only" ] [ text "Close" ], Icon.solid Icon.X "h-6 w-6" ]
                ]
            , div [ class "text-left" ]
                [ h3 [ class "mr-7 text-base font-semibold leading-6 text-gray-900", id htmlId ] [ text (String.fromInt (List.length values) ++ " values for column: " ++ column.pathStr) ]
                , case
                    ( ( strings |> Nel.fromList |> Maybe.map (computeStats identity (String.length >> toFloat)), ints |> Nel.fromList |> Maybe.map (computeStats String.fromInt toFloat), floats |> Nel.fromList |> Maybe.map (computeStats String.fromFloat identity) )
                    , ( bools |> Nel.fromList |> Maybe.map (computeStats Bool.toString (\b -> Bool.cond b 1 0)), arrays |> Nel.fromList |> Maybe.map (computeStats (DbArray >> DbValue.toString) (List.length >> toFloat)), objects |> Nel.fromList |> Maybe.map (computeStats (DbObject >> DbValue.toString) (Dict.size >> toFloat)) )
                    )
                  of
                    -- TODO: handle time values for String
                    ( ( Nothing, Nothing, Nothing ), ( Nothing, Nothing, Nothing ) ) ->
                        div [] []

                    ( ( Just stats, Nothing, Nothing ), ( Nothing, Nothing, Nothing ) ) ->
                        stats |> viewStringStats nulls

                    ( ( Nothing, Just stats, Nothing ), ( Nothing, Nothing, Nothing ) ) ->
                        stats |> viewIntStats nulls

                    ( ( Nothing, Nothing, Just stats ), ( Nothing, Nothing, Nothing ) ) ->
                        stats |> viewFloatStats nulls

                    ( ( Nothing, Nothing, Nothing ), ( Just stats, Nothing, Nothing ) ) ->
                        stats |> viewBoolStats nulls

                    ( ( Nothing, Nothing, Nothing ), ( Nothing, Just stats, Nothing ) ) ->
                        stats |> viewArrayStats nulls

                    ( ( Nothing, Nothing, Nothing ), ( Nothing, Nothing, Just stats ) ) ->
                        stats |> viewObjectStats nulls

                    ( ( stringStats, intStats, floatStats ), ( boolStats, arrayStats, objectStats ) ) ->
                        viewMixedStats nulls stringStats intStats floatStats boolStats arrayStats objectStats
                ]
            ]
        ]


partitionByType : List DbValue -> ( ( List String, List Int, List Float ), ( List Bool, List (List DbValue), List (Dict String DbValue) ), Int )
partitionByType values =
    values
        |> List.foldr
            (\value ( ( strings, ints, floats ), ( bools, arrays, objects ), nulls ) ->
                case value of
                    DbString v ->
                        ( ( v :: strings, ints, floats ), ( bools, arrays, objects ), nulls )

                    DbInt v ->
                        ( ( strings, v :: ints, floats ), ( bools, arrays, objects ), nulls )

                    DbFloat v ->
                        ( ( strings, ints, v :: floats ), ( bools, arrays, objects ), nulls )

                    DbBool v ->
                        ( ( strings, ints, floats ), ( v :: bools, arrays, objects ), nulls )

                    DbNull ->
                        ( ( strings, ints, floats ), ( bools, arrays, objects ), nulls + 1 )

                    DbArray v ->
                        ( ( strings, ints, floats ), ( bools, v :: arrays, objects ), nulls )

                    DbObject v ->
                        ( ( strings, ints, floats ), ( bools, arrays, v :: objects ), nulls )
            )
            ( ( [], [], [] ), ( [], [], [] ), 0 )


type alias Distinct a =
    { value : a, valueStr : String, valueNum : Float, count : Int }


type alias Stats a =
    { min : Float, max : Float, avg : Float, count : Int, cardinality : Int, distinct : List (Distinct a) }


viewStringStats : Int -> Stats String -> Html msg
viewStringStats nulls stats =
    div []
        [ viewPieChart ({ value = "Null", count = nulls } :: (stats.distinct |> List.map (\v -> { value = v.valueStr, count = v.count })))
        , p [ class "text-sm text-gray-500" ] [ text (String.fromInt stats.cardinality ++ " distinct values") ]
        , p [ class "text-sm text-gray-500" ] [ text ("Minimum length: " ++ viewNum stats.min) ]
        , p [ class "text-sm text-gray-500" ] [ text ("Maximum length: " ++ viewNum stats.max) ]
        , p [ class "text-sm text-gray-500" ] [ text ("Average length: " ++ viewNum stats.avg) ]
        ]


viewIntStats : Int -> Stats Int -> Html msg
viewIntStats nulls stats =
    div []
        [ viewPieChart ({ value = "Null", count = nulls } :: (stats.distinct |> List.map (\v -> { value = v.valueStr, count = v.count })))
        , p [ class "text-sm text-gray-500" ] [ text (String.fromInt stats.cardinality ++ " distinct values") ]
        , p [ class "text-sm text-gray-500" ] [ text ("Minimum: " ++ viewNum stats.min) ]
        , p [ class "text-sm text-gray-500" ] [ text ("Maximum: " ++ viewNum stats.max) ]
        , p [ class "text-sm text-gray-500" ] [ text ("Average: " ++ viewNum stats.avg) ]
        ]


viewFloatStats : Int -> Stats Float -> Html msg
viewFloatStats nulls stats =
    div []
        [ viewPieChart ({ value = "Null", count = nulls } :: (stats.distinct |> List.map (\v -> { value = v.valueStr, count = v.count })))
        , p [ class "text-sm text-gray-500" ] [ text (String.fromInt stats.cardinality ++ " distinct values") ]
        , p [ class "text-sm text-gray-500" ] [ text ("Minimum: " ++ viewNum stats.min) ]
        , p [ class "text-sm text-gray-500" ] [ text ("Maximum: " ++ viewNum stats.max) ]
        , p [ class "text-sm text-gray-500" ] [ text ("Average: " ++ viewNum stats.avg) ]
        ]


viewBoolStats : Int -> Stats Bool -> Html msg
viewBoolStats nulls stats =
    div []
        [ viewPieChart ({ value = "Null", count = nulls } :: (stats.distinct |> List.map (\v -> { value = v.valueStr, count = v.count })))
        ]


viewArrayStats : Int -> Stats (List DbValue) -> Html msg
viewArrayStats nulls stats =
    div []
        [ viewPieChart ({ value = "Null", count = nulls } :: (stats.distinct |> List.map (\v -> { value = v.valueStr, count = v.count })))
        , p [ class "text-sm text-gray-500" ] [ text (String.fromInt stats.cardinality ++ " distinct values") ]
        , p [ class "text-sm text-gray-500" ] [ text ("Minimum length: " ++ viewNum stats.min) ]
        , p [ class "text-sm text-gray-500" ] [ text ("Maximum length: " ++ viewNum stats.max) ]
        , p [ class "text-sm text-gray-500" ] [ text ("Average length: " ++ viewNum stats.avg) ]
        ]


viewObjectStats : Int -> Stats (Dict String DbValue) -> Html msg
viewObjectStats nulls stats =
    div []
        [ viewPieChart ({ value = "Null", count = nulls } :: (stats.distinct |> List.map (\v -> { value = v.valueStr, count = v.count })))
        , p [ class "text-sm text-gray-500" ] [ text (String.fromInt stats.cardinality ++ " distinct values") ]
        , p [ class "text-sm text-gray-500" ] [ text ("Minimum props: " ++ viewNum stats.min) ]
        , p [ class "text-sm text-gray-500" ] [ text ("Maximum props: " ++ viewNum stats.max) ]
        , p [ class "text-sm text-gray-500" ] [ text ("Average props: " ++ viewNum stats.avg) ]
        ]


viewMixedStats : Int -> Maybe (Stats String) -> Maybe (Stats Int) -> Maybe (Stats Float) -> Maybe (Stats Bool) -> Maybe (Stats (List DbValue)) -> Maybe (Stats (Dict String DbValue)) -> Html msg
viewMixedStats nulls stringStats intStats floatStats boolStats arrayStats objectStats =
    let
        data : List { value : String, count : Int }
        data =
            (stringStats |> Maybe.toList |> List.map (\s -> { value = "String", count = s.count }))
                ++ (intStats |> Maybe.toList |> List.map (\s -> { value = "Int", count = s.count }))
                ++ (floatStats |> Maybe.toList |> List.map (\s -> { value = "Float", count = s.count }))
                ++ (boolStats |> Maybe.toList |> List.map (\s -> { value = "Bool", count = s.count }))
                ++ (arrayStats |> Maybe.toList |> List.map (\s -> { value = "Array", count = s.count }))
                ++ (objectStats |> Maybe.toList |> List.map (\s -> { value = "Object", count = s.count }))
                ++ Bool.cond (nulls /= 0) [ { value = "Null", count = nulls } ] []
    in
    div []
        [ viewPieChart data
        ]


viewPieChart : List { value : String, count : Int } -> Html msg
viewPieChart values =
    -- TODO: instead of "just" PieChart, add tabs with pie chart, bar chart, histogram, value list
    let
        maxSlices : Int
        maxSlices =
            10

        sorted : List { value : String, count : Int }
        sorted =
            values |> List.filter (\v -> v.count > 0) |> List.sortBy (.count >> negate)

        data : List { value : String, count : Int }
        data =
            if List.length sorted > maxSlices then
                sorted |> List.take (maxSlices - 1) |> List.add { value = "Other values", count = sorted |> List.drop (maxSlices - 1) |> List.map .count |> List.sum }

            else
                sorted
    in
    --PieChart.view { defaultPieChart | data = data |> List.map (\v -> ( v.value, toFloat v.count )) }
    div [ style "width" "600px", style "height" "300px" ] [ PieChartCustom.view { defaultPieChartCustom | data = data |> List.map (\v -> ( v.value, toFloat v.count )), width = 600, height = 300 } ]


viewNum : Float -> String
viewNum value =
    Round.round 2 value |> String.stripRight ".00"


computeStats : (a -> String) -> (a -> Float) -> Nel a -> Stats a
computeStats toString toNum values =
    let
        distinct : List (Distinct a)
        distinct =
            values |> computeDistinct toString toNum

        -- percentiles: 10, 25, 50, 75, 90
        -- most frequent values => pie chart
        -- histogram => bar chart (split range in 10 buckets)
        -- box plot (https://elm-visualization.netlify.app/boxplot) => add tabs under the chart to choose (pie, bar, line, box plot)
    in
    { min = distinct |> List.minimumBy .valueNum |> Maybe.mapOrElse .valueNum (toNum values.head)
    , max = distinct |> List.maximumBy .valueNum |> Maybe.mapOrElse .valueNum (toNum values.head)
    , avg = (distinct |> List.map (\v -> v.valueNum * toFloat v.count) |> List.sum) / (values |> Nel.length |> toFloat)
    , count = values |> Nel.length
    , cardinality = distinct |> List.length
    , distinct = distinct
    }


computeDistinct : (a -> String) -> (a -> Float) -> Nel a -> List (Distinct a)
computeDistinct toString toNum values =
    values
        |> Nel.toList
        |> List.groupBy toString
        |> Dict.toList
        |> List.map (\( key, list ) -> list |> List.head |> Maybe.withDefault values.head |> (\v -> { value = v, valueStr = key, valueNum = toNum v, count = List.length list }))
        |> List.sortBy (.count >> negate)



-- DOCUMENTATION


doc : Chapter x
doc =
    Chapter.chapter "DataExplorerStats"
        |> Chapter.renderComponentList
            [ ( "string"
              , div [ class "flex bg-gray-100 p-3 space-x-3" ]
                    [ view (docColumnTarget "name") (docCityValues.rows |> List.filterMap (Dict.get "name")) docClose "html-id"
                    , view (docColumnTarget "country_code") (docCityValues.rows |> List.filterMap (Dict.get "country_code")) docClose "html-id"
                    ]
              )
            , ( "int"
              , div [ class "flex bg-gray-100 p-3 space-x-3" ]
                    [ view (docColumnTarget "population") (docCityValues.rows |> List.filterMap (Dict.get "population")) docClose "html-id"
                    , view (docColumnTarget "id") (docCityValues.rows |> List.filterMap (Dict.get "id")) docClose "html-id"
                    ]
              )
            , ( "float"
              , div [ class "flex bg-gray-100 p-3 space-x-3" ]
                    [ view (docColumnTarget "diameter") (docCityValues.rows |> List.filterMap (Dict.get "diameter")) docClose "html-id"
                    , view (docColumnTarget "diameter") ([ 3.78, 25.23, 28.44, 9.82, 2.64, 21.56, 18.85, 5.63, 27, 24.92, 12.41, 27.68, 7.27, 26.9, 13.54, 29.99, 27.8, 10.67, 15.47, 2.32, 15.41, 6.13, 23.38, 13.74, 16.05, 21.66, 14.12, 19.23, 11.3, 24.17, 9.41, 2.19, 21.37, 13.74, 20.01, 24.22, 11.15, 21.46, 27.02, 19.08, 19.86, 6.55, 16.11, 13.6, 27.78, 11.18, 7.42, 7.02, 3.75, 19.21 ] |> List.map DbFloat) docClose "html-id"
                    ]
              )
            , ( "bool", div [ class "flex bg-gray-100 p-3 space-x-3" ] [ view (docColumnTarget "capital") (docCityValues.rows |> List.filterMap (Dict.get "capital")) docClose "html-id" ] )
            , ( "array", div [ class "flex bg-gray-100 p-3 space-x-3" ] [ view (docColumnTarget "tags") (docCityValues.rows |> List.filterMap (Dict.get "tags")) docClose "html-id" ] )
            , ( "object", div [ class "flex bg-gray-100 p-3 space-x-3" ] [ view (docColumnTarget "details") (docCityValues.rows |> List.filterMap (Dict.get "details")) docClose "html-id" ] )
            , ( "mixed types", div [ class "flex bg-gray-100 p-3 space-x-3" ] [ view (docColumnTarget "json") [ DbBool True, DbInt 3, DbInt 4, DbInt 5, DbString "aaa", DbNull, DbNull ] docClose "html-id" ] )
            ]


docCityValues : { columns : List QueryResultColumn, rows : List QueryResultRow }
docCityValues =
    { columns = [ "id", "name", "country_code", "district", "population", "diameter", "capital", "tags", "details" ] |> List.map (docColumn "public" "city")
    , rows =
        [ docCityColumnValues 1 "Kabul" "AFG" "Kabol" 1780000 10.2 True ([ "capital", "top50", "top100" ] |> List.map DbString) ([ ( "plan", DbString "pro" ) ] |> Dict.fromList)
        , docCityColumnValues 2 "Qandahar" "AFG" "Qandahar" 237500 12.71 True ([ "top50", "top100" ] |> List.map DbString) ([] |> Dict.fromList)
        , docCityColumnValues 3 "Herat" "AFG" "Herat" 186800 9.55 False [] ([] |> Dict.fromList)
        , docCityColumnValues 4 "Mazar-e-Sharif" "AFG" "Balkh" 127800 22.72 False [] ([] |> Dict.fromList)
        , docCityColumnValues 5 "Amsterdam" "NLD" "Noord-Holland" 731200 12.81 True ([ "top50", "top100" ] |> List.map DbString) ([] |> Dict.fromList)
        , docCityColumnValues 6 "Rotterdam" "NLD" "Zuid-Holland" 593321 2.1 True ([ "top50", "top100" ] |> List.map DbString) ([] |> Dict.fromList)
        , docCityColumnValues 7 "Haag" "NLD" "Zuid-Holland" 440900 0.2 False [] ([] |> Dict.fromList)
        , docCityColumnValues 8 "Utrecht" "NLD" "Utrecht" 234323 0.2 False [] ([ ( "plan", DbString "pro" ) ] |> Dict.fromList)
        , docCityColumnValues 9 "Eindhoven" "NLD" "Noord-Brabant" 201843 0.2 False [] ([] |> Dict.fromList)
        , docCityColumnValues 10 "Tilburg" "NLD" "Noord-Brabant" 193238 0.2 False [] ([] |> Dict.fromList)
        , docCityColumnValues 11 "Groningen" "NLD" "Groningen" 172701 0.2 False [] ([ ( "plan", DbString "pro" ), ( "referral", DbString "google" ) ] |> Dict.fromList)
        , docCityColumnValues 12 "Breda" "NLD" "Noord-Brabant" 160398 0.2 False [] ([] |> Dict.fromList)
        , docCityColumnValues 13 "Apeldoorn" "NLD" "Gelderland" 153491 0.2 False [] ([] |> Dict.fromList)
        , docCityColumnValues 14 "Nijmegen" "NLD" "Gelderland" 152463 0.2 False [] ([] |> Dict.fromList)
        , docCityColumnValues 15 "Enschede" "NLD" "Overijssel" 149544 0.2 False [] ([ ( "plan", DbString "free" ), ( "referral", DbString "twitter" ) ] |> Dict.fromList)
        , docCityColumnValues 16 "Haarlem" "NLD" "Noord-Holland" 148772 0.2 False [] ([] |> Dict.fromList)
        , docCityColumnValues 17 "Almere" "NLD" "Flevoland" 142465 0.2 False [] ([] |> Dict.fromList)
        , docCityColumnValues 18 "Arnhem" "NLD" "Gelderland" 138020 0.2 False [] ([] |> Dict.fromList)
        , docCityColumnValues 19 "Zaanstad" "NLD" "Noord-Holland" 135621 0.2 False [] ([ ( "plan", DbString "pro" ) ] |> Dict.fromList)
        , docCityColumnValues 20 "´s-Hertogenbosch" "NLD" "Noord-Brabant" 129170 0.2 False [] ([] |> Dict.fromList)
        , docCityColumnValues 21 "Amersfoort" "NLD" "Utrecht" 126270 0.2 False [] ([] |> Dict.fromList)
        , docCityColumnValues 22 "Maastricht" "NLD" "Limburg" 122087 0.2 True [] ([ ( "plan", DbString "free" ), ( "referral", DbString "google" ) ] |> Dict.fromList)
        , docCityColumnValues 23 "Dordrecht" "NLD" "Zuid-Holland" 119811 0.2 False [] ([] |> Dict.fromList)
        , docCityColumnValues 24 "Leiden" "NLD" "Zuid-Holland" 117196 0.2 False [] ([] |> Dict.fromList)
        , docCityColumnValues 25 "Haarlemmermeer" "NLD" "Noord-Holland" 110722 0.2 False [] ([] |> Dict.fromList)
        , docCityColumnValues 26 "Zoetermeer" "NLD" "Zuid-Holland" 110214 0.2 False [] ([] |> Dict.fromList)
        , docCityColumnValues 27 "Emmen" "NLD" "Drenthe" 105853 0.2 False [] ([] |> Dict.fromList)
        , docCityColumnValues 28 "Zwolle" "NLD" "Overijssel" 105819 0.2 False [] ([ ( "plan", DbString "free" ), ( "referral", DbString "twitter" ) ] |> Dict.fromList)
        , docCityColumnValues 29 "Ede" "NLD" "Gelderland" 101574 0.2 False [] ([] |> Dict.fromList)
        , docCityColumnValues 30 "Delft" "NLD" "Zuid-Holland" 95268 0.2 False [] ([] |> Dict.fromList)
        , docCityColumnValues 31 "Heerlen" "NLD" "Limburg" 95052 0.2 False [] ([] |> Dict.fromList)
        , docCityColumnValues 32 "Alkmaar" "NLD" "Noord-Holland" 92713 0.2 False [] ([ ( "plan", DbString "pro" ) ] |> Dict.fromList)
        , docCityColumnValues 33 "Willemstad" "ANT" "Curaçao" 2345 0.2 False [] ([] |> Dict.fromList)
        , docCityColumnValues 34 "Tirana" "ALB" "Tirana" 270000 0.2 False [] ([] |> Dict.fromList)
        , docCityColumnValues 35 "Alger" "DZA" "Alger" 2168000 0.2 True [] ([] |> Dict.fromList)
        , docCityColumnValues 36 "Oran" "DZA" "Oran" 609823 0.2 False [] ([] |> Dict.fromList)
        , docCityColumnValues 37 "Constantine" "DZA" "Constantine" 443727 0.2 False [] ([] |> Dict.fromList)
        , docCityColumnValues 38 "Annaba" "DZA" "Annaba" 222518 0.2 False [] ([] |> Dict.fromList)
        , docCityColumnValues 39 "Batna" "DZA" "Batna" 183377 0.2 False [] ([] |> Dict.fromList)
        , docCityColumnValues 40 "Sétif" "DZA" "Sétif" 179055 0.2 False [] ([] |> Dict.fromList)
        , docCityColumnValues 41 "Sidi Bel Abbès" "DZA" "Sidi Bel Abbès" 153106 0.2 False [] ([] |> Dict.fromList)
        , docCityColumnValues 42 "Skikda" "DZA" "Skikda" 128747 0.2 False [] ([] |> Dict.fromList)
        , docCityColumnValues 43 "Biskra" "DZA" "Biskra" 128281 0.2 False [] ([] |> Dict.fromList)
        , docCityColumnValues 44 "Blida (el-Boulaida)" "DZA" "Blida" 127284 0.2 False [] ([] |> Dict.fromList)
        , docCityColumnValues 45 "Béjaïa" "DZA" "Béjaïa" 117162 0.2 False [] ([] |> Dict.fromList)
        , docCityColumnValues 46 "Mostaganem" "DZA" "Mostaganem" 115212 0.2 False [] ([] |> Dict.fromList)
        , docCityColumnValues 47 "Tébessa" "DZA" "Tébessa" 112007 0.2 False [] ([] |> Dict.fromList)
        ]
    }


docColumn : SchemaName -> TableName -> ColumnPathStr -> QueryResultColumn
docColumn schema table pathStr =
    { path = ColumnPath.fromString pathStr, pathStr = pathStr, ref = Just { table = ( schema, table ), column = ColumnPath.fromString pathStr } }


docColumnTarget : String -> QueryResultColumnTarget
docColumnTarget name =
    { path = Nel name [], pathStr = name, ref = Nothing, fk = Nothing }


docCityColumnValues : Int -> String -> String -> String -> Int -> Float -> Bool -> List DbValue -> Dict String DbValue -> QueryResultRow
docCityColumnValues id name country_code district population diameter capital tags details =
    Dict.fromList
        [ ( "id", DbInt id )
        , ( "name", DbString name )
        , ( "country_code", DbString country_code )
        , ( "district", DbString district )
        , ( "population", DbInt population )
        , ( "diameter", DbFloat diameter )
        , ( "capital", DbBool capital )
        , ( "tags", DbArray tags )
        , ( "details", DbObject details )
        ]


docClose : ElmBook.Msg state
docClose =
    logAction "close"
