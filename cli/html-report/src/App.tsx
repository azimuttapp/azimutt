import { useEffect } from "react"
import { REPORT } from "./constants/report.constants"
import { Button } from "./components/ui/button"
import { MainLayout } from "./components/layout/MainLayout"
import { ReportSidebar } from "./components/report/ReportSidebar/ReportSidebar"

function App() {
  useEffect(() => {
    console.log(REPORT)
  }, [])

  return (
    <MainLayout sidebar={<ReportSidebar />}>
      <Button>Azimutt</Button>
    </MainLayout>
  )
}

export default App
