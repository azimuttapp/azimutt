import { Sidebar } from "../Sidebar/Sidebar"

export interface MainLayoutProps {
  children?: React.ReactNode
  sidebar?: React.ReactNode
}

export const MainLayout = ({ children, sidebar }: MainLayoutProps) => {
  return (
    <div className="min-h-svh	max-h-svh h-full overflow-hidden flex">
      <aside className="pb-4">
        <div className="min-h-svh	max-h-svh h-full overflow-y-scroll overflow-x-hidden">
          <Sidebar>{sidebar}</Sidebar>
        </div>
      </aside>
      <div className="flex-grow p-4 min-h-svh	max-h-svh h-full overflow-y-scroll overflow-x-hidden">
        <main className="flex-grow">{children}</main>
      </div>
    </div>
  )
}
