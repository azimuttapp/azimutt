import { REPORT } from "./constants/report.constants"
import { MainLayout } from "./components/layout/MainLayout/MainLayout"
import { ReportSidebar } from "./components/report/ReportSidebar/ReportSidebar"
import { ReportContext } from "./context/ReportContext"
import { RuleLevel } from "@azimutt/models"
import { useState } from "react"
import { ViolationsTable } from "./components/report/ViolationsTable/ViolationsTable"
import { ReportStats } from "./components/report/ReportStats/ReportStats"

function App() {
  const [selectedLevels, setSelectedLevels] = useState<RuleLevel[]>([])
  const [selectedRules, setSelectedRules] = useState<string[]>([])

  const toggleLevel = (level: RuleLevel) =>
    setSelectedLevels((current) =>
      current.includes(level)
        ? current.filter((item) => item !== level)
        : [...current, level]
    )

  const toggleRule = (rule: string) =>
    setSelectedRules((current) =>
      current.includes(rule.trim())
        ? current.filter((item) => item !== rule.trim())
        : [...current, rule.trim()]
    )

  return (
    <ReportContext.Provider
      value={{
        report: REPORT,
        filters: { levels: selectedLevels, rules: selectedRules },
      }}
    >
      <MainLayout
        sidebar={
          <ReportSidebar onLevelClick={toggleLevel} onRuleClick={toggleRule} />
        }
      >
        <ReportStats />
        <ViolationsTable />
      </MainLayout>
    </ReportContext.Provider>
  )
}

export default App
