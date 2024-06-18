import { Sidebar } from "./Sidebar/Sidebar"

export interface MainLayoutProps {
  children?: React.ReactNode
  sidebar?: React.ReactNode
}

export const MainLayout = ({ children, sidebar }: MainLayoutProps) => {
  return (
    <div className="min-h-screen flex">
      <Sidebar>{sidebar}</Sidebar>
      <div className="flex-grow p-4">
        <main className="flex-grow">{children}</main>
      </div>
    </div>
  )
}
