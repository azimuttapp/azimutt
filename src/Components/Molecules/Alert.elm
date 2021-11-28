module Components.Molecules.Alert exposing (ActionsModel, DescriptionModel, ListModel, doc, withActions, withDescription, withList)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon(..))
import ElmBook.Chapter as Chapter
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Html, div, h3, li, text, ul)
import Html.Styled.Attributes exposing (css)
import Libs.Html.Styled.Attributes exposing (role)
import Libs.Models.TwColor as TwColor exposing (TwColor(..), TwColorLevel(..), TwColorPosition(..))
import Tailwind.Utilities as Tw


type alias DescriptionModel msg =
    { color : TwColor
    , icon : Icon
    , title : String
    , description : Html msg
    }


withDescription : DescriptionModel msg -> Html msg
withDescription model =
    alert
        { color = model.color
        , icon = model.icon
        , content = [ alertTitle model.color model.title, alertDescription model.color model.description ]
        }


type alias ListModel =
    { color : TwColor
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
    { color : TwColor
    , icon : Icon
    , title : String
    , description : Html msg
    , actions : List (Html msg)
    }


withActions : ActionsModel msg -> Html msg
withActions model =
    alert
        { color = model.color
        , icon = model.icon
        , content =
            [ alertTitle model.color model.title
            , alertDescription model.color model.description
            , alertActions model.actions
            ]
        }


type alias Model msg =
    { color : TwColor
    , icon : Icon
    , content : List (Html msg)
    }


alert : Model msg -> Html msg
alert model =
    div [ css [ TwColor.render Bg model.color L50, Tw.p_4, Tw.border_l_4, TwColor.render Border model.color L400 ] ]
        [ div [ css [ Tw.flex ] ]
            [ alertIcon model.color model.icon
            , div [ css [ Tw.ml_3 ] ] model.content
            ]
        ]


alertIcon : TwColor -> Icon -> Html msg
alertIcon color icon =
    div [ css [ Tw.flex_shrink_0 ] ]
        [ Icon.solid icon [ TwColor.render Text color L400 ] ]


alertTitle : TwColor -> String -> Html msg
alertTitle color title =
    h3 [ css [ Tw.text_sm, Tw.font_medium, TwColor.render Text color L800 ] ] [ text title ]


alertDescription : TwColor -> Html msg -> Html msg
alertDescription color description =
    div [ css [ Tw.mt_2, Tw.text_sm, TwColor.render Text color L700 ] ] [ description ]


alertList : TwColor -> List String -> Html msg
alertList color items =
    div [ css [ Tw.mt_2, Tw.text_sm, TwColor.render Text color L700 ] ]
        [ ul [ role "list", css [ Tw.list_disc, Tw.pl_5, Tw.space_y_1 ] ]
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
            [ ( "withDescription", withDescription { color = Yellow, icon = Exclamation, title = "Attention needed", description = text "Lorem ipsum dolor sit amet consectetur adipisicing elit. Aliquid pariatur, ipsum similique veniam quo totam eius aperiam dolorum." } )
            , ( "withList", withList { color = Red, icon = XCircle, title = "There were 2 errors with your submission", items = [ "Your password must be at least 8 characters", "Your password must include at least one pro wrestling finishing move" ] } )
            , ( "withActions", withActions { color = Green, icon = CheckCircle, title = "Order completed", description = text "Lorem ipsum dolor sit amet consectetur adipisicing elit. Aliquid pariatur, ipsum similique veniam.", actions = [ Button.light2 Green [] [ text "View status" ], Button.light2 Green [ css [ Tw.ml_3 ] ] [ text "Dismiss" ] ] } )
            ]
