module PagesComponents.Home_.View exposing (viewHome)

import Components.Organisms.Footer as Footer
import Components.Slices.Cta as Cta
import Components.Slices.Feature as Feature
import Components.Slices.FeatureSideBySide as FeatureSideBySide exposing (Position(..))
import Components.Slices.Hero as Hero
import Css.Global as Global
import Gen.Route as Route
import Html.Styled exposing (Html, br, div, text)
import Html.Styled.Attributes exposing (class)
import Libs.Html.Styled exposing (bText)
import Tailwind.Utilities exposing (globalStyles)


viewHome : List (Html msg)
viewHome =
    [ div [ class "bg-white" ]
        [ Global.global globalStyles
        , Hero.backgroundImageSlice
        , FeatureSideBySide.imageSwapSlice { url = "/assets/images/screenshot-complex.png", alt = "Azimutt screenshot" }
            { image = { url = "/assets/images/screenshot.png", alt = "Azimutt screenshot" }
            , imagePosition = Right
            , icon = Nothing
            , description =
                { title = "Explore your database schema"
                , content =
                    [ text """Not everyone has the opportunity to work on brand new application where you create everything, including the data model.
                              Many developers evolve and maintain existing applications with an already big schema, sometimes more than 50, 100 or even 500 tables.
                              Finding the right tables and relations to work with can be hard, and sincerely, no tool really helps. Until now."""
                    , br [] []
                    , bText "Azimutt"
                    , text " allows you to explore your schema: search for relevant tables, follow the relations, hide less interesting columns and even find the paths between tables."
                    ]
                }
            , cta = Just { url = Route.App, label = "Get started" }
            , quote = Just { text = "Using Azimutt is like having super powers!", author = "Loïc Knuchel, Principal Engineer @ Doctolib", avatar = { url = "/assets/images/knuchel_avatar.jpg", alt = "Loïc Knuchel" } }
            }

        --, FeatureSideBySide.imageSlice
        --    { image = { url = "https://tailwindui.com/img/component-images/inbox-app-screenshot-2.jpg", alt = "Customer profile user interface" }
        --    , imagePosition = Left
        --    , icon = Just (Icon.sparkles [ text_white ])
        --    , description =
        --        { title = "Better understand your customers"
        --        , content = [ text "Semper curabitur ullamcorper posuere nunc sed. Ornare iaculis bibendum malesuada faucibus lacinia porttitor. Pulvinar laoreet sagittis viverra duis. In venenatis sem arcu pretium pharetra at. Lectus viverra dui tellus ornare pharetra." ]
        --        }
        --    , cta = Just { url = Route.App, label = "Get started" }
        --    , quote = Nothing
        --    }
        , Feature.coloredSlice
        , Cta.slice
        , Footer.slice
        ]
    ]
