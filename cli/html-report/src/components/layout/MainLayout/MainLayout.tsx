import { AppBar } from "../AppBar/AppBar"

export interface MainLayoutProps {
  children?: React.ReactNode
}

export const MainLayout = ({ children }: MainLayoutProps) => {
  return (
    <div className="min-h-svh	max-h-svh h-full overflow-hidden p-2">
      <AppBar />
      <div className="flex pb-16">
        <div className="flex-grow p-4 min-h-[90svh]	max-h-[90svh] h-full overflow-y-scroll overflow-x-hidden">
          <main className="flex-grow">{children}</main>
        </div>
      </div>
    </div>
  )
}
