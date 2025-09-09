import { memo, useCallback } from 'react';
import { Badge } from '@/components/ui/badge'

interface Props {
  label: string
  onClick: (value: string) => void
}

const QuestionBadge = memo<Props>(({ label, onClick }) => {
  const handleClick = useCallback(() => {
    onClick(label);
  }, [label, onClick]);

  return (
    <Badge
      variant="outline"
      className="cursor-pointer border-gray-400 text-gray-500 hover:bg-gray-200"
      onClick={handleClick}
    >
      {label}
    </Badge>
  );
});

export default QuestionBadge
