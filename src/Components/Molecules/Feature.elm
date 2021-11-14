module Components.Molecules.Feature exposing (CheckedModel, checked, doc)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import ElmBook.Chapter exposing (chapter, renderComponentList)
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Html, dd, div, dt, p, text)
import Html.Styled.Attributes exposing (css)
import Tailwind.Utilities exposing (absolute, font_medium, leading_6, ml_9, mt_2, relative, text_base, text_gray_500, text_gray_900, text_green_500, text_lg)


type alias CheckedModel =
    { title : String, description : Maybe String }


checked : CheckedModel -> Html msg
checked model =
    div [ css [ relative ] ]
        (List.filterMap identity
            [ Just (dt [] [ Icon.view Check [ absolute, text_green_500 ], p [ css [ ml_9, text_lg, leading_6, font_medium, text_gray_900 ] ] [ text model.title ] ])
            , model.description |> Maybe.map (\desc -> dd [ css [ mt_2, ml_9, text_base, text_gray_500 ] ] [ text desc ])
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
