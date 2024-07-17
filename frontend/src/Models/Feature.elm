module Models.Feature exposing (ai, aml, analysis, colors, dataExploration, layoutTables, projectDbs, projectDoc, projectExport, projectLayouts, projectShare, projects, schemaExport)


ai : { name : String, default : Bool }
ai =
    { name = "ai", default = False }


aml : { name : String, default : Bool }
aml =
    { name = "aml", default = False }


analysis : { name : String, preview : String, snapshot : String, trends : String, limit : Int, default : Bool }
analysis =
    { name = "analysis", preview = "preview", snapshot = "snapshot", trends = "trends", limit = 3, default = False }


colors : { name : String, default : Bool }
colors =
    { name = "colors", default = False }


dataExploration : { name : String }
dataExploration =
    { name = "data_exploration" }


layoutTables : { name : String, default : Int }
layoutTables =
    { name = "layout_tables", default = 10 }


projects : { name : String, default : Int }
projects =
    { name = "projects", default = 0 }


projectDbs : { name : String }
projectDbs =
    { name = "project_dbs" }


projectDoc : { name : String }
projectDoc =
    { name = "project_doc" }


projectExport : { name : String }
projectExport =
    { name = "project_export" }


projectLayouts : { name : String, default : Int }
projectLayouts =
    { name = "project_layouts", default = 1 }


projectShare : { name : String, default : Bool }
projectShare =
    { name = "project_share", default = False }


schemaExport : { name : String, default : Bool }
schemaExport =
    { name = "schema_export", default = False }
