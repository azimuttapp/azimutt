module PagesComponents.Projects.Id_.Views.Modals.Help exposing (viewHelp)

import Components.Atoms.Badge as Badge
import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Atoms.Kbd as Kbd
import Components.Molecules.Modal as Modal
import Conf
import Html exposing (Html, div, h3, p, text)
import Html.Attributes exposing (class, id)
import Html.Events exposing (onClick)
import Libs.Bool as B
import Libs.Html exposing (extLink)
import Libs.Html.Attributes exposing (css)
import Libs.Models.Color as Color
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Tailwind exposing (sm)
import PagesComponents.Projects.Id_.Models exposing (HelpDialog, HelpMsg(..), Msg(..))


viewHelp : Bool -> HelpDialog -> Html Msg
viewHelp opened model =
    let
        titleId : HtmlId
        titleId =
            model.id ++ "-title"
    in
    Modal.modal
        { id = model.id
        , titleId = titleId
        , isOpen = opened
        , onBackgroundClick = ModalClose (HelpMsg HClose)
        }
        [ div [ class "max-w-3xl mx-6 mt-6" ]
            [ div [ css [ "mt-3 text-center", sm [ "mt-5" ] ] ]
                [ h3 [ id titleId, class "text-lg leading-6 font-medium text-gray-900" ]
                    [ text "🎊 Hey! Welcome to Azimutt 🎊" ]
                , div [ class "mt-2" ]
                    [ p [ class "text-sm text-gray-500" ]
                        [ text "Let's dive into the features you might be interested in..." ]
                    ]
                ]
            , div [ class "mt-3 border border-gray-300 rounded-md shadow-sm divide-y divide-gray-300" ]
                (List.map (\s -> sectionToAccordionItem (s.title == model.openedSection) s)
                    [ search
                    , canvasNavigation
                    , partialDisplay
                    , layout
                    , followRelation
                    , findPath
                    , shortcuts
                    ]
                )
            , p [ class "mt-3" ]
                [ text "I hope you find Azimutt as much as useful as I do. The application is quickly evolving and any feedback, feature request or use case description is "
                , extLink Conf.constants.azimuttDiscussions [ class "tw-link" ] [ text "very welcome" ]
                , text " to help us make the most out of it."
                ]
            ]
        , div [ class "px-6 py-3 mt-3 flex items-center justify-between flex-row-reverse bg-gray-50" ]
            [ Button.primary3 Color.primary [ onClick (ModalClose (HelpMsg HClose)) ] [ text "Thanks!" ] ]
        ]


type alias Section msg =
    { title : String, body : List (Html msg) }


search : Section msg
search =
    { title = "Search"
    , body =
        [ p [] [ text """It's quite easy, just enter the search (top left) and look for what you want.
                         You will find tables from your schema but also columns or relations.
                         We search "everywhere": name, comment or constraints for tables, name, comment, type or default value for columns and name, linked table and columns for relations.
                         Selecting them will show the related table on the canvas.""" ]
        , p [ class "mt-3" ]
            [ tip
            , text " Just type "
            , hotkey [ "/" ]
            , text " from anywhere to focus the search input and start typing. You can also use "
            , hotkey [ "Arrows" ]
            , text " and "
            , hotkey [ "Enter" ]
            , text " to navigate in the results and select one."
            ]
        , p [ class "mt-3" ]
            [ soon
            , text " We plan to use full-text search to be typo tolerant and have better results, as well as let you import some data to perform search on them. If you need this, please "
            , extLink Conf.constants.azimuttDiscussionSearch [ class "tw-link" ] [ text "vote and let us know" ]
            , text " to help prioritize it."
            ]
        ]
    }


canvasNavigation : Section msg
canvasNavigation =
    { title = "Canvas navigation"
    , body =
        [ p []
            [ text "You have an infinite canvas to organize your tables. You can scroll with your mouse and zoom using the "
            , hotkey [ "ctrl", "scroll" ]
            , text ". On the bottom right you also have some commands to control the zoom or adjust your schema to the screen ("
            , Icon.solid ArrowsExpand "inline"
            , text ")."
            ]
        , p [ class "mt-3" ] [ text "You can move table by dragging them and move the whole canvas by dragging the background." ]
        , p [ class "mt-3" ]
            [ tip
            , text " You can select multiple tables using "
            , hotkey [ "ctrl", "click" ]
            , text " or the selection box, and then move them all at once. If you have feedback or suggestions to improve this navigation, please "
            , extLink Conf.constants.azimuttDiscussionCanvas [ class "tw-link" ] [ text "tell us" ]
            , text ", it's an important core feature."
            ]
        ]
    }


partialDisplay : Section msg
partialDisplay =
    { title = "Partial display"
    , body =
        [ text "Having too much information makes it useless. Azimutt let you select the table you want to see but also the columns. If you "
        , hotkey [ "double click" ]
        , text " on a column, it will be moved to the 'hidden columns' section. And then shown again in last position with the "
        , hotkey [ "double click" ]
        , text " from this section. For quicker hide, you can use the keyboard shortcuts "
        , hotkey [ "d" ]
        , text ", "
        , hotkey [ "Backspace" ]
        , text " or "
        , hotkey [ "Delete" ]
        , text " while hovering the column, also works for a table."
        ]
    }


layout : Section msg
layout =
    { title = "Layout"
    , body =
        [ text """If you are using Azimutt, your schema is probably too complex to be seen all at once.
                  Focusing on specific use cases can be very interesting, showing only the relevant tables, columns and relations.
                  Layouts allows you to define such use cases and save them so you can come back to them later and easily switch between them.""" ]
    }


followRelation : Section msg
followRelation =
    { title = "Follow relation"
    , body =
        [ text "Azimutt shows you foreign keys as outgoing relations from a column with a small horizontal link on the right. Just "
        , hotkey [ "click" ]
        , text " on the column icon ("
        , Icon.solid ExternalLink "inline"
        , text ") to show the target table. Incoming relations (foreign keys pointing to the table) are shown on the left, "
        , hotkey [ "click" ]
        , text " on the column icon to see all the incoming relations an choose the tables you want to show."
        ]
    }


findPath : Section msg
findPath =
    { title = "Find path"
    , body =
        [ p []
            [ experimental
            , text " Find all the possible paths between two tables. To get relevant results, use the settings to ignore some tables or columns and keep the length small. "
            , text "We are still figuring out how this could be the most interesting (path algo, heuristics, UX...) so don't hesitate to "
            , extLink Conf.constants.azimuttDiscussionFindPath [ class "tw-link" ] [ text "come and discuss" ]
            , text " about it."
            ]
        ]
    }


shortcuts : Section msg
shortcuts =
    { title = "Shortcuts"
    , body =
        [ p [] [ text "Keyboard shortcuts improve user productivity. So Azimutt has some to help you:" ]
        , div [ class "mt-3" ]
            ([ { hotkey = [ "/" ], description = "Focus on the search" }
             , { hotkey = [ "Ctrl", "s" ], description = "Save the project. It's not done automatically so don't forget it ^^" }
             , { hotkey = [ "d" ], description = "Hide a table or column, depending on what is hovered" }
             , { hotkey = [ "Alt", "l" ], description = "Create a layout from your current state" }
             , { hotkey = [ "Alt", "v" ], description = "Add a new virtual relation" }
             , { hotkey = [ "Alt", "p" ], description = "Open find path dialog, use hovered table as source" }
             , { hotkey = [ "Ctrl", "ArrowUp" ], description = "Bring hovered table on step forward" }
             , { hotkey = [ "Ctrl", "ArrowDown" ], description = "Bring hovered table on step backward" }
             , { hotkey = [ "Ctrl", "Shift", "ArrowUp" ], description = "Bring hovered table in the front" }
             , { hotkey = [ "Ctrl", "Shift", "ArrowDown" ], description = "Bring hovered table to the back" }
             , { hotkey = [ "Escape" ], description = "Cancel what you are doing (drag, opened dialog, input focus, create relation...)" }
             , { hotkey = [ "?" ], description = "Open this documentation dialog" }
             ]
                |> List.map (\h -> div [ class "flex justify-between flex-row-reverse mt-1" ] [ hotkey h.hotkey, text (" " ++ h.description) ])
            )
        , p [ class "mt-3" ] [ text "If you can think of other or have better suggestion for them, ", extLink Conf.constants.azimuttDiscussions [ class "tw-link" ] [ text "just let us know" ], text "." ]
        ]
    }


sectionToAccordionItem : Bool -> Section Msg -> Html Msg
sectionToAccordionItem isOpen section =
    div []
        [ div [ onClick (HelpMsg (HToggle section.title)), css [ "px-6 py-4 cursor-pointer", B.cond isOpen "bg-primary-100 text-primary-700" "" ] ] [ text section.title ]
        , div [ css [ "px-6 py-3 border-t border-gray-300", B.cond isOpen "" "hidden" ] ] section.body
        ]


tip : Html msg
tip =
    Badge.rounded Color.green [] [ text "tip" ]


soon : Html msg
soon =
    Badge.rounded Color.indigo [] [ text "soon" ]


experimental : Html msg
experimental =
    Badge.rounded Color.yellow [] [ text "experimental" ]


hotkey : List String -> Html msg
hotkey values =
    Kbd.badge [] values
