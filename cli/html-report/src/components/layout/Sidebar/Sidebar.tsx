export interface SidebarProps {
  children?: React.ReactNode
}

export const Sidebar = ({ children }: SidebarProps) => {
  return (
    <div className="min-h-screen w-64 h-full flex flex-col">{children}</div>
  )
}
