import { Logo } from "@/components/azimutt/Logo/Logo"

export const AppBar = () => {
  return (
    <div className="p-4 flex justify-between border-b border-solid">
      <a href="https://azimutt.app" target="_blank" rel="noreferrer">
        <Logo />
      </a>
    </div>
  )
}
