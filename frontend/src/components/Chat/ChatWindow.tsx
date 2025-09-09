// src/components/ChatWindow.tsx
import React, { memo, useEffect, useRef } from 'react'
import type { Message } from './../../store/chatStore'
import { cn } from '@/lib/utils'

export interface ChatWindowProps {
  messages: Message[]
}

const TypingDots = memo(() => (
  <div className="flex space-x-1 p-2">
    <span className="w-2 h-2 rounded-full bg-gray-400 animate-bounce [animation-delay:-.3s]" />
    <span className="w-2 h-2 rounded-full bg-gray-400 animate-bounce [animation-delay:-.15s]" />
    <span className="w-2 h-2 rounded-full bg-gray-400 animate-bounce" />
  </div>
));

const MessageItem = memo<{ message: Message }>(({ message }) => {
  return (
    <div
      className={cn(
        'flex w-full fade-slide-up',
        message.role === 'user' ? 'justify-end' : 'justify-start'
      )}
    >
      <div
        className={cn(
          'max-w-[85%] px-6 py-3 rounded-2xl shadow-md transition-all duration-300 border',
          message.role === 'user'
            ? 'bg-[#0d47a1] text-white shadow-gray-200'
            : 'bg-white/90 text-gray-800',
          message.pending ? 'opacity-70 scale-95' : 'opacity-100 scale-100',
          message.animate ? 'animate-fade-in' : ''
        )}
      >
        {message.pending ? (
          <div className="flex items-center space-x-2 fade-slide-up">
            <TypingDots />
          </div>
        ) : (
          <div className="whitespace-pre-wrap leading-relaxed">
            {message.text}
          </div>
        )}
      </div>
    </div>
  );
});

const ChatWindow: React.FC<ChatWindowProps> = ({ messages }) => {
  const bottomRef = useRef<HTMLDivElement>(null)

  // auto-scroll to bottom on new message
  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages])

  return (
    <div className="flex-1 p-2 fade-slide-up" 
      style={{ animationDelay: '0.15s' }}>
      {messages.length === 0 ? (
        <div className="flex flex-col items-center justify-center h-full text-center py-12">
          <div className="bg-white/60 backdrop-blur-sm rounded-xl p-8 shadow-lg fade-slide-up">
            <h3 className="text-xl font-semibold text-gray-700 mb-2">
              Start Your Conversation
            </h3>
            <p className="text-gray-500">
              Ask any question about your documents to get started
            </p>
          </div>
        </div>
      ) : (
        <div className="flex flex-col space-y-4 p-2 pb-16">
          {messages.map((msg) => (
            <MessageItem key={msg.id} message={ msg} />
          ))}
          <div ref={bottomRef} />
        </div>
      )}
    </div>
  )
}

export default ChatWindow