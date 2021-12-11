module PagesComponents.Projects.Id_.Models exposing (Model, Msg(..), NavbarModel)

import Components.Molecules.Toast as Toast
import Models.Project.ProjectId exposing (ProjectId)
import Shared exposing (Confirm)


type alias Model =
    { projectId : ProjectId
    , navbar : NavbarModel
    , openedDropdown : String
    , confirm : Confirm Msg
    , toastCpt : Int
    , toasts : List Toast.Model
    }


type alias NavbarModel =
    { mobileMenuOpen : Bool }


type Msg
    = ToggleMobileMenu
    | ToggleDropdown String
    | ShowAllTables
    | HideAllTables
    | ResetCanvas
    | LayoutMsg
    | VirtualRelationMsg
    | FindPathMsg
    | Noop
