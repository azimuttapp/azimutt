module PagesComponents.Projects.Id_.Views.Modals.Help exposing (viewHelp)

import Components.Atoms.Badge as Badge
import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Atoms.Kbd as Kbd
import Components.Molecules.Modal as Modal
import Conf
import Html.Styled exposing (Html, div, h3, p, text)
import Html.Styled.Attributes exposing (css, id)
import Html.Styled.Events exposing (onClick)
import Libs.Html.Styled exposing (extLink)
import Libs.Models.Color as Color
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Theme exposing (Theme)
import Libs.Tailwind.Utilities as Tu
import PagesComponents.Projects.Id_.Models exposing (HelpDialog, HelpMsg(..), Msg(..))
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw


viewHelp : Theme -> Bool -> HelpDialog -> Html Msg
viewHelp theme opened model =
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
        [ div [ css [ Tw.max_w_3xl, Tw.mx_6, Tw.mt_6 ] ]
            [ div [ css [ Tw.mt_3, Tw.text_center, Bp.sm [ Tw.mt_5 ] ] ]
                [ h3 [ id titleId, css [ Tw.text_lg, Tw.leading_6, Tw.font_medium, Tw.text_gray_900 ] ]
                    [ text "🎊 Hey! Welcome to Azimutt 🎊" ]
                , div [ css [ Tw.mt_2 ] ]
                    [ p [ css [ Tw.text_sm, Tw.text_gray_500 ] ]
                        [ text "Let's dive into the features you might be interested in..." ]
                    ]
                ]
            , div [ css [ Tw.mt_3, Tw.border, Tw.border_gray_300, Tw.rounded_md, Tw.shadow_sm, Tw.divide_y, Tw.divide_gray_300 ] ]
                (List.map (\s -> sectionToAccordionItem theme (s.title == model.openedSection) s)
                    [ search
                    , canvasNavigation
                    , partialDisplay
                    , layout
                    , followRelation
                    , findPath
                    , shortcuts
                    ]
                )
            , p [ css [ Tw.mt_3 ] ]
                [ text "I hope you find Azimutt as much as useful as I do. The application is quickly evolving and any feedback, feature request or use case description is "
                , extLink Conf.constants.azimuttDiscussions [ css [ Tu.link ] ] [ text "very welcome" ]
                , text " to help us make the most out of it."
                ]
            ]
        , div [ css [ Tw.px_6, Tw.py_3, Tw.mt_3, Tw.flex, Tw.items_center, Tw.justify_between, Tw.flex_row_reverse, Tw.bg_gray_50 ] ]
            [ Button.primary3 theme.color [ onClick (ModalClose (HelpMsg HClose)) ] [ text "Thanks!" ] ]
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
        , p [ css [ Tw.mt_3 ] ]
            [ tip
            , text " Just type "
            , hotkey [ "/" ]
            , text " from anywhere to focus the search input and start typing. You can also use "
            , hotkey [ "Arrows" ]
            , text " and "
            , hotkey [ "Enter" ]
            , text " to navigate in the results and select one."
            ]
        , p [ css [ Tw.mt_3 ] ]
            [ soon
            , text " We plan to use full-text search to be typo tolerant and have better results, as well as let you import some data to perform search on them. If you need this, please "
            , extLink Conf.constants.azimuttDiscussionSearch [ css [ Tu.link ] ] [ text "vote and let us know" ]
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
            , Icon.solid ArrowsExpand [ Tw.inline ]
            , text ")."
            ]
        , p [ css [ Tw.mt_3 ] ] [ text "You can move table by dragging them and move the whole canvas by dragging the background." ]
        , p [ css [ Tw.mt_3 ] ]
            [ tip
            , text " You can select multiple tables using "
            , hotkey [ "ctrl", "click" ]
            , text " or the selection box, and then move them all at once. If you have feedback or suggestions to improve this navigation, please "
            , extLink Conf.constants.azimuttDiscussionCanvas [ css [ Tu.link ] ] [ text "tell us" ]
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
        , Icon.solid ExternalLink [ Tw.inline ]
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
            , extLink Conf.constants.azimuttDiscussionFindPath [ css [ Tu.link ] ] [ text "come and discuss" ]
            , text " about it."
            ]
        ]
    }


shortcuts : Section msg
shortcuts =
    { title = "Shortcuts"
    , body =
        [ p [] [ text "Keyboard shortcuts improve user productivity. So Azimutt has some to help you:" ]
        , div [ css [ Tw.mt_3 ] ]
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
                |> List.map (\h -> div [ css [ Tw.flex, Tw.justify_between, Tw.flex_row_reverse, Tw.mt_1 ] ] [ hotkey h.hotkey, text (" " ++ h.description) ])
            )
        , p [ css [ Tw.mt_3 ] ] [ text "If you can think of other or have better suggestion for them, ", extLink Conf.constants.azimuttDiscussions [ css [ Tu.link ] ] [ text "just let us know" ], text "." ]
        ]
    }


sectionToAccordionItem : Theme -> Bool -> Section Msg -> Html Msg
sectionToAccordionItem theme opened section =
    div []
        [ div [ onClick (HelpMsg (HToggle section.title)), css [ Tw.px_6, Tw.py_4, Tw.cursor_pointer, Tu.when opened [ Color.bg theme.color 100, Color.text theme.color 700 ] ] ] [ text section.title ]
        , div [ css [ Tw.px_6, Tw.py_3, Tw.border_t, Tw.border_gray_300, Tu.when (not opened) [ Tw.hidden ] ] ] section.body
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
