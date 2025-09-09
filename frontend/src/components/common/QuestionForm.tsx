// src/components/QuestionForm.tsx
import React from 'react'
import { Button, Input } from '@/components/ui'
import { Loader2 } from 'lucide-react'  

export interface QuestionFormProps {
  question: string
  setQuestion: (q: string) => void
  onSubmit: (e: React.FormEvent) => void
  disabled?: boolean
}

export const QuestionForm: React.FC<QuestionFormProps> = ({
  question,
  setQuestion,
  onSubmit,
  disabled = false,
}) => {
  return (
    <form onSubmit={onSubmit} className="flex space-x-2">
      <Input
        className="flex-1"
        placeholder="Type your question…"
        value={question}
        onChange={(e) => setQuestion(e.target.value)}
        disabled={disabled}
      />

      <Button type="submit" disabled={disabled} className="
        bg-[#0d47a1] hover:bg-[#093372] active:bg-[#051d3f] text-white
      ">
        {disabled ? <Loader2 className="h-4 w-4 animate-spin" /> : 'Send'}
      </Button>
    </form>
  )
}
