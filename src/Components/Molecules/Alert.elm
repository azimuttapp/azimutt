module Components.Molecules.Alert exposing (ActionsModel, DescriptionModel, ListModel, doc, withActions, withDescription, withList)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon(..))
import ElmBook.Chapter as Chapter
import ElmBook.ElmCSS exposing (Chapter)
import Html exposing (Html, div, h3, li, text, ul)
import Html.Attributes exposing (class)
import Html.Styled as Styled exposing (fromUnstyled)
import Html.Styled.Attributes as Styled
import Libs.Html.Attributes exposing (classes, role)
import Libs.Models.Color as Color exposing (Color)
import Libs.Tailwind exposing (bg_50, border_400, text_700, text_800)
import Tailwind.Utilities as Tw


type alias DescriptionModel =
    { color : Color
    , icon : Icon
    , title : String
    }


withDescription : DescriptionModel -> List (Html msg) -> Html msg
withDescription model description =
    alert
        { color = model.color
        , icon = model.icon
        , content = [ alertTitle model.color model.title, alertDescription model.color description ]
        }


type alias ListModel =
    { color : Color
    , icon : Icon
    , title : String
    , items : List String
    }


withList : ListModel -> Html msg
withList model =
    alert
        { color = model.color
        , icon = model.icon
        , content = [ alertTitle model.color model.title, alertList model.color model.items ]
        }


type alias ActionsModel msg =
    { color : Color
    , icon : Icon
    , title : String
    , actions : List (Html msg)
    }


withActions : ActionsModel msg -> List (Html msg) -> Html msg
withActions model description =
    alert
        { color = model.color
        , icon = model.icon
        , content =
            [ alertTitle model.color model.title
            , alertDescription model.color description
            , alertActions model.actions
            ]
        }


type alias Model msg =
    { color : Color
    , icon : Icon
    , content : List (Html msg)
    }


alert : Model msg -> Html msg
alert model =
    div [ classes [ "p-4 border-l-4", bg_50 model.color, border_400 model.color ] ]
        [ div [ class "flex" ]
            [ alertIcon model.color model.icon
            , div [ class "ml-3" ] model.content
            ]
        ]


alertIcon : Color -> Icon -> Html msg
alertIcon color icon =
    div [ class "flex-shrink-0" ]
        [ Icon.solid icon [ Color.text color 400 ] |> Styled.toUnstyled ]


alertTitle : Color -> String -> Html msg
alertTitle color title =
    h3 [ classes [ "text-sm font-medium", text_800 color ] ] [ text title ]


alertDescription : Color -> List (Html msg) -> Html msg
alertDescription color content =
    div [ classes [ "mt-2 text-sm", text_700 color ] ] content


alertList : Color -> List String -> Html msg
alertList color items =
    div [ classes [ "mt-2 text-sm", text_700 color ] ]
        [ ul [ role "list", class "list-disc list-inside" ]
            (items |> List.map (\item -> li [] [ text item ]))
        ]


alertActions : List (Html msg) -> Html msg
alertActions actions =
    div [ class "mt-4" ]
        [ div [ class "-mx-2 -my-1.5 flex" ]
            actions
        ]



-- DOCUMENTATION


doc : Chapter x
doc =
    Chapter.chapter "Alert"
        |> Chapter.renderComponentList
            [ ( "withDescription", withDescription { color = Color.yellow, icon = Exclamation, title = "Attention needed" } [ text "Lorem ipsum dolor sit amet consectetur adipisicing elit. Aliquid pariatur, ipsum similique veniam quo totam eius aperiam dolorum." ] |> fromUnstyled )
            , ( "withList", withList { color = Color.red, icon = XCircle, title = "There were 2 errors with your submission", items = [ "Your password must be at least 8 characters", "Your password must include at least one pro wrestling finishing move" ] } |> fromUnstyled )
            , ( "withActions"
              , withActions
                    { color = Color.green
                    , icon = CheckCircle
                    , title = "Order completed"
                    , actions =
                        [ Button.light2 Color.green [] [ Styled.text "View status" ] |> Styled.toUnstyled
                        , Button.light2 Color.green [ Styled.css [ Tw.ml_3 ] ] [ Styled.text "Dismiss" ] |> Styled.toUnstyled
                        ]
                    }
                    [ text "Lorem ipsum dolor sit amet consectetur adipisicing elit. Aliquid pariatur, ipsum similique veniam." ]
                    |> fromUnstyled
              )
            ]
