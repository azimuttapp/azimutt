module Models.Feature exposing (ai, aml, analysis, colors, dataExploration, groups, layoutTables, memos, projectDbs, projectDoc, projectExport, projectLayouts, projectShare, projects, schemaExport)


ai : { name : String }
ai =
    { name = "ai" }


aml : { name : String }
aml =
    { name = "aml" }


analysis : { name : String, preview : String, snapshot : String, trends : String }
analysis =
    { name = "analysis", preview = "preview", snapshot = "snapshot", trends = "trends" }


colors : { name : String }
colors =
    { name = "colors" }


dataExploration : { name : String }
dataExploration =
    { name = "data_exploration" }


layoutTables : { name : String, default : Int }
layoutTables =
    { name = "layout_tables", default = 3 }


memos : { name : String, default : Int }
memos =
    { name = "memos", default = 3 }


groups : { name : String, default : Int }
groups =
    { name = "groups", default = 3 }


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


projectLayouts : { name : String }
projectLayouts =
    { name = "project_layouts" }


projectShare : { name : String }
projectShare =
    { name = "project_share" }


schemaExport : { name : String }
schemaExport =
    { name = "schema_export" }
