module Components.Molecules.Feature exposing (CheckedModel, checked, doc)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import ElmBook.Chapter exposing (chapter, renderComponentList)
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Html, dd, div, dt, p, text)
import Html.Styled.Attributes exposing (css)
import Tailwind.Utilities as Tw


type alias CheckedModel =
    { title : String, description : Maybe String }


checked : CheckedModel -> Html msg
checked model =
    div [ css [ Tw.relative ] ]
        (List.filterMap identity
            [ Just (dt [] [ Icon.outline Check [ Tw.absolute, Tw.text_green_500 ], p [ css [ Tw.ml_9, Tw.text_lg, Tw.leading_6, Tw.font_medium, Tw.text_gray_900 ] ] [ text model.title ] ])
            , model.description |> Maybe.map (\desc -> dd [ css [ Tw.mt_2, Tw.ml_9, Tw.text_base, Tw.text_gray_500 ] ] [ text desc ])
            ]
        )



-- DOCUMENTATION


doc : Chapter x
doc =
    chapter "Feature"
        |> renderComponentList
            [ ( "checked", checked { title = "Invite team members", description = Just "You can manage phone, email and chat conversations all from a single mailbox." } )
            , ( "checked, no description", checked { title = "Invite team members", description = Nothing } )
            ]
