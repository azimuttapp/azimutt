module Components.Book exposing (DocState, main)

import Components.Atoms.Badge as Badge
import Components.Atoms.Badge2 as Badge2
import Components.Atoms.Button as Button
import Components.Atoms.Dots as Dots
import Components.Atoms.Icon as Icon
import Components.Atoms.Input as Input
import Components.Atoms.Kbd as Kbd
import Components.Atoms.Kbd2 as Kbd2
import Components.Atoms.Link as Link
import Components.Atoms.Markdown as Markdown
import Components.Atoms.Styles as Styles
import Components.Molecules.Alert as Alert
import Components.Molecules.Alert2 as Alert2
import Components.Molecules.Divider as Divider
import Components.Molecules.Dropdown as Dropdown
import Components.Molecules.Dropdown2 as Dropdown2
import Components.Molecules.Feature as Feature
import Components.Molecules.FileInput as FileInput
import Components.Molecules.ItemList as ItemList
import Components.Molecules.Modal as Modal
import Components.Molecules.Modal2 as Modal2
import Components.Molecules.Slideover as Slideover
import Components.Molecules.Toast as Toast
import Components.Molecules.Toast2 as Toast2
import Components.Molecules.Tooltip as Tooltip
import Components.Molecules.Tooltip2 as Tooltip2
import Components.Organisms.Footer as Footer
import Components.Organisms.Header as Header
import Components.Organisms.Navbar as Navbar
import Components.Organisms.Relation as Relation
import Components.Organisms.Table as Table
import Components.Slices.Blog as Blog
import Components.Slices.Content as Content
import Components.Slices.Cta as Cta
import Components.Slices.FeatureGrid as FeatureGrid
import Components.Slices.FeatureSideBySide as FeatureSideBySide
import Components.Slices.Hero as Hero
import Components.Slices.Newsletter as Newsletter
import Components.Slices.NotFound as NotFound
import Css.Global as Global
import ElmBook
import ElmBook.Chapter as Chapter
import ElmBook.ComponentOptions
import ElmBook.ElmCSS as ElmCSS
import ElmBook.StatefulOptions
import ElmBook.ThemeOptions
import Html.Styled exposing (Html, img, node, table, td, text, th, tr)
import Html.Styled.Attributes exposing (alt, css, href, rel, src)
import Libs.Models.Color as Color exposing (Color, ColorLevel)
import Tailwind.Utilities as Tw


type alias DocState =
    { dropdownDocState : Dropdown.DocState
    , inputDocState : Input.DocState
    , modalDocState : Modal.DocState
    , navbarDocState : Navbar.DocState
    , slideoverDocState : Slideover.DocState
    , tableDocState : Table.DocState
    , toastDocState : Toast.DocState
    , toastDocState2 : Toast2.DocState
    }


init : DocState
init =
    { dropdownDocState = Dropdown.initDocState
    , inputDocState = Input.initDocState
    , modalDocState = Modal.initDocState
    , navbarDocState = Navbar.initDocState
    , slideoverDocState = Slideover.initDocState
    , tableDocState = Table.initDocState
    , toastDocState = Toast.initDocState
    , toastDocState2 = Toast2.initDocState
    }


theme : { color : Color }
theme =
    { color = Color.indigo }


main : ElmCSS.Book DocState
main =
    ElmCSS.book "Azimutt Design System"
        |> ElmBook.withThemeOptions
            [ ElmBook.ThemeOptions.subtitle "v0.1.0"
            , ElmBook.ThemeOptions.globals [ Global.global Tw.globalStyles, Styles.global, node "link" [ rel "stylesheet", href "/dist/tw-styles.css" ] [] ]
            , ElmBook.ThemeOptions.logo (img [ src "/logo.svg", alt "Azimutt logo", css [ Tw.h_12 ] ] [])
            ]
        |> ElmBook.withComponentOptions [ ElmBook.ComponentOptions.fullWidth True ]
        |> ElmBook.withStatefulOptions [ ElmBook.StatefulOptions.initialState init ]
        |> ElmBook.withChapterGroups
            -- sorted alphabetically
            [ ( "", [ docs ] )
            , ( "Atoms", [ Badge.doc theme, Badge2.doc theme, Button.doc theme, colorsDoc, Dots.doc, Icon.doc, Input.doc theme, Kbd.doc, Kbd2.doc, Link.doc theme, Markdown.doc ] )
            , ( "Molecules", [ Alert.doc, Alert2.doc, Divider.doc, Dropdown.doc theme, Dropdown2.doc theme, Feature.doc, FileInput.doc theme, ItemList.doc theme, Modal.doc theme, Modal2.doc theme, Slideover.doc theme, Toast.doc theme, Toast2.doc theme, Tooltip.doc, Tooltip2.doc ] )
            , ( "Organisms", [ Footer.doc, Header.doc, Navbar.doc theme, Relation.doc, Table.doc ] )
            , ( "Slices", [ Blog.doc, Content.doc, Cta.doc, FeatureGrid.doc, FeatureSideBySide.doc, Hero.doc, Newsletter.doc, NotFound.doc theme ] )
            ]


docs : ElmCSS.Chapter x
docs =
    Chapter.chapter "Readme" |> Chapter.render """

work in progress
---
"""


colorsDoc : ElmCSS.Chapter x
colorsDoc =
    Chapter.chapter "Colors"
        |> Chapter.renderComponentList
            [ ( "Color"
              , table []
                    (tr [] (th [] [] :: (Color.levels |> List.map (\l -> th [] [ text (String.fromInt l) ])))
                        :: (Color.all |> List.map (\color -> tr [] (th [] [ text color.name ] :: (Color.levels |> List.map (viewColorCell color)))))
                    )
              )
            ]


viewColorCell : Color -> ColorLevel -> Html msg
viewColorCell color level =
    td [ css [ Tw.p_3, Color.bg color level ] ] [ text (color |> Color.hex level) ]
