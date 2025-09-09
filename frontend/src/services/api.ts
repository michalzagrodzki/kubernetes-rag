/* eslint-disable @typescript-eslint/no-explicit-any */
import { http } from "./http";

export interface UploadResponse {
  message: string;
  inserted_count: number;
}

export interface QueryResponse {
  answer: string;
  source_docs: any[];
  conversation_id?: string;
}

export interface AskStreamResult {
  answer: string;
  conversation_id?: string; // echoed or assigned by backend
  headers: Headers;
}

export const uploadPdf = (file: File) => {
  const form = new FormData();
  form.append("file", file, file.name);
  return http.post<UploadResponse>("/v1/upload", form, {
    headers: { "Content-Type": "multipart/form-data" },
  });
};

export const listDocuments = (skip = 0, limit = 10) =>
  http.get<any[]>(`/v1/documents?skip=${skip}&limit=${limit}`);

export const ask = (question: string, conversationId?: string) =>
  http.post<QueryResponse>("/v1/query", {
    question,
    conversation_id: conversationId ?? null,
  });

export const askStream = async (
  question: string,
  conversationId?: string
): Promise<AskStreamResult> => {
  const res = await fetch(`${http.defaults.baseURL}/v1/query-stream`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      question,
      conversation_id: conversationId ?? null,
    }),
  });

  if (!res.ok) {
    throw new Error(`HTTP ${res.status}: ${await res.text()}`);
  }

  const reader = res.body!.getReader();
  const decoder = new TextDecoder();
  let answer = "";

  while (true) {
    const { value, done } = await reader.read();
    if (done) break;
    answer += decoder.decode(value, { stream: true });
  }

  return {
    answer,
    conversation_id: res.headers.get("x-conversation-id") || undefined,
    headers: res.headers,
  };
};

export const fetchHistory = (conversationId: string) =>
  http.get<{ question: string; answer: string }[]>(
    `/v1/history/${conversationId}`
  );
