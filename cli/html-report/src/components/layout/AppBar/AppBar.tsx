import { Logo } from "@/components/azimutt/Logo/Logo"

export interface AppBarProps {}

export const AppBar = ({}: AppBarProps) => {
  return (
    <div className="p-4 flex justify-between border-b border-solid">
      <a href="https://azimutt.app" target="_blank">
        <Logo />
      </a>
    </div>
  )
}
