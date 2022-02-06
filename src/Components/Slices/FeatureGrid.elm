module Components.Slices.FeatureGrid exposing (CardItemModel, CardModel, cardSlice, coloredSlice, doc)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import ElmBook.Chapter exposing (Chapter, chapter, renderComponentList)
import Gen.Route as Route
import Html exposing (Html, a, br, div, h2, h3, p, span, text)
import Html.Attributes exposing (class, href)
import Libs.Html.Attributes exposing (css)
import Libs.Tailwind exposing (lg, sm)


coloredSlice : Html msg
coloredSlice =
    div [ css [ "bg-gradient-to-r from-green-800 to-indigo-700" ] ]
        [ div [ css [ "max-w-4xl mx-auto px-4 py-16", sm [ "px-6 pt-20 pb-24" ], lg [ "max-w-7xl pt-24 px-8" ] ] ]
            [ h2 [ css [ "text-3xl font-extrabold text-white tracking-tight" ] ]
                [ text "Explore your SQL schema like never before" ]
            , p [ css [ "mt-4 max-w-3xl text-lg text-purple-200" ] ]
                [ text "Your new weapons to dig into your schema:" ]
            , div [ css [ "mt-12 grid grid-cols-1 gap-x-6 gap-y-12 text-white", sm [ "grid-cols-2" ], lg [ "mt-16 grid-cols-3 gap-x-8 gap-y-16" ] ] ]
                [ item (Icon.outline Inbox "")
                    "Partial display"
                    [ text """Maybe the less impressive but most useful feature when you work with a schema with 20, 40 or even 400 or 1000 tables!
                              Seeing only what you need is vital to understand how it works. This is true for tables but also for columns and relations!""" ]
                , item (Icon.outline DocumentSearch "")
                    "Search"
                    [ text """Search is awesome, don't know where to start? Just type a few words and you will have related tables and columns ranked by relevance.
                              Looking at table and column names, but also comments, keys or relations.""" ]
                , item (Icon.outline Photograph "")
                    "Layouts"
                    [ text """Your database is probably supporting many use cases, why not save them and move from one to an other ?
                              Layouts are here for that: select tables and columns related to a feature and save them as a layout. So you can easily switch between them.""" ]
                , item (Icon.outline Link "")
                    "Relation exploration"
                    [ text """Start from a table and look at its relations to display more.
                              Outgoing, of course (foreign keys), but incoming ones also (foreign keys from other tables)!""" ]
                , item (Icon.outline Link "")
                    "Relation search"
                    [ text """Did you ever ask how to join two tables ?
                              Azimutt can help showing all the possible paths between two tables. But also between a table and a column!""" ]
                , item (Icon.outline Link "")
                    "Lorem Ipsum"
                    [ text "You came this far ??? Awesome! You seem quite interested and ready to dig in ^^", br [] [], text """
                            The best you can do now is to """, a [ href (Route.toHref Route.App), class "link" ] [ text "try it out" ], text " right away :D" ]
                ]
            ]
        ]


item : Html msg -> String -> List (Html msg) -> Html msg
item icon title description =
    div []
        [ div []
            [ span [ css [ "flex items-center justify-center h-12 w-12 rounded-md bg-white bg-opacity-10" ] ] [ icon ] ]
        , div [ css [ "mt-6" ] ]
            [ h3 [ css [ "text-lg font-medium text-white" ] ] [ text title ]
            , p [ css [ "mt-2 text-base text-purple-200" ] ] description
            ]
        ]


type alias CardModel msg =
    { header : String
    , title : String
    , description : String
    , cards : List (CardItemModel msg)
    }


type alias CardItemModel msg =
    { icon : Icon
    , title : String
    , description : List (Html msg)
    }


cardSlice : CardModel msg -> Html msg
cardSlice model =
    div [ css [ "relative bg-white py-16", sm [ "py-24" ], lg [ "py-32" ] ] ]
        [ div [ css [ "mx-auto max-w-md px-4 text-center", sm [ "max-w-3xl px-6" ], lg [ "px-8 max-w-7xl" ] ] ]
            [ h2 [ css [ "text-base font-semibold tracking-wider uppercase bg-gradient-to-r from-green-600 to-indigo-600 bg-clip-text text-transparent" ] ] [ text model.header ]
            , p [ css [ "mt-2 text-3xl font-extrabold text-gray-900 tracking-tight", sm [ "text-4xl" ] ] ] [ text model.title ]
            , p [ css [ "mt-5 max-w-prose mx-auto text-xl text-gray-500" ] ] [ text model.description ]
            , div [ css [ "mt-12" ] ]
                [ div [ css [ "grid grid-cols-1 gap-8", sm [ "grid-cols-2" ], lg [ "grid-cols-3" ] ] ]
                    (model.cards |> List.map card)
                ]
            ]
        ]


card : CardItemModel msg -> Html msg
card model =
    div [ css [ "pt-6" ] ]
        [ div [ css [ "flow-root bg-gray-50 rounded-lg px-6 pb-8" ] ]
            [ div [ css [ "-mt-6" ] ]
                [ div []
                    [ span [ css [ "inline-flex items-center justify-center p-3 rounded-md shadow-lg bg-gradient-to-r from-green-600 to-indigo-600" ] ] [ Icon.outline model.icon "text-white" ]
                    ]
                , h3 [ css [ "mt-8 text-lg font-medium text-gray-900 tracking-tight" ] ] [ text model.title ]
                , p [ css [ "mt-5 text-base text-gray-500" ] ] model.description
                ]
            ]
        ]



-- DOCUMENTATION


cardModel : CardModel msg
cardModel =
    { header = "Deploy faster"
    , title = "Everything you need to deploy your app"
    , description = "Phasellus lorem quam molestie id quisque diam aenean nulla in. Accumsan in quis quis nunc, ullamcorper malesuada. Eleifend condimentum id viverra nulla."
    , cards =
        [ { icon = CloudUpload, title = "Push to Deploy", description = [ text "Ac tincidunt sapien vehicula erat auctor pellentesque rhoncus. Et magna sit morbi lobortis." ] }
        , { icon = LockClosed, title = "SSL Certificates", description = [ text "Ac tincidunt sapien vehicula erat auctor pellentesque rhoncus. Et magna sit morbi lobortis." ] }
        , { icon = Refresh, title = "Simple Queues", description = [ text "Ac tincidunt sapien vehicula erat auctor pellentesque rhoncus. Et magna sit morbi lobortis." ] }
        , { icon = ShieldCheck, title = "Advanced Security", description = [ text "Ac tincidunt sapien vehicula erat auctor pellentesque rhoncus. Et magna sit morbi lobortis." ] }
        , { icon = Cog, title = "Powerful API", description = [ text "Ac tincidunt sapien vehicula erat auctor pellentesque rhoncus. Et magna sit morbi lobortis." ] }
        , { icon = Server, title = "Database Backups", description = [ text "Ac tincidunt sapien vehicula erat auctor pellentesque rhoncus. Et magna sit morbi lobortis." ] }
        ]
    }


doc : Chapter x
doc =
    chapter "FeatureGrid"
        |> renderComponentList
            [ ( "coloredSlice", coloredSlice )
            , ( "cardsSlice", cardSlice cardModel )
            ]
