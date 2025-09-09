// src/components/ErrorBanner.tsx
import React from 'react'

interface Props {
  error: string
}

const ErrorBanner: React.FC<Props> = ({ error }) => (
  <div className="mb-4 p-4 text-red-600 bg-red-50 border border-red-200 
    rounded-lg shadow-sm fade-slide-up">
    {error}
  </div>
)

export default ErrorBanner