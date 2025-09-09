import { Link } from 'react-router-dom'
import { ArrowLeft } from 'lucide-react'          // shadcn uses lucide icons

const BackHomeButton: React.FC = () => (
  <Link
    to="/"
    aria-label="Back to Home"
    className="group fixed top-4 left-4 z-30 p-2 rounded-full bg-white shadow-md
               hover:bg-blue-50 transition-colors"
  >
    <ArrowLeft className="h-5 w-5 text-gray-700 group-hover:text-blue-600" />
  </Link>
)

export default BackHomeButton
