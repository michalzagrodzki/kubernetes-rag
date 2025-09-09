import { memo, useCallback } from 'react';
import QuestionBadge from './QuestionBadge'

interface Props {
  onSelect: (q: string) => void
}

const commonQuestions = [
  'Can you provide an overview of the experiment?',
  'What are the main findings discussed in this document?',
  'What is the significance of the findings in this research paper?',
  'How was the experiment structured?',
  'What were the key tasks involved in this experiment?',
  'What role did group discussions play?',
  'What insights were gained about memory and intelligence?',
  'What implications do the results of this research have in real-world settings?'
] as const

const CommonQuestionsRow = memo<Props>(({ onSelect }) => {
  // Memoize the callback to prevent QuestionBadge re-renders
  const handleSelect = useCallback((question: string) => {
    onSelect(question);
  }, [onSelect]);

  return (
    <div className="flex flex-wrap justify-center gap-2 mb-6">
      {commonQuestions.map((q) => (
        <QuestionBadge 
          key={q} 
          label={q} 
          onClick={handleSelect} 
        />
      ))}
    </div>
  );
});

export default CommonQuestionsRow
