import { REPORT } from "./constants/report.constants"
import { MainLayout } from "./components/layout/MainLayout/MainLayout"
import { ReportSidebar } from "./components/report/ReportSidebar/ReportSidebar"
import { ReportContext } from "./context/ReportContext"
import { ViolationsList } from "./components/report/ViolationsList/ViolationsList"

function App() {
  return (
    <ReportContext.Provider value={REPORT}>
      <MainLayout sidebar={<ReportSidebar />}>
        <ViolationsList />
      </MainLayout>
    </ReportContext.Provider>
  )
}

export default App
