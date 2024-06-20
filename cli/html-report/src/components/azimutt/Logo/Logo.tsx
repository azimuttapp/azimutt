export interface LogoProps {
  className?: string
}

export const Logo = ({ className }: LogoProps) => {
  return (
    <img
      className={className}
      src={`https://azimutt.app/images/logo_dark.svg`}
      style={{ height: 32 }}
    />
  )
}
