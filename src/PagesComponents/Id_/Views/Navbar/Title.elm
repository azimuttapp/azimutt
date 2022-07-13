module PagesComponents.Id_.Views.Navbar.Title exposing (viewNavbarTitle)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.ContextMenu as ContextMenu exposing (Direction(..))
import Components.Molecules.Dropdown as Dropdown
import Components.Molecules.Tooltip as Tooltip
import Conf
import Dict exposing (Dict)
import Gen.Route as Route
import Html exposing (Html, br, button, div, small, span, text)
import Html.Attributes exposing (class, disabled, id, tabindex, type_)
import Html.Events exposing (onClick)
import Html.Lazy as Lazy
import Libs.Bool as B
import Libs.Dict as Dict
import Libs.Html exposing (bText)
import Libs.Html.Attributes exposing (ariaExpanded, ariaHaspopup, css, role)
import Libs.List as List
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Platform exposing (Platform)
import Libs.String as String
import Libs.Tailwind as Tw exposing (focus, focus_ring_offset_600)
import Libs.Task as T
import Models.Project.LayoutName exposing (LayoutName)
import Models.Project.ProjectStorage as ProjectStorage
import PagesComponents.Id_.Components.ProjectUploadDialog as ProjectUploadDialog
import PagesComponents.Id_.Models exposing (LayoutMsg(..), Msg(..), prompt)
import PagesComponents.Id_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Id_.Models.ErdLayout exposing (ErdLayout)
import PagesComponents.Id_.Models.ProjectInfo exposing (ProjectInfo)
import Shared exposing (GlobalConf)


viewNavbarTitle : GlobalConf -> ErdConf -> List ProjectInfo -> ProjectInfo -> LayoutName -> Dict LayoutName ErdLayout -> HtmlId -> HtmlId -> Html Msg
viewNavbarTitle gConf eConf projects project currentLayout layouts htmlId openedDropdown =
    div [ class "flex justify-center items-center text-white" ]
        ([ if gConf.enableCloud && eConf.projectManagement then
            button [ onClick (ProjectUploadDialogMsg ProjectUploadDialog.Open), css [ "mx-1 rounded-full", focus_ring_offset_600 Tw.primary ] ]
                [ Icon.outline (B.cond (project.storage == ProjectStorage.Browser) CloudUpload Cloud) ""
                ]
                |> Tooltip.b (B.cond (project.storage == ProjectStorage.Browser) "Sync your project" "Sync in Azimutt")

           else
            div [] []
         , if eConf.projectManagement then
            Lazy.lazy5 viewProjectsDropdown gConf.platform projects project (htmlId ++ "-projects") (openedDropdown |> String.filterStartsWith (htmlId ++ "-projects"))

           else
            div [] [ text project.name ]
         ]
            ++ viewLayoutsMaybe gConf.platform eConf currentLayout layouts (htmlId ++ "-layouts") (openedDropdown |> String.filterStartsWith (htmlId ++ "-layouts"))
        )


viewProjectsDropdown : Platform -> List ProjectInfo -> ProjectInfo -> HtmlId -> HtmlId -> Html Msg
viewProjectsDropdown platform projects project htmlId openedDropdown =
    let
        otherProjects : List ProjectInfo
        otherProjects =
            projects |> List.filter (\p -> p.id /= project.id)
    in
    Dropdown.dropdown { id = htmlId, direction = BottomRight, isOpen = openedDropdown == htmlId }
        (\m ->
            button [ type_ "button", id m.id, onClick (DropdownToggle m.id), ariaExpanded False, ariaHaspopup "true", css [ "flex justify-center items-center p-1 rounded-full", focus_ring_offset_600 Tw.primary ] ]
                [ span [] [ text project.name ]
                , Icon.solid ChevronDown ("transform transition " ++ B.cond m.isOpen "-rotate-180" "")
                ]
        )
        (\_ ->
            div [ class "divide-y divide-gray-100" ]
                (([ [ ContextMenu.btnHotkey "" SaveProject [ text "Save project" ] platform (Conf.hotkeys |> Dict.getOrElse "save" [])
                    , ContextMenu.btn "" (RenameProject |> prompt "Rename project" (text "") project.name) [ text "Rename project" ]
                    ]
                  ]
                    ++ B.cond (List.isEmpty otherProjects)
                        []
                        [ otherProjects
                            |> List.map
                                (\p ->
                                    ContextMenu.linkHtml (Route.toHref (Route.Id_ { id = p.id }))
                                        [ class "flex" ]
                                        [ Icon.outline (ProjectStorage.icon p.storage) "mr-1"
                                        , text p.name
                                        ]
                                )
                        ]
                    ++ [ [ ContextMenu.link { url = Route.toHref Route.Home_, text = "Back to dashboard" } ] ]
                 )
                    |> List.filterNot List.isEmpty
                    |> List.map (\section -> div [ role "none", class "py-1" ] section)
                )
        )


viewLayoutsMaybe : Platform -> ErdConf -> LayoutName -> Dict LayoutName ErdLayout -> HtmlId -> HtmlId -> List (Html Msg)
viewLayoutsMaybe platform conf currentLayout layouts htmlId openedDropdown =
    if conf.layoutManagement then
        [ Icon.slash "text-primary-300"
        , Lazy.lazy5 viewLayouts platform currentLayout layouts htmlId openedDropdown
        ]

    else
        [ Icon.slash "text-primary-300", text currentLayout ]


viewLayouts : Platform -> LayoutName -> Dict LayoutName ErdLayout -> HtmlId -> HtmlId -> Html Msg
viewLayouts platform currentLayout layouts htmlId openedDropdown =
    Dropdown.dropdown { id = htmlId, direction = BottomLeft, isOpen = openedDropdown == htmlId }
        (\m ->
            button [ type_ "button", id m.id, onClick (DropdownToggle m.id), ariaExpanded False, ariaHaspopup "true", css [ "flex justify-center items-center p-1 rounded-full", focus_ring_offset_600 Tw.primary ] ]
                [ span [] [ text currentLayout ]
                , Icon.solid ChevronDown ("transform transition " ++ B.cond m.isOpen "-rotate-180" "")
                ]
        )
        (\_ ->
            div [ class "min-w-max divide-y divide-gray-100" ]
                [ div [ role "none", class "py-1" ]
                    [ ContextMenu.btnHotkey "" (LOpen Nothing |> LayoutMsg) [ text "Create new layout" ] platform (Conf.hotkeys |> Dict.getOrElse "create-layout" []) ]
                , div [ role "none", class "py-1" ]
                    (layouts
                        |> Dict.toList
                        |> List.sortBy (\( name, _ ) -> name)
                        |> List.map (\( name, layout ) -> viewLayoutItem (currentLayout == name) name layout)
                    )
                ]
        )


viewLayoutItem : Bool -> LayoutName -> ErdLayout -> Html Msg
viewLayoutItem isCurrent name layout =
    span [ role "menuitem", tabindex -1, css [ "flex", B.cond isCurrent ContextMenu.itemCurrentStyles ContextMenu.itemStyles ] ]
        [ button [ type_ "button", onClick (name |> confirmDeleteLayout layout), disabled isCurrent, css [ focus [ "outline-none" ], Tw.disabled [ "text-gray-400" ] ] ] [ Icon.solid Trash "inline-block" ] |> Tooltip.t (B.cond isCurrent "" "Delete this layout")
        , button [ type_ "button", onClick (name |> Just |> LOpen |> LayoutMsg), css [ "ml-1", focus [ "outline-none" ] ] ] [ Icon.solid DocumentDuplicate "inline-block" ] |> Tooltip.t "Duplicate this layout"
        , button [ type_ "button", onClick (name |> LLoad |> LayoutMsg), css [ "flex-grow text-left ml-3", focus [ "outline-none" ] ] ]
            [ text name
            , text " "
            , small [] [ text ("(" ++ (layout.tables |> String.pluralizeL "table") ++ ")") ]
            ]
        ]


confirmDeleteLayout : ErdLayout -> LayoutName -> Msg
confirmDeleteLayout layout name =
    ConfirmOpen
        { color = Tw.red
        , icon = Trash
        , title = "Delete layout"
        , message =
            span []
                [ text "Are you sure you want to delete "
                , bText name
                , text " layout?"
                , br [] []
                , text ("It contains " ++ (layout.tables |> String.pluralizeL "table") ++ ".")
                ]
        , confirm = "Delete " ++ name ++ " layout"
        , cancel = "Cancel"
        , onConfirm = T.send (name |> LDelete |> LayoutMsg)
        }
