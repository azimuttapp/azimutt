import { render, screen } from "@testing-library/react"
import { Sidebar } from "./Sidebar"

describe("Sidebar", async () => {
  test("Should render", () => {
    render(
      <Sidebar>
        <p>My sidebar</p>
      </Sidebar>
    )

    expect(screen.getByText("My sidebar")).toBeDefined()
  })
})
