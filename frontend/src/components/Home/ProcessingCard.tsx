// src/components/ProcessingCard.tsx
import React from 'react'
import { Card, CardContent } from '@/components/ui'
import { Loader2 } from 'lucide-react'

interface Props {
  question: string
}

const ProcessingCard: React.FC<Props> = ({ question }) => (
  <Card className="bg-gray-100 shadow-2xl animate-fade-in">
    <CardContent className="space-y-2 py-2 text-center">
      <h2>Processing your question</h2>
      <p className="text-xl font-bold text-gray-600">{question}</p>
      <div className="flex justify-center pt-2">
        <Loader2 className="h-6 w-6 animate-spin text-blue-500" />
      </div>
    </CardContent>
  </Card>
)

export default ProcessingCard
