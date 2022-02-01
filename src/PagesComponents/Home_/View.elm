module PagesComponents.Home_.View exposing (viewHome)

import Components.Atoms.Badge as Badge
import Components.Atoms.Icon exposing (Icon(..))
import Components.Atoms.Link as Link
import Components.Molecules.Feature as Feature
import Components.Slices.Cta as Cta
import Components.Slices.FeatureGrid as FeatureGrid
import Components.Slices.FeatureSideBySide as FeatureSideBySide exposing (Position(..))
import Components.Slices.Hero as Hero
import Conf
import Css.Global as Global
import Gen.Route as Route
import Html exposing (b, br, div, span, text)
import Html.Attributes exposing (title)
import Html.Styled as Styled exposing (fromUnstyled)
import Html.Styled.Attributes as Styled
import Libs.Bootstrap exposing (Toggle(..), bsToggle)
import Libs.Html exposing (bText, extLink)
import Libs.Html.Attributes exposing (classes)
import Libs.Html.Styled as Styled
import Libs.Html.Styled.Attributes as Styled2
import Libs.Maybe as M
import Libs.Models.Color as Color
import PagesComponents.Helpers as Helpers
import PagesComponents.Home_.Models exposing (Model)
import Tailwind.Utilities as Tw
import Track


viewHome : Model -> List (Styled.Html msg)
viewHome model =
    let
        heroCta : Styled.Html msg
        heroCta =
            model.projects
                |> List.head
                |> M.mapOrElse
                    (\p ->
                        Styled.div []
                            [ Link.white5 Color.indigo ([ Styled.href (Route.toHref (Route.Projects__Id_ { id = p.id })) ] ++ Styled2.track (Track.openAppCta "last-project")) [ Styled.text ("Explore " ++ p.name) ]
                            , Link.white5 Color.indigo ([ Styled.href (Route.toHref Route.Projects), Styled.css [ Tw.ml_3 ] ] ++ Styled2.track (Track.openAppCta "dashboard")) [ Styled.text "Open Dashboard" ]
                            ]
                    )
                    (Link.white5 Color.indigo ([ Styled.href (Route.toHref Route.Projects) ] ++ Styled2.track (Track.openAppCta "home-hero")) [ Styled.text "Explore your schema" ])
    in
    [ Global.global Tw.globalStyles
    , Helpers.publicHeader |> fromUnstyled
    , Hero.backgroundImageSlice
        { bg = { src = "/assets/images/background_hero.jpeg", alt = "A compass on a map" }
        , title = "Explore your database SQL schema"
        , content = [ Styled.bText "Did you ever find yourself lost in your database?", Styled.br [] [], Styled.bText "Discover how Azimutt will help you understand it." ]
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
        |> fromUnstyled
    , FeatureSideBySide.imageSwapSlice { src = "/assets/images/gospeak-schema-light.png", alt = "Gospeak.io minimal schema by Azimutt" }
        { image = { src = "/assets/images/gospeak-schema-full.png", alt = "Gospeak.io schema by Azimutt" }
        , imagePosition = Left
        , icon = Just Sparkles
        , description =
            { title = "See what you need"
            , content =
                [ text "Good understanding starts with a good visualization. Azimutt is the only Entity-Relationship diagram that let you choose what you want to see and how."
                , div [ classes [ "mt-3" ] ] []
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
        |> fromUnstyled
    , FeatureSideBySide.imageSlice
        { image = { src = "/assets/images/gospeak-incoming-relation.jpg", alt = "Gospeak.io incoming relations by Azimutt" }
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
                , div [ classes [ "mt-3" ] ] []
                , Feature.checked { title = "outgoing relations", description = Nothing }
                , Feature.checked { title = "incoming relations", description = Nothing }
                ]
            }
        , cta = Just { url = Route.toHref Route.Projects, text = "I can't resist, let's go!", track = Just (Track.openAppCta "home-relations-section") }
        , quote = Nothing
        }
        |> fromUnstyled
    , FeatureSideBySide.imageSlice
        { image = { src = "/assets/images/gospeak-layouts.jpg", alt = "Gospeak.io layouts by Azimutt" }
        , imagePosition = Left
        , icon = Just ColorSwatch -- chat-alt-2 / collection / color-swatch
        , description =
            { title = "Context switch like a pro"
            , content =
                [ text "Do you like throwing away your work ? Me neither. And Azimutt has you covered on this."
                , text "Once you have finished an investigation, save your meaningful diagram as a layout so you can come back to it later and even improve it."
                , br [] []
                , text "Your colleagues will be jealous, until you tell the about Azimutt ❤️"
                ]
            }
        , cta = Just { url = Route.toHref Route.Projects, text = "That's enough, I'm in!", track = Just (Track.openAppCta "home-layouts-section") }
        , quote = Nothing
        }
        |> fromUnstyled
    , FeatureSideBySide.imageSlice
        { image = { src = "/assets/images/gospeak-find-path.png", alt = "Gospeak.io find path with Azimutt" }
        , imagePosition = Right
        , icon = Just Beaker
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
                , Badge.basic Color.red [] [ text "soon" ]
                , text " It will make you a "
                , span [ title "coffee", bsToggle Tooltip ] [ text "☕️" ]
                , text ", just as you like!"
                ]
            }
        , cta = Just { url = Route.toHref Route.Projects, text = "I'm hooked!", track = Just (Track.openAppCta "home-find-path-section") }
        , quote = Nothing
        }
        |> fromUnstyled
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
                    , text ", awesomely built with Elm. Come a let's discuss!"
                    ]
              }
            ]
        }
        |> fromUnstyled
    , Cta.slice |> fromUnstyled
    , Helpers.newsletterSection |> fromUnstyled
    , Helpers.publicFooter |> fromUnstyled
    ]
