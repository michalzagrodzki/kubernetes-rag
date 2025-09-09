# RAG Client (React + Vite)

Frontend client for a Retrieval-Augmented Generation (RAG) system. It connects to the companion FastAPI backend to ask questions about your uploaded PDFs. The UI provides a simple “Document Chat” experience with conversation history, streaming answers, and a clean component setup using Tailwind and shadcn/ui.

This README focuses on the client. For the backend reference and API contract, see “RAG Web API (FastAPI + Supabase)” summary below.

## Added Value

- Fast chat over your documents with minimal setup.
- Built-in conversation handling and graceful loading/error states.
- Ready-to-style UI built on Tailwind v4 and shadcn/ui.
- Typed React + Vite project with a small, clear structure.
- Streaming answer support wired to the backend’s `/v1/query-stream` endpoint.

## Technology Stack

- React 19 + TypeScript, Vite 6
- Tailwind CSS v4, shadcn/ui, Radix primitives
- React Router DOM 7 for routing
- Zustand for state, axios + fetch for API
- ESLint (TypeScript), modern TS config

## Prerequisites

- Node.js 18+ (Node 20+ recommended)
- npm 9+ (or compatible package manager)
- Running RAG backend API (FastAPI) reachable from the browser

## Environment

Create a `.env` file in the project root (or set env at runtime) to point the client at your API. Only one variable is needed:

```
VITE_API_URL=http://localhost:8000
```

Notes:

- Default fallback is `http://localhost:8000` if `VITE_API_URL` is not set (see `src/services/http.ts`).
- Ensure backend CORS allows the Vite dev origin (e.g., `http://localhost:5173`).

## How To Run

1) Install dependencies:

```
npm install
```

2) Start the dev server (Vite):

```
npm run dev
```

Open the printed URL (usually `http://localhost:5173`).

3) Build and preview production bundle:

```
npm run build
npm run preview
```

4) Lint:

```
npm run lint
```

## Usage

- Home page lets you start a conversation by asking a question or selecting a common prompt. You’ll be navigated to `/chat/:conversationId` when the first answer arrives.
- Chat page displays the conversation, with loading states and errors surfaced from the API.
- Streaming is supported under the hood; the client currently buffers the token stream and renders upon completion for a smooth baseline UX.

Tip: Make sure you’ve uploaded and embedded PDFs via the backend API before asking questions for best results.

## Project Structure

```
.
├── index.html
├── vite.config.ts                # Vite + React + Tailwind plugin, path alias '@'
├── src/
│   ├── main.tsx                  # App bootstrap and router
│   ├── App.tsx                   # Lazy routes and error boundaries
│   ├── index.css                 # Tailwind v4 setup + theme + animations
│   ├── pages/
│   │   ├── Home.tsx              # Landing with quick prompts + form
│   │   └── Chat.tsx              # Conversation view
│   ├── components/
│   │   ├── Home/                 # Header, Footer, badges, processing card
│   │   ├── Chat/                 # ChatWindow, loading, error banner, back button
│   │   └── common/               # QuestionForm, ErrorBoundary
│   │
│   ├── services/                 # API calls
│   │   ├── http.ts               # axios instance (uses VITE_API_URL)
│   │   └── api.ts                # upload, ask, stream, list, history
│   ├── store/
│   │   └── chatStore.ts          # Zustand store for chat state
│   ├── lib/
│   │   └── utils.ts              # classnames/tw-merge helper
│   └── components/ui/            # shadcn/ui components used in app
│
├── public/                       # Static assets
├── package.json                  # Scripts and deps
├── tsconfig*.json                # TypeScript configs
├── eslint.config.js              # ESLint config
├── components.json               # shadcn/ui config
└── README.md
```

## How It Works (Client)

- The store (`src/store/chatStore.ts`) manages conversation id, messages, and loading/error state. It uses UUIDs for the initial conversation id and updates it from the backend header if the server assigns a canonical id.
- `askStream` (`src/services/api.ts`) POSTs to `/v1/query-stream` and reads the streaming body. The current implementation concatenates chunks and returns a single `answer` string, which replaces a pending “typing” placeholder in the UI.
- History loading calls `/v1/history/:conversationId` to rebuild the chat locally when navigating directly to a chat URL.

## Backend Reference (FastAPI + Supabase)

This client targets the companion RAG backend described below. Ensure it is running and reachable at `VITE_API_URL`.

RAG Web API (FastAPI + Supabase)

Retrieval-Augmented Generation (RAG) backend built with FastAPI. It ingests PDFs, chunks and embeds them into a Supabase-backed vector store, and answers questions using OpenAI with both standard and streaming responses. The service also persists basic chat history and ingestion metadata in Postgres (via SQLModel).

Added Value

- Fast start RAG backend: upload PDFs and query them immediately.
- Managed vector DB via Supabase + pgvector; simple to operate.
- Streaming answers with conversation history support.
- Clean FastAPI interface with OpenAPI docs and typed schemas.
- Async SQLModel access to Postgres for history and ingestion records.

Key Endpoints

- POST `/v1/upload` — Upload a PDF; chunks and stores embeddings; records ingestion metadata.
- GET `/v1/documents?skip=0&limit=10` — List stored documents.
- POST `/v1/query` — Non-streaming Q&A over your documents; returns answer and sources.
- POST `/v1/query-stream` — Streaming Q&A; returns token stream; response header `x-conversation-id` is set.
- GET `/v1/history/{conversation_id}` — Returns chat history for a conversation.

When hosting locally, open backend docs at `http://localhost:8000/docs`.

## Developing Further

- Token-by-token UI: stream tokens into the chat bubble for more responsive UX instead of buffering the entire stream before render.
- Upload UI: wire `uploadPdf` into a drag-and-drop uploader with progress and basic file validation.
- Sources UI: render source chunks/metadata returned by the backend alongside answers.
- Conversation management: list past conversations, rename/delete, resume.
- Theming and accessibility: dark mode toggle, focus rings, keyboard navigation.
- Error handling and retries: automatic backoff on transient errors; better empty/error states.
- Observability: add simple logging for request timings; integrate web analytics if needed.
- Deployment: add containerized Nginx or static hosting instructions with SPA fallback rules.

## Troubleshooting

- CORS errors: configure backend CORS to allow your dev origin (e.g., `http://localhost:5173`).
- 404s on refresh in `/chat/*`: configure your host to serve `index.html` for unknown routes (SPA fallback).
- Backend not reachable: confirm `VITE_API_URL`, that the server is running, and browser/network allows the connection.
- Streaming stalls: check network proxies; backend streams `text/plain` tokens.

## Scripts

- `npm run dev`: start Vite dev server.
- `npm run build`: type-check and build for production.
- `npm run preview`: preview the production build locally.
- `npm run lint`: run ESLint.

---

Happy hacking! Start the backend, set `VITE_API_URL`, then `npm run dev` to chat with your documents.
