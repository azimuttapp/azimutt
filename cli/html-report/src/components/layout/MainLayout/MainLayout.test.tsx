import { render, screen } from "@testing-library/react"
import { MainLayout } from "./MainLayout"

describe("MainLayout", async () => {
  test("Should render content", () => {
    render(
      <MainLayout>
        <p>Content</p>
      </MainLayout>
    )

    expect(screen.getByText("Content")).toBeDefined()
  })

  test("Should render sidebar", () => {
    render(
      <MainLayout sidebar={<aside>Sidebar</aside>}>
        <p>Content</p>
      </MainLayout>
    )

    expect(screen.getByText("Sidebar")).toBeDefined()
  })
})
