module PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf, embedDefault, project)

import Models.ProjectTokenId exposing (ProjectTokenId)


type alias ErdConf =
    { fullscreen : Bool -- to allow fullscreen button
    , save : Bool -- to allow to save the project
    , hover : Bool -- to be responsive to the hover (column & link highlight)
    , select : Bool -- to allow to select tables
    , move : Bool -- to allow to move tables
    , layout : Bool -- to allow to update the current layout
    , update : Bool -- to enable AML sources button
    , showNavbar : Bool -- to show navbar
    , dashboardLink : Bool -- if top left Azimutt link send to home or landing page
    , findPath : Bool -- to allow find path feature
    , layoutManagement : Bool -- to allow to create & change layouts
    , projectManagement : Bool -- to allow to change, update or create projects
    , sharing : Bool -- to display embed button
    }


project : Maybe ProjectTokenId -> ErdConf
project token =
    -- used for real app
    -- if token is present, we are in sharing mode so disabled the sharing menu and the save action
    { fullscreen = False
    , save = token == Nothing
    , hover = True
    , select = True
    , move = True
    , layout = True
    , update = True
    , showNavbar = True
    , dashboardLink = True
    , findPath = True
    , layoutManagement = True
    , projectManagement = True
    , sharing = token == Nothing
    }


embedDefault : ErdConf
embedDefault =
    -- used for embed app
    { fullscreen = True
    , save = False
    , hover = False
    , select = False
    , move = False
    , layout = False
    , update = False
    , showNavbar = False
    , dashboardLink = False
    , findPath = False
    , layoutManagement = False
    , projectManagement = False
    , sharing = False
    }
