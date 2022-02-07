module Components.Book exposing (DocState, main)

import Components.Atoms.Badge as Badge
import Components.Atoms.Button as Button
import Components.Atoms.Dots as Dots
import Components.Atoms.Icon as Icon
import Components.Atoms.Input as Input
import Components.Atoms.Kbd as Kbd
import Components.Atoms.Link as Link
import Components.Atoms.Markdown as Markdown
import Components.Molecules.Alert as Alert
import Components.Molecules.Divider as Divider
import Components.Molecules.Dropdown as Dropdown
import Components.Molecules.Feature as Feature
import Components.Molecules.FileInput as FileInput
import Components.Molecules.ItemList as ItemList
import Components.Molecules.Modal as Modal
import Components.Molecules.Slideover as Slideover
import Components.Molecules.Toast as Toast
import Components.Molecules.Tooltip as Tooltip
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
import ElmBook
import ElmBook.Chapter as Chapter exposing (Chapter)
import ElmBook.ComponentOptions
import ElmBook.StatefulOptions
import ElmBook.ThemeOptions
import Html exposing (img, node, table, td, text, th, tr)
import Html.Attributes exposing (alt, href, rel, src)
import Libs.Html.Attributes exposing (css)
import Libs.Tailwind as Tw


type alias DocState =
    { dropdownDocState : Dropdown.DocState
    , inputDocState : Input.DocState
    , modalDocState : Modal.DocState
    , navbarDocState : Navbar.DocState
    , slideoverDocState : Slideover.DocState
    , tableDocState : Table.DocState
    , toastDocState : Toast.DocState
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
    }


main : ElmBook.Book DocState
main =
    ElmBook.book "Azimutt Design System"
        |> ElmBook.withThemeOptions
            [ ElmBook.ThemeOptions.subtitle "v0.1.0"
            , ElmBook.ThemeOptions.globals [ node "link" [ rel "stylesheet", href "/dist/tw-styles.css" ] [] ]
            , ElmBook.ThemeOptions.logo (img [ src "/logo.svg", alt "Azimutt logo", css [ "h-12" ] ] [])
            ]
        |> ElmBook.withComponentOptions [ ElmBook.ComponentOptions.fullWidth True ]
        |> ElmBook.withStatefulOptions [ ElmBook.StatefulOptions.initialState init ]
        |> ElmBook.withChapterGroups
            -- sorted alphabetically
            [ ( "", [ docs ] )
            , ( "Atoms", [ Badge.doc, Button.doc, colorsDoc, Dots.doc, Icon.doc, Input.doc, Kbd.doc, Link.doc, Markdown.doc ] )
            , ( "Molecules", [ Alert.doc, Divider.doc, Dropdown.doc, Feature.doc, FileInput.doc, ItemList.doc, Modal.doc, Slideover.doc, Toast.doc, Tooltip.doc ] )
            , ( "Organisms", [ Footer.doc, Header.doc, Navbar.doc, Relation.doc, Table.doc ] )
            , ( "Slices", [ Blog.doc, Content.doc, Cta.doc, FeatureGrid.doc, FeatureSideBySide.doc, Hero.doc, Newsletter.doc, NotFound.doc ] )
            ]


docs : Chapter x
docs =
    Chapter.chapter "Readme" |> Chapter.render """

work in progress
---
"""


colorsDoc : Chapter x
colorsDoc =
    Chapter.chapter "Colors"
        |> Chapter.renderComponentList
            [ ( "Color"
              , table []
                    (tr [] (th [] [] :: (Tw.levels |> List.map (\l -> th [ css [ "w-24 text-center" ] ] [ text (String.fromInt l) ])))
                        :: (Tw.all
                                |> List.map
                                    (\color ->
                                        tr []
                                            (th [ css [ "h-10" ] ] [ text (Tw.extractColor color) ]
                                                :: (Tw.levels |> List.map (\level -> td [ css [ "bg-" ++ Tw.extractColor color ++ "-" ++ String.fromInt level ] ] []))
                                            )
                                    )
                           )
                    )
              )
            ]
