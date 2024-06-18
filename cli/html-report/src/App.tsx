import { useEffect } from "react"
import { REPORT } from "./constants/report.constants"

function App() {

  useEffect(() => {
    console.log(REPORT)
  }, [])

  return (
    <>
      Hello Azimutt
    </>
  )
}

export default App
