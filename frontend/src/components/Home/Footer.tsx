/* src/components/Footer.tsx */
import React from 'react'
interface Props {
  style?: React.CSSProperties            // ← add this
}

const HomeFooter: React.FC<Props> = ({ style }) => (
  <footer
    className={`shrink-0 py-4 text-center text-sm text-gray-500`}
    style={style} 
  >
    © 2025 Document Chat · Built with React + Vite + shadcn/ui
  </footer>
)

export default HomeFooter
