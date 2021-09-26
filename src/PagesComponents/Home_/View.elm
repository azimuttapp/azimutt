module PagesComponents.Home_.View exposing (viewHome)

import Components.Atoms.Badge as Badge
import Components.Atoms.Icon as Icon
import Components.Molecules.Feature as Feature
import Components.Organisms.Footer as Footer
import Components.Slices.Cta as Cta
import Components.Slices.FeatureGrid as FeatureGrid
import Components.Slices.FeatureSideBySide as FeatureSideBySide exposing (Position(..))
import Components.Slices.Hero as Hero
import Conf exposing (constants)
import Css.Global as Global
import Gen.Route as Route
import Html.Styled exposing (Html, b, br, div, span, text)
import Html.Styled.Attributes exposing (css, title)
import Libs.Bootstrap.Styled exposing (Toggle(..), bsToggle)
import Libs.Html.Styled exposing (bText, extLink)
import PagesComponents.Helpers as Helpers
import Tailwind.Utilities exposing (bg_red_100, globalStyles, mt_3, text_red_800, text_white)
import Tracking exposing (events)


viewHome : List (Html msg)
viewHome =
    [ Global.global globalStyles
    , Helpers.publicHeader
    , Hero.backgroundImageSlice
        { bg = { src = "/assets/images/background_hero.jpeg", alt = "A compass on a map" }
        , title = "Azimutt"
        , content = [ text "Lost in your database schema ?", br [] [], text "You just found the right ", bText "Azimutt", text " 🎉" ]
        , cta = { url = Route.toHref Route.App, text = "Explore your schema", track = Just (events.openAppCta "home-hero") }
        }
    , FeatureSideBySide.imageSwapSlice { src = "/assets/images/gospeak-schema-full.png", alt = "Gospeak.io schema by Azimutt" }
        { image = { src = "/assets/images/basic-schema.png", alt = "Basic schema by Azimutt" }
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
        , cta = Just { url = Route.toHref Route.App, text = "Let's try it!", track = Just (events.openAppCta "home-explore-section") }
        , quote =
            Just
                { text = "Using Azimutt is like having super powers!"
                , author = "Loïc Knuchel, Principal Engineer @ Doctolib"
                , avatar = { src = "/assets/images/avatar-loic-knuchel.jpg", alt = "Loïc Knuchel" }
                }
        }
    , FeatureSideBySide.imageSwapSlice { src = "/assets/images/gospeak-schema-light.png", alt = "Gospeak.io minimal schema by Azimutt" }
        { image = { src = "/assets/images/gospeak-schema-full.png", alt = "Gospeak.io schema by Azimutt" }
        , imagePosition = Left
        , icon = Just (Icon.sparkles [ text_white ])
        , description =
            { title = "See what you need"
            , content =
                [ text "Good understanding starts with a good visualization. Azimutt is the only Entity-Relationship diagram that let you choose what you want to see and how."
                , div [ css [ mt_3 ] ] []
                , Feature.checked { title = "search everywhere", description = Nothing }
                , Feature.checked { title = "show, hide and organize tables", description = Nothing }
                , Feature.checked { title = "show, hide and sort columns", description = Nothing }
                ]
            }
        , cta = Just { url = Route.toHref Route.App, text = "Let me see...", track = Just (events.openAppCta "home-display-section") }
        , quote =
            Just
                { text = """The app seems really well thought out, particularly the control you have over what to include in the diagram and the ability to save different views.
                                This feels like the workflow I never knew I wanted until trying it just now."""
                , author = "Oliver Searle-Barnes, Freelance, former VP Eng at Zapnito"
                , avatar = { src = "/assets/images/avatar-oliver-searle-barnes.png", alt = "Oliver Searle-Barnes" }
                }
        }
    , FeatureSideBySide.imageSlice
        { image = { src = "/assets/images/gospeak-incoming-relation.jpg", alt = "Gospeak.io incoming relations by Azimutt" }
        , imagePosition = Right
        , icon = Just (Icon.lightBulb [ text_white ]) -- arrows-expand / light-bulb / lightning-bolt
        , description =
            { title = "Follow your mind"
            , content =
                [ text "Relational databases are made of, well, relations."
                , br [] []
                , text "Did you ever wanted to see what is on the other side of a relation ? With Azimutt, it's just one click away 🤩"
                , br [] []
                , text "And there's more, how do you see incoming relations ? Azimutt list all of them and is able to show one, many or all of them in just two clicks! 😍"
                , div [ css [ mt_3 ] ] []
                , Feature.checked { title = "outgoing relations", description = Nothing }
                , Feature.checked { title = "incoming relations", description = Nothing }
                ]
            }
        , cta = Just { url = Route.toHref Route.App, text = "I can't resist, let's go!", track = Just (events.openAppCta "home-relations-section") }
        , quote = Nothing
        }
    , FeatureSideBySide.imageSlice
        { image = { src = "/assets/images/gospeak-layouts.jpg", alt = "Gospeak.io layouts by Azimutt" }
        , imagePosition = Left
        , icon = Just (Icon.colorSwatch [ text_white ]) -- chat-alt-2 / collection / color-swatch
        , description =
            { title = "Context switch like a pro"
            , content =
                [ text "Do you like throwing away your work ? Me neither. And Azimutt has you covered on this."
                , text "Once you have finished an investigation, save your meaningful diagram as a layout so you can come back to it later and even improve it."
                , br [] []
                , text "Your colleagues will be jealous, until you tell the about Azimutt ❤️"
                ]
            }
        , cta = Just { url = Route.toHref Route.App, text = "That's enough, I'm in!", track = Just (events.openAppCta "home-layouts-section") }
        , quote = Nothing
        }
    , FeatureSideBySide.imageSlice
        { image = { src = "/assets/images/gospeak-find-path.png", alt = "Gospeak.io find path with Azimutt" }
        , imagePosition = Right
        , icon = Just (Icon.beaker [ text_white ])
        , description =
            { title = "Relax"
            , content =
                [ text """Sometimes, easily following relations is not enough, especially when you don't know in which direction to go.
                              And looking at every possible relation can be tedious. So let's grab a """
                , span [ title "drink", bsToggle Tooltip ] [ text "🍹" ]
                , text """ and watch Azimutt do the work for you."""
                , br [] []
                , text """It will look for every relation and build possible paths between two tables you want to join.
                              And as it is helpful, it will even build the SQL request for you with all the needed joins."""
                , br [] []
                , Badge.basic [ bg_red_100, text_red_800 ] "soon"
                , text " It will make you a "
                , span [ title "coffee", bsToggle Tooltip ] [ text "☕️" ]
                , text ", just as you like!"
                ]
            }
        , cta = Just { url = Route.toHref Route.App, text = "I'm hooked!", track = Just (events.openAppCta "home-find-path-section") }
        , quote = Nothing
        }
    , FeatureGrid.cardSlice
        { header = "Last chance"
        , title = "What more can you want ?"
        , description = "If you are still not convinced, here are my last words. Azimutt is awesome, built with awesome technology and supports your awesome use cases. See below..."
        , cards =
            [ { icon = Icon.arrowCircleDown [ text_white ], title = "PWA ready", description = [ text "Install Azimutt on your PC so your schema will always be at your fingertips. Whatever happens." ] }
            , { icon = Icon.shieldCheck [ text_white ], title = "Everything is local", description = [ text "Don't worry about privacy, everything stays on your computer, this is your data! #localStorage" ] }
            , { icon = Icon.github [ text_white ]
              , title = "Fully open source"
              , description =
                    [ text "Want to have a look? Everything is on "
                    , b [] [ extLink constants.azimuttGithub [] [ text "azimuttap/azimutt" ] ]
                    , text ", awesomely built with Elm. Come a let's discuss!"
                    ]
              }
            ]
        }
    , Cta.slice
    , Footer.slice
    ]
