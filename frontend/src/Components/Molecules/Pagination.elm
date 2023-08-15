module Components.Molecules.Pagination exposing (Model, PageIndex, doc, paginate, view)

import ElmBook.Actions exposing (logActionWith)
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, button, div, nav, p, span, text)
import Html.Attributes exposing (class, type_)
import Html.Events exposing (onClick)
import Libs.Html.Attributes exposing (ariaCurrent)


type alias Model =
    { currentPage : Int
    , pageSize : Int
    , totalItems : Int
    }


type alias PageIndex =
    Int


paginate : List a -> Model -> List ( PageIndex, a )
paginate list model =
    let
        first : Int
        first =
            1 + ((model.currentPage - 1) * model.pageSize)
    in
    list |> List.drop (first - 1) |> List.take model.pageSize |> List.indexedMap (\i a -> ( first + i, a ))


view : (Int -> msg) -> Model -> Html msg
view changePage model =
    let
        first : Int
        first =
            1 + ((model.currentPage - 1) * model.pageSize)

        last : Int
        last =
            model.currentPage * model.pageSize

        pages : Int
        pages =
            toFloat model.totalItems / toFloat model.pageSize |> ceiling
    in
    if pages < 2 then
        div [] []

    else
        div [ class "flex items-center justify-between border-t border-gray-200 bg-white" ]
            [ div [ class "hidden sm:flex sm:flex-1 sm:items-center sm:justify-between" ]
                [ viewItems first last model.totalItems
                , viewPages changePage model.currentPage pages
                ]
            ]


viewItems : Int -> Int -> Int -> Html msg
viewItems first last total =
    p [ class "text-sm text-gray-700" ]
        [ text "Showing "
        , span [ class "font-medium" ] [ text (String.fromInt first) ]
        , text " to "
        , span [ class "font-medium" ] [ text (String.fromInt (min last total)) ]
        , text " of "
        , span [ class "font-medium" ] [ text (String.fromInt total) ]
        , text " results"
        ]


viewPages : (Int -> msg) -> Int -> Int -> Html msg
viewPages changePage current pages =
    let
        currentPages : List Int
        currentPages =
            [ current - 2, current - 1, current, current + 1, current + 2 ] |> List.filter (\p -> 0 < p && p <= pages)

        firstPages : List Int
        firstPages =
            if 4 <= current then
                [ 1 ]

            else
                []

        firstEllipse : List (Html msg)
        firstEllipse =
            if 4 < current then
                [ viewPageEllipse ]

            else
                []

        lastPages : List Int
        lastPages =
            if current <= pages - 3 then
                [ pages ]

            else
                []

        lastEllipse : List (Html msg)
        lastEllipse =
            if current < pages - 3 then
                [ viewPageEllipse ]

            else
                []
    in
    nav [ class "flex items-center justify-between" ]
        [ div [ class "flex -mt-px" ]
            ((firstPages |> List.map (viewPageNumber changePage current))
                ++ firstEllipse
                ++ (currentPages |> List.map (viewPageNumber changePage current))
                ++ lastEllipse
                ++ (lastPages |> List.map (viewPageNumber changePage current))
            )
        ]


viewPageNumber : (Int -> msg) -> Int -> Int -> Html msg
viewPageNumber changePage current page =
    if page == current then
        span [ class "inline-flex items-center border-t-2 px-2 pt-2 text-sm font-medium border-indigo-500 text-indigo-600", ariaCurrent "page" ]
            [ text (String.fromInt page) ]

    else
        button [ type_ "button", onClick (changePage page), class "inline-flex items-center border-t-2 px-2 pt-2 text-sm font-medium border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700" ]
            [ text (String.fromInt page) ]


viewPageEllipse : Html msg
viewPageEllipse =
    span [ class "inline-flex items-center border-t-2 px-2 pt-2 text-sm font-medium border-transparent text-gray-500" ] [ text "..." ]



-- DOCUMENTATION


doc : Chapter x
doc =
    Chapter.chapter "Pagination"
        |> Chapter.renderComponentList
            [ ( "page 1", view (logActionWith String.fromInt "changePage") (docModel 1 100) )
            , ( "page 2", view (logActionWith String.fromInt "changePage") (docModel 2 98) )
            , ( "page 3", view (logActionWith String.fromInt "changePage") (docModel 3 98) )
            , ( "page 4", view (logActionWith String.fromInt "changePage") (docModel 4 98) )
            , ( "page 5", view (logActionWith String.fromInt "changePage") (docModel 5 98) )
            , ( "page 6", view (logActionWith String.fromInt "changePage") (docModel 6 98) )
            , ( "page 7", view (logActionWith String.fromInt "changePage") (docModel 7 98) )
            , ( "page 8", view (logActionWith String.fromInt "changePage") (docModel 8 98) )
            , ( "page 9", view (logActionWith String.fromInt "changePage") (docModel 9 98) )
            , ( "page 10", view (logActionWith String.fromInt "changePage") (docModel 10 98) )
            , ( "1 page", view (logActionWith String.fromInt "changePage") (docModel 1 5) )
            , ( "2 pages", view (logActionWith String.fromInt "changePage") (docModel 1 15) )
            ]


docModel : Int -> Int -> Model
docModel page items =
    { currentPage = page, pageSize = 10, totalItems = items }
