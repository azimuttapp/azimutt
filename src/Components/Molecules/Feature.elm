module Components.Molecules.Feature exposing (CheckedModel, checked, doc)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import ElmBook.Chapter exposing (chapter, renderComponentList)
import ElmBook.ElmCSS exposing (Chapter)
import Html exposing (Html, dd, div, dt, p, text)
import Html.Styled exposing (fromUnstyled)
import Libs.Html.Attributes exposing (css)


type alias CheckedModel =
    { title : String, description : Maybe String }


checked : CheckedModel -> Html msg
checked model =
    div [ css [ "relative" ] ]
        (List.filterMap identity
            [ Just (dt [] [ Icon.outline Check "absolute text-green-500", p [ css [ "ml-9 text-lg leading-6 font-medium text-gray-900" ] ] [ text model.title ] ])
            , model.description |> Maybe.map (\desc -> dd [ css [ "mt-2 ml-9 text-base text-gray-500" ] ] [ text desc ])
            ]
        )



-- DOCUMENTATION


doc : Chapter x
doc =
    chapter "Feature"
        |> renderComponentList
            [ ( "checked", checked { title = "Invite team members", description = Just "You can manage phone, email and chat conversations all from a single mailbox." } |> fromUnstyled )
            , ( "checked, no description", checked { title = "Invite team members", description = Nothing } |> fromUnstyled )
            ]
