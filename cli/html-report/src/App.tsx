import { useEffect } from "react"
import { REPORT } from "./constants/report.constants"
import { Button } from "./components/ui/button"

function App() {

  useEffect(() => {
    console.log(REPORT)
  }, [])

  return (
    <>
      <Button>Azimutt</Button>
    </>
  )
}

export default App
