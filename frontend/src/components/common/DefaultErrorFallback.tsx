// src/components/common/DefaultErrorFallback.tsx
import React from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { AlertTriangle, RefreshCw } from 'lucide-react';

interface Props {
  error?: Error;
  onReset?: () => void;
}

export const DefaultErrorFallback: React.FC<Props> = ({ error, onReset }) => {
  const handleReset = () => {
    onReset?.();
    // Optionally reload the page as last resort
    // window.location.reload();
  };

  return (
    <Card className="mx-auto mt-8 max-w-md">
      <CardHeader className="text-center">
        <div className="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-red-100">
          <AlertTriangle className="h-6 w-6 text-red-600" />
        </div>
        <CardTitle className="text-lg font-semibold text-red-800">
          Oops! Something went wrong
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <p className="text-center text-sm text-gray-600">
          We encountered an unexpected error. Please try refreshing the page or contact support if the problem persists.
        </p>
        
        {process.env.NODE_ENV === 'development' && error && (
          <details className="rounded bg-gray-100 p-3 text-xs">
            <summary className="cursor-pointer font-medium">Error Details (Dev Mode)</summary>
            <pre className="mt-2 whitespace-pre-wrap">{error.message}</pre>
            {error.stack && (
              <pre className="mt-2 whitespace-pre-wrap text-xs text-gray-500">
                {error.stack}
              </pre>
            )}
          </details>
        )}

        <div className="flex gap-2">
          {onReset && (
            <Button onClick={handleReset} variant="outline" className="flex-1">
              <RefreshCw className="mr-2 h-4 w-4" />
              Try Again
            </Button>
          )}
          <Button 
            onClick={() => window.location.reload()} 
            className="flex-1"
          >
            Reload Page
          </Button>
        </div>
      </CardContent>
    </Card>
  );
};