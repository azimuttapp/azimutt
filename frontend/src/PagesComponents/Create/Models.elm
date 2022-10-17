module PagesComponents.Create.Models exposing (Model, Msg(..))

import Models.Project exposing (Project)
import Models.Project.ProjectName exposing (ProjectName)
import Models.ProjectInfo exposing (ProjectInfo)
import Ports exposing (JsMsg)
import Services.DatabaseSource as DatabaseSource
import Services.JsonSource as JsonSource
import Services.SqlSource as SqlSource
import Services.Toasts as Toasts


type alias Model =
    { projects : List ProjectInfo
    , databaseSource : Maybe (DatabaseSource.Model Msg)
    , sqlSource : Maybe (SqlSource.Model Msg)
    , jsonSource : Maybe (JsonSource.Model Msg)
    , projectName : ProjectName

    -- global attrs
    , toasts : Toasts.Model
    }


type Msg
    = InitProject
    | DatabaseSourceMsg DatabaseSource.Msg
    | SqlSourceMsg SqlSource.Msg
    | JsonSourceMsg JsonSource.Msg
    | AmlSourceMsg
    | CreateProjectTmp Project
      -- global messages
    | Toast Toasts.Msg
    | JsMessage JsMsg
