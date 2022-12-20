module Components.Book exposing (DocState, main)

import Components.Atoms.Badge as Badge
import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon
import Components.Atoms.Input as Input
import Components.Atoms.Kbd as Kbd
import Components.Atoms.Link as Link
import Components.Atoms.Loader as Loader
import Components.Atoms.Markdown as Markdown
import Components.Molecules.Alert as Alert
import Components.Molecules.Avatar as Avatar
import Components.Molecules.Divider as Divider
import Components.Molecules.Dropdown as Dropdown
import Components.Molecules.Editor as Editor
import Components.Molecules.FileInput as FileInput
import Components.Molecules.FormLabel as FormLabel
import Components.Molecules.InputText as InputText
import Components.Molecules.ItemList as ItemList
import Components.Molecules.Modal as Modal
import Components.Molecules.Popover as Popover
import Components.Molecules.Select as Select
import Components.Molecules.Slideover as Slideover
import Components.Molecules.Toast as Toast
import Components.Molecules.Tooltip as Tooltip
import Components.Organisms.ColorPicker as ColorPicker
import Components.Organisms.Details as Details
import Components.Organisms.Navbar as Navbar
import Components.Organisms.Relation as Relation
import Components.Organisms.Table as Table
import Components.Slices.NewLayoutBody as NewLayoutBody
import Components.Slices.NotFound as NotFound
import Components.Slices.ProPlan as ProPlan
import Components.Slices.ProjectSaveDialogBody as ProjectSaveDialogBody
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
    { detailsDocState : Details.DocState
    , dropdownDocState : Dropdown.DocState
    , formLabelDocState : FormLabel.DocState
    , inputDocState : Input.DocState
    , inputTextDocState : InputText.DocState
    , modalDocState : Modal.DocState
    , navbarDocState : Navbar.DocState
    , newLayoutDocState : NewLayoutBody.DocState
    , popoverDocState : Popover.DocState
    , projectSaveDocState : ProjectSaveDialogBody.DocState
    , selectDocState : Select.DocState
    , slideoverDocState : Slideover.DocState
    , tableDocState : Table.DocState
    , toastDocState : Toast.DocState
    }


init : DocState
init =
    { detailsDocState = Details.initDocState
    , dropdownDocState = Dropdown.initDocState
    , formLabelDocState = FormLabel.initDocState
    , inputDocState = Input.initDocState
    , inputTextDocState = InputText.initDocState
    , modalDocState = Modal.initDocState
    , navbarDocState = Navbar.initDocState
    , newLayoutDocState = NewLayoutBody.initDocState
    , popoverDocState = Popover.initDocState
    , projectSaveDocState = ProjectSaveDialogBody.initDocState
    , selectDocState = Select.initDocState
    , slideoverDocState = Slideover.initDocState
    , tableDocState = Table.initDocState
    , toastDocState = Toast.initDocState
    }


main : ElmBook.Book DocState
main =
    ElmBook.book "Azimutt Design System"
        |> ElmBook.withThemeOptions
            [ ElmBook.ThemeOptions.subtitle "v0.1.0"
            , ElmBook.ThemeOptions.globals [ node "link" [ rel "stylesheet", href "/dist/styles.css" ] [] ]
            , ElmBook.ThemeOptions.logo (img [ src "/logo_icon_light.svg", alt "Azimutt logo", css [ "h-12" ] ] [])
            ]
        |> ElmBook.withComponentOptions [ ElmBook.ComponentOptions.fullWidth True ]
        |> ElmBook.withStatefulOptions [ ElmBook.StatefulOptions.initialState init ]
        |> ElmBook.withChapterGroups
            -- sorted alphabetically
            [ ( "", [ docs ] )
            , ( "Slices", [ NotFound.doc, NewLayoutBody.doc, ProjectSaveDialogBody.doc, ProPlan.doc ] )
            , ( "Organisms", [ ColorPicker.doc, Details.doc, Navbar.doc, Relation.doc, Table.doc ] )
            , ( "Molecules", [ Alert.doc, Avatar.doc, Divider.doc, Dropdown.doc, Editor.doc, FileInput.doc, FormLabel.doc, InputText.doc, ItemList.doc, Modal.doc, Popover.doc, Select.doc, Slideover.doc, Toast.doc, Tooltip.doc ] )
            , ( "Atoms", [ Badge.doc, Button.doc, colorsDoc, Icon.doc, Input.doc, Kbd.doc, Markdown.doc, Link.doc, Loader.doc ] )
            ]


docs : Chapter x
docs =
    Chapter.chapter "Overview" |> Chapter.render """
Azimutt is an application to help you **explore** your database but not only, it also supports **creation/modification**, **documentation** and even **analysis** 🎉

It's available on [https://azimutt.app](https://azimutt.app) and the code is on [https://github.com/azimuttapp/azimutt](https://github.com/azimuttapp/azimutt).

This documentation if for components, mainly aim at developers.
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
