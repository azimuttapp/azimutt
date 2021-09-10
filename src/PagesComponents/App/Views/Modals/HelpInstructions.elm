module PagesComponents.App.Views.Modals.HelpInstructions exposing (viewHelpModal)

import Conf exposing (conf, constants)
import Html exposing (Html, a, button, div, h2, kbd, p, span, text)
import Html.Attributes exposing (class, href, id, rel, target, type_)
import Libs.Bootstrap exposing (Toggle(..), bsDismiss, bsModal, bsParent, bsTarget, bsToggle)
import Libs.Html.Attributes exposing (ariaControls, ariaExpanded, ariaLabelledBy)


viewHelpModal : Html msg
viewHelpModal =
    bsModal conf.ids.helpModal
        "🎊 Hey! Welcome to Azimutt 🎊"
        [ p [] [ text "Let's dive into the features you might be interested in..." ]
        , div [ class "accordion mb-3", id (conf.ids.helpModal ++ "-accordion") ]
            (List.map sectionToAccordionItem
                [ search
                , canvasNavigation
                , partialDisplay
                , layout
                , followRelation
                , findPath
                ]
            )
        , p [ class "mb-0" ]
            [ text "I hope you find Azimutt as much as useful as I do. The application is quickly evolving and any feedback, feature request or use case description is "
            , extLink (constants.azimuttGithub ++ "/discussions") "very welcome"
            , text " to help us make the most out of it."
            ]
        ]
        [ button [ type_ "button", class "btn btn-primary", bsDismiss Modal ] [ text "Thanks!" ] ]


type alias Section msg =
    { title : String, body : List (Html msg) }


search : Section msg
search =
    { title = "Search"
    , body =
        [ p [] [ text """It's quite easy, just enter the search (top left) and look for what you want.
                                  You will find tables from your schema but also columns if there is an exact match.
                                  Clicking on them will show the table on the canvas.""" ]
        , p [] [ tip, text " Just type ", c "/", text " from anywhere to focus the search input" ]
        , p []
            [ soon
            , text " We plan to use full-text search to be typo tolerant and also include table comment and column names & comments to score the results. If you really want this, please "
            , extLink (constants.azimuttGithub ++ "/discussions/8") "vote and let us know"
            , text " to help prioritization."
            ]
        , p []
            [ bug
            , text " "
            , c "Up"
            , text ", "
            , c "Down"
            , text " and "
            , c "Enter"
            , text " don't work to navigate in the search results, we are looking for a fix."
            ]
        ]
    }


canvasNavigation : Section msg
canvasNavigation =
    { title = "Canvas navigation"
    , body =
        [ p []
            [ text "You have an infinite canvas to organize your tables. You can navigate in it using the scroll and zoom using the "
            , c "ctrl"
            , text " + "
            , c "scroll"
            , text ". On the bottom right you also have some commands to control the zoom or adjust your schema to the screen."
            ]
        , p [] [ text "You can move table by dragging them and move the whole canvas by dragging the background." ]
        , p []
            [ soon
            , text " Group selection using a box or ctrl + click will allow to move multiple tables at once. "
            , extLink (constants.azimuttGithub ++ "/discussions/9") "Tell us"
            , text " if this feature is highly expected."
            ]
        ]
    }


partialDisplay : Section msg
partialDisplay =
    { title = "Partial display"
    , body =
        [ text "Having too much information makes it useless. Azimutt let you select the table you want to see but also the columns. If you "
        , c "double click"
        , text " on a column, it will be hidden in the 'hidden columns' section. And then shown again in last position with the "
        , c "double click"
        , text " from this section. For quicker hide, you can use the keyboard shortcuts ("
        , c "d"
        , text ", "
        , c "Backspace"
        , text " or "
        , c "Suppr"
        , text ") while hovering the column."
        ]
    }


layout : Section msg
layout =
    { title = "Layout"
    , body =
        [ text """If you are using Azimutt, your schema is probably too complex to be seen all at once.
                  But focusing on specific use cases can be very interesting, showing only the relevant tables, columns and relations.
                  Layouts allows you to define such use cases and save them so you can come back to them later.""" ]
    }


followRelation : Section msg
followRelation =
    { title = "Follow relation"
    , body =
        [ text "Azimutt shows you foreign keys as outgoing relations from a column with a small horizontal link on the right. Just "
        , c "click"
        , text " on the column icon to show the target table. Incoming relations (foreign keys pointing to the table) are shown on the left, "
        , c "click"
        , text " on the column icon to see all the incoming relations an choose which tables to show."
        ]
    }


findPath : Section msg
findPath =
    { title = "Find path"
    , body =
        [ p []
            [ experimental
            , text " Find all the possible paths between two tables. To get relevant results, use the settings to ignore some columns or tables. "
            , text "We are still figuring out how this could be the most interesting so don't hesitate to "
            , extLink (constants.azimuttGithub ++ "/discussions/7") "come and discuss"
            , text " out it."
            ]
        ]
    }


tip : Html msg
tip =
    span [ class "badge bg-success" ] [ text "tip" ]


soon : Html msg
soon =
    span [ class "badge bg-primary" ] [ text "soon" ]


bug : Html msg
bug =
    span [ class "badge bg-danger" ] [ text "bug" ]


experimental : Html msg
experimental =
    span [ class "badge bg-warning" ] [ text "experimental" ]


sectionToAccordionItem : Section msg -> Html msg
sectionToAccordionItem section =
    let
        sectionId : String
        sectionId =
            sectionTitleToId section.title
    in
    div [ class "accordion-item" ]
        [ h2 [ class "accordion-header", id (sectionId ++ "-heading") ]
            [ button [ class "accordion-button collapsed", type_ "button", bsToggle Collapse, bsTarget (sectionId ++ "-collapse"), ariaExpanded False, ariaControls (sectionId ++ "-collapse") ] [ text section.title ]
            ]
        , div [ id (sectionId ++ "-collapse"), class "accordion-collapse collapse", bsParent (conf.ids.helpModal ++ "-accordion"), ariaLabelledBy (sectionId ++ "-heading") ]
            [ div [ class "accordion-body" ] section.body
            ]
        ]


sectionTitleToId : String -> String
sectionTitleToId title =
    title |> String.toLower |> String.replace " " "-"


c : String -> Html msg
c value =
    kbd [] [ text value ]


extLink : String -> String -> Html msg
extLink url value =
    a [ href url, target "_blank", rel "noopener" ] [ text value ]
