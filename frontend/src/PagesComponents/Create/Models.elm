module PagesComponents.Create.Models exposing (Model, Msg(..))

import Models.Project exposing (Project)
import Models.Project.ProjectName exposing (ProjectName)
import Models.Project.ProjectStorage exposing (ProjectStorage)
import Ports exposing (JsMsg)
import Services.DatabaseSource as DatabaseSource
import Services.JsonSource as JsonSource
import Services.PrismaSource as PrismaSource
import Services.SqlSource as SqlSource
import Services.Toasts as Toasts


type alias Model =
    { databaseSource : Maybe (DatabaseSource.Model Msg)
    , sqlSource : Maybe (SqlSource.Model Msg)
    , prismaSource : Maybe (PrismaSource.Model Msg)
    , jsonSource : Maybe (JsonSource.Model Msg)

    -- global attrs
    , toasts : Toasts.Model
    }


type Msg
    = InitProject
    | DatabaseSourceMsg DatabaseSource.Msg
    | SqlSourceMsg SqlSource.Msg
    | PrismaSourceMsg PrismaSource.Msg
    | JsonSourceMsg JsonSource.Msg
    | AmlSourceMsg (Maybe ProjectStorage) ProjectName
    | CreateProjectTmp (Maybe ProjectStorage) Project
      -- global messages
    | Toast Toasts.Msg
    | JsMessage JsMsg
