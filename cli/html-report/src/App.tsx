import { REPORT } from "./constants/report.constants"
import { MainLayout } from "./components/layout/MainLayout/MainLayout"
import { ReportContext } from "./context/ReportContext"
import { RuleLevel } from "@azimutt/models"
import { useState } from "react"
import { ReportStats } from "./components/report/ReportStats/ReportStats"
import { ReportFilters } from "./components/report/ReportFilters/ReportFilters"
import { ViolationsList } from "./components/report/ViolationsList/ViolationsList"

function App() {
  const [selectedLevels, setSelectedLevels] = useState<RuleLevel[]>([])
  const [selectedCategories, setSelectedCategories] = useState<string[]>([])
  const [selectedRules, setSelectedRules] = useState<string[]>([])
  const [selectedTables, setSelectedTables] = useState<string[]>([])

  const handleChange =
    (setter: React.Dispatch<React.SetStateAction<any[]>>) => (value: any[]) => {
      setter(value)
    }

  return (
    <ReportContext.Provider
      value={{
        report: REPORT,
        filters: {
          levels: selectedLevels,
          categories: selectedCategories,
          rules: selectedRules,
          tables: selectedTables,
        },
      }}
    >
      <MainLayout>
        <div className="grid gap-5 grid-cols-1">
          <ReportStats />
          <ReportFilters
            onSeveritiesChange={handleChange(setSelectedLevels)}
            onCategoriesChange={handleChange(setSelectedCategories)}
            onRulesChange={handleChange(setSelectedRules)}
            onTablesChange={handleChange(setSelectedTables)}
          />
          <ViolationsList />
        </div>
      </MainLayout>
    </ReportContext.Provider>
  )
}

export default App
