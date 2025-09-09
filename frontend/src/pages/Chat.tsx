// src/pages/Chat.tsx
import React, { useEffect, useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import ChatWindow from '../components/Chat/ChatWindow'
import { QuestionForm } from '../components/common/QuestionForm'
import { useChatStore } from '../store/chatStore'
import BackHomeButton from '../components/Chat/BackHomeButton'
import ErrorBanner from '@/components/Chat/ErrorBanner'
import LoadingState from '@/components/Chat/LoadingState'

const Chat: React.FC = () => {
  const { conversationId: routeCid } = useParams<{ conversationId?: string }>()
  const navigate = useNavigate()

  const {
    conversationId,
    messages,
    loading,
    error,
    loadHistory,
    sendMessage,
    clearChat,
  } = useChatStore()

  const [question, setQuestion] = useState('')

  useEffect(() => {
    if (!routeCid) return

    const needFresh =
      conversationId !== routeCid || messages.length === 0

    if (needFresh) {
      loadHistory(routeCid)
    }
  }, [routeCid, conversationId, messages.length, loadHistory])

  useEffect(() => clearChat, [clearChat])
  
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!question.trim()) return

    await sendMessage(question)
    if (!routeCid && conversationId) {
      navigate(`/chat/${conversationId}`, { replace: true })
    }

    setQuestion('')
  }

  return (
    <div className="min-h-screen bg-gray-100">
      <BackHomeButton />
      <main className="flex flex-col">
        <div className="flex-1 max-w-4xl mx-auto w-full fade-slide-up" style={{ animationDelay: '0.15s' }}>
          {error && (
            <ErrorBanner error={error} />
          )}

          {(messages.length > 0 || !loading) && (
            <ChatWindow messages={messages} />
          )}
          
          {(loading && messages.length === 0) && (
            <LoadingState />
          )}
        </div>
      </main>
      <div className="fixed bottom-0 left-0 right-0 bg-white/95 border-gray-200 p-4 fade-slide-up z-20" 
        style={{ animationDelay: '0,5s' }}>
        <div className="max-w-4xl mx-auto">
          <QuestionForm
            question={question}
            setQuestion={setQuestion}
            onSubmit={handleSubmit}
            disabled={loading}
          />
        </div>
      </div>
    </div>
  )
}

export default Chat
