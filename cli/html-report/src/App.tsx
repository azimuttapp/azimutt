import { REPORT } from "./constants/report.constants"
import { Button } from "./components/ui/button"
import { MainLayout } from "./components/layout/MainLayout"
import { ReportSidebar } from "./components/report/ReportSidebar/ReportSidebar"
import { ReportContext } from "./context/ReportContext"

function App() {
  return (
    <ReportContext.Provider value={REPORT}>
      <MainLayout sidebar={<ReportSidebar />}>
        <Button>Azimutt</Button>
      </MainLayout>
    </ReportContext.Provider>
  )
}

export default App
