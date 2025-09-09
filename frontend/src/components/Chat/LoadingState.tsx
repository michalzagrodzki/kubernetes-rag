// src/components/LoadingState.tsx
import React from 'react'

const LoadingState: React.FC = () => (
  <div className="flex-1 rounded-xl shadow-2xl p-4 pb-20 fade-slide-up"
    style={{ animationDelay: '0.15s' }}>
    <div className="text-center">
      <div className="inline-flex items-center space-x-2 text-gray-600">
        <div className="w-6 h-6 border-2 border-blue-500 border-t-transparent rounded-full animate-spin"></div>
        <span className="text-lg">Loading conversation...</span>
      </div>
    </div>
  </div>
)

export default LoadingState