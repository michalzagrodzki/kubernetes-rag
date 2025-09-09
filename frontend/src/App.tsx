
import { Routes, Route } from 'react-router-dom';
import { lazy, Suspense } from 'react';
import ErrorBoundary from './components/common/ErrorBoundary';
import { DefaultErrorFallback } from './components/common/DefaultErrorFallback';

const Home = lazy(() => import('./pages/Home'));
const Chat = lazy(() => import('./pages/Chat'));

const handleAppError = (error: Error, errorInfo: React.ErrorInfo) => {
  console.error('App-level error:', error, errorInfo);
};

function App() {
  return (
    <ErrorBoundary 
      fallback={<DefaultErrorFallback />}
      onError={handleAppError}
    >
      <Suspense>
        <Routes>
          <Route path='/' element={<Home />} />
          <Route path='/chat/:conversationId?' element={<Chat />} />
        </Routes>
      </Suspense>
    </ErrorBoundary>
  )
}

export default App
