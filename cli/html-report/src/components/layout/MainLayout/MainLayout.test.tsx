import { render, screen } from "@testing-library/react"
import { MainLayout } from "./MainLayout"

describe("MainLayout", () => {
  test("Should render content", () => {
    render(
      <MainLayout>
        <p>Content</p>
      </MainLayout>
    )

    expect(screen.getByText("Content")).toBeDefined()
  })
})
