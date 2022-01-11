module Components.Molecules.Alert exposing (ActionsModel, DescriptionModel, ListModel, doc, withActions, withDescription, withList)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon(..))
import ElmBook.Chapter as Chapter
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Html, div, h3, li, text, ul)
import Html.Styled.Attributes exposing (css)
import Libs.Html.Styled.Attributes exposing (role)
import Libs.Models.Color as Color exposing (Color)
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
    div [ css [ Color.bg model.color 50, Tw.p_4, Tw.border_l_4, Color.border model.color 400 ] ]
        [ div [ css [ Tw.flex ] ]
            [ alertIcon model.color model.icon
            , div [ css [ Tw.ml_3 ] ] model.content
            ]
        ]


alertIcon : Color -> Icon -> Html msg
alertIcon color icon =
    div [ css [ Tw.flex_shrink_0 ] ]
        [ Icon.solid icon [ Color.text color 400 ] ]


alertTitle : Color -> String -> Html msg
alertTitle color title =
    h3 [ css [ Tw.text_sm, Tw.font_medium, Color.text color 800 ] ] [ text title ]


alertDescription : Color -> List (Html msg) -> Html msg
alertDescription color content =
    div [ css [ Tw.mt_2, Tw.text_sm, Color.text color 700 ] ] content


alertList : Color -> List String -> Html msg
alertList color items =
    div [ css [ Tw.mt_2, Tw.text_sm, Color.text color 700 ] ]
        [ ul [ role "list", css [ Tw.list_disc, Tw.list_inside ] ]
            (items |> List.map (\item -> li [] [ text item ]))
        ]


alertActions : List (Html msg) -> Html msg
alertActions actions =
    div [ css [ Tw.mt_4 ] ]
        [ div [ css [ Tw.neg_mx_2, Tw.neg_my_1_dot_5, Tw.flex ] ]
            actions
        ]



-- DOCUMENTATION


doc : Chapter x
doc =
    Chapter.chapter "Alert"
        |> Chapter.renderComponentList
            [ ( "withDescription", withDescription { color = Color.yellow, icon = Exclamation, title = "Attention needed" } [ text "Lorem ipsum dolor sit amet consectetur adipisicing elit. Aliquid pariatur, ipsum similique veniam quo totam eius aperiam dolorum." ] )
            , ( "withList", withList { color = Color.red, icon = XCircle, title = "There were 2 errors with your submission", items = [ "Your password must be at least 8 characters", "Your password must include at least one pro wrestling finishing move" ] } )
            , ( "withActions", withActions { color = Color.green, icon = CheckCircle, title = "Order completed", actions = [ Button.light2 Color.green [] [ text "View status" ], Button.light2 Color.green [ css [ Tw.ml_3 ] ] [ text "Dismiss" ] ] } [ text "Lorem ipsum dolor sit amet consectetur adipisicing elit. Aliquid pariatur, ipsum similique veniam." ] )
            ]
