module PagesComponents.Home_.View exposing (viewHome)

import Components.Atoms.Badge as Badge
import Components.Atoms.Icon exposing (Icon(..))
import Components.Atoms.Link as Link
import Components.Molecules.Feature as Feature
import Components.Molecules.Tooltip as Tooltip
import Components.Slices.Cta as Cta
import Components.Slices.FeatureGrid as FeatureGrid
import Components.Slices.FeatureSideBySide as FeatureSideBySide exposing (Position(..))
import Components.Slices.Hero as Hero
import Conf
import Gen.Route as Route
import Html exposing (Html, b, br, div, span, text)
import Html.Attributes exposing (href)
import Libs.Html exposing (bText, extLink)
import Libs.Html.Attributes exposing (css, track)
import Libs.Maybe as Maybe
import Libs.Tailwind as Tw
import PagesComponents.Helpers as Helpers
import PagesComponents.Home_.Models exposing (Model)
import Track


viewHome : Model -> List (Html msg)
viewHome model =
    let
        heroCta : Html msg
        heroCta =
            model.projects
                |> List.head
                |> Maybe.mapOrElse
                    (\p ->
                        div []
                            [ Link.white5 Tw.indigo ([ href (Route.toHref (Route.Projects__Id_ { id = p.id })) ] ++ track (Track.openAppCta "last-project")) [ text ("Explore " ++ p.name) ]
                            , Link.white5 Tw.indigo ([ href (Route.toHref Route.Projects), css [ "ml-3" ] ] ++ track (Track.openAppCta "dashboard")) [ text "Open Dashboard" ]
                            ]
                    )
                    (Link.white5 Tw.indigo ([ href (Route.toHref Route.Projects) ] ++ track (Track.openAppCta "home-hero")) [ text "Explore your schema" ])
    in
    [ Helpers.publicHeader
    , Hero.backgroundImageSlice
        { bg = { src = "/assets/images/background_hero.jpeg", alt = "A compass on a map" }
        , title = "Explore your SQL database schema"
        , content = [ bText "Did you ever find yourself lost in your database?", br [] [], bText "Discover how Azimutt will help you understand it." ]
        , cta = heroCta
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
        , cta = Just { url = Route.toHref Route.Projects, text = "Let's try it!", track = Just (Track.openAppCta "home-explore-section") }
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
        , icon = Just Sparkles
        , description =
            { title = "See what you need"
            , content =
                [ text "Good understanding starts with a good visualization. Azimutt is the only Entity-Relationship diagram that let you choose what you want to see and how."
                , div [ css [ "mt-3" ] ] []
                , Feature.checked { title = "search everywhere", description = Nothing }
                , Feature.checked { title = "show, hide and organize tables", description = Nothing }
                , Feature.checked { title = "show, hide and sort columns", description = Nothing }
                ]
            }
        , cta = Just { url = Route.toHref Route.Projects, text = "Let me see...", track = Just (Track.openAppCta "home-display-section") }
        , quote =
            Just
                { text = """The app seems really well thought out, particularly the control you have over what to include in the diagram and the ability to save different views.
                            This feels like the workflow I never knew I wanted until trying it just now."""
                , author = "Oliver Searle-Barnes, Freelance, former VP Eng at Zapnito"
                , avatar = { src = "/assets/images/avatar-oliver-searle-barnes.png", alt = "Oliver Searle-Barnes" }
                }
        }
    , FeatureSideBySide.imageSlice
        { image = { src = "/assets/images/gospeak-incoming-relation.png", alt = "Gospeak.io incoming relations by Azimutt" }
        , imagePosition = Right
        , icon = Just LightBulb -- arrows-expand / light-bulb / lightning-bolt
        , description =
            { title = "Follow your mind"
            , content =
                [ text "Relational databases are made of, well, relations."
                , br [] []
                , text "Did you ever wanted to see what is on the other side of a relation ? With Azimutt, it's just one click away 🤩"
                , br [] []
                , text "And there's more, how do you see incoming relations ? Azimutt list all of them and is able to show one, many or all of them in just two clicks! 😍"
                , div [ css [ "mt-3" ] ] []
                , Feature.checked { title = "outgoing relations", description = Nothing }
                , Feature.checked { title = "incoming relations", description = Nothing }
                ]
            }
        , cta = Just { url = Route.toHref Route.Projects, text = "I can't resist, let's go!", track = Just (Track.openAppCta "home-relations-section") }
        , quote = Nothing
        }
    , FeatureSideBySide.imageSlice
        { image = { src = "/assets/images/gospeak-layouts.png", alt = "Gospeak.io layouts by Azimutt" }
        , imagePosition = Left
        , icon = Just ColorSwatch -- chat-alt-2 / collection / color-swatch
        , description =
            { title = "Context switch like a pro"
            , content =
                [ text "Do you like throwing away your work ? Me neither. And Azimutt has you covered on this. "
                , text "Once you have finished an investigation, save your meaningful diagram as a layout so you can come back to it later and even improve it."
                , br [] []
                , text "Your colleagues will be jealous, until you tell them about Azimutt ❤️"
                ]
            }
        , cta = Just { url = Route.toHref Route.Projects, text = "That's enough, I'm in!", track = Just (Track.openAppCta "home-layouts-section") }
        , quote = Nothing
        }
    , FeatureSideBySide.imageSlice
        { image = { src = "/assets/images/gospeak-find-path.png", alt = "Gospeak.io find path with Azimutt" }
        , imagePosition = Right
        , icon = Just Map
        , description =
            { title = "Let Azimutt drive you"
            , content =
                [ text """Sometimes, easily following relations is not enough, especially when you don't know in which direction to go.
                          And looking at every possible relation can be tedious. So let's grab a """
                , span [] [ text "🍹" ] |> Tooltip.t "drink"
                , text """ and watch Azimutt do the work for you."""
                , br [] []
                , text """It will look for every relation and build possible paths between two tables you want to join.
                          And as it is helpful, it will even build the SQL request for you with all the needed joins."""
                ]
            }
        , cta = Just { url = Route.toHref Route.Projects, text = "I'm hooked!", track = Just (Track.openAppCta "home-find-path-section") }
        , quote = Nothing
        }
    , FeatureSideBySide.imageSlice
        { image = { src = "/assets/images/wordpress-schema-analysis.png", alt = "Analyze WordPress database schema" }
        , imagePosition = Left
        , icon = Just CursorClick
        , description =
            { title = "Find and fix mistakes"
            , content =
                [ text """Azimutt not only let your explore your database schema but also analyze it to provide you insights.
                          Import your schema and find inconsistencies or forgotten relations in a minute, and trust me, for any on-trivial schema, you will find some."""
                , br [] []
                , text "Schema analysis always evolve, thanks to your feedback, to be as helpful as possible."
                , br [] []
                , Badge.basic Tw.red [] [ text "soon" ]
                , text " It will also make you a "
                , span [] [ text "☕️" ] |> Tooltip.t "coffee"
                , text ", just as you like!"
                ]
            }
        , cta = Just { url = Route.toHref Route.Projects, text = "I must try!", track = Just (Track.openAppCta "home-schema-analysis-section") }
        , quote = Nothing
        }
    , FeatureGrid.cardSlice
        { header = "Last chance"
        , title = "What more can you want ?"
        , description = "If you are still not convinced, here are my last words. Azimutt is awesome, built with awesome technology and supports your awesome use cases. See below..."
        , cards =
            [ { icon = ArrowCircleDown, title = "PWA ready", description = [ text "Install Azimutt on your PC so your schema will always be at your fingertips. Whatever happens." ] }
            , { icon = ShieldCheck, title = "Everything is local", description = [ text "Don't worry about privacy, everything stays on your computer, this is your data! #localStorage" ] }
            , { icon = DocumentSearch
              , title = "Fully open source"
              , description =
                    [ text "Want to have a look? Everything is on "
                    , b [] [ extLink Conf.constants.azimuttGithub [] [ text "azimuttap/azimutt" ] ]
                    , text ", awesomely built with Elm. Come and let's discuss!"
                    ]
              }
            ]
        }
    , Cta.slice (Route.toHref Route.Projects)
    , Helpers.newsletterSection
    , Helpers.publicFooter
    ]
