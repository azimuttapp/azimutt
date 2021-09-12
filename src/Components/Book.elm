module Components.Book exposing (main)

import Components.Atoms.Button as Button
import Components.Atoms.Dots as Dots
import Components.Atoms.Icon as Icon
import Components.Atoms.Link as Link
import Components.Organisms.Footer as Footer
import Components.Organisms.Header as Header
import Components.Slices.Cta as Cta
import Components.Slices.FeatureGrid as FeatureGrid
import Components.Slices.FeatureSideBySide as FeatureSideBySide
import Components.Slices.Hero as Hero
import Css.Global as Global
import ElmBook exposing (withChapterGroups, withComponentOptions, withThemeOptions)
import ElmBook.Chapter exposing (chapter, render)
import ElmBook.ComponentOptions
import ElmBook.ElmCSS exposing (Book, Chapter, book)
import ElmBook.ThemeOptions
import Html.Styled exposing (Html, img)
import Html.Styled.Attributes exposing (alt, css, src)
import Tailwind.Breakpoints exposing (sm)
import Tailwind.Utilities exposing (globalStyles, h_6, h_8, w_auto)


main : Book x
main =
    book "Azimutt Design System"
        |> withThemeOptions [ ElmBook.ThemeOptions.subtitle "v0.1.0", ElmBook.ThemeOptions.globals [ Global.global globalStyles ], ElmBook.ThemeOptions.logo logo ]
        |> withComponentOptions [ ElmBook.ComponentOptions.fullWidth True ]
        |> withChapterGroups
            [ ( "", [ docs ] )
            , ( "Atoms", [ Link.doc, Button.doc, Icon.doc, Dots.doc ] )
            , ( "Molecules", [] )
            , ( "Organisms", [ Header.doc, Footer.doc ] )
            , ( "Slices", [ Hero.doc, FeatureGrid.doc, FeatureSideBySide.doc, Cta.doc ] )
            ]


logo : Html msg
logo =
    img [ src "/logo.svg", alt "Azimutt elm-book", css [ h_8, w_auto, sm [ h_6 ] ] ] []


docs : Chapter x
docs =
    chapter "Readme" |> render """

work in progress
---
"""
