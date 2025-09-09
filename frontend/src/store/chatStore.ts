/* eslint-disable @typescript-eslint/no-explicit-any */
import { create } from "zustand";
import { devtools } from "zustand/middleware";
import { askStream, fetchHistory } from "../services/api";
import { v4 as uuidv4 } from "uuid";

export interface Message {
  id: string;
  role: "user" | "assistant";
  text: string;
  pending?: boolean;
  animate?: boolean;
}

interface ChatState {
  conversationId?: string;
  messages: Message[];
  loading: boolean;
  error: string | null;

  initConversation: () => void;
  sendMessage: (text: string) => Promise<string | undefined>;
  loadHistory: (cid: string) => Promise<void>;
  clearChat: () => void;
}

export const useChatStore = create<ChatState>()(
  devtools((set, get) => ({
    conversationId: undefined,
    messages: [],
    loading: false,
    error: null,

    initConversation: () =>
      set({ conversationId: undefined, messages: [], error: null }),

    async sendMessage(text: string) {
      const userMsg: Message = { id: uuidv4(), role: "user", text };
      set((s) => ({ messages: [...s.messages, userMsg] }));

      let cid = get().conversationId;
      if (!cid) {
        cid = uuidv4();
        set({ conversationId: cid });
      }

      const placeholderId = uuidv4();
      const pendingMsg: Message = {
        id: placeholderId,
        role: "assistant",
        text: "",
        pending: true,
      };
      set((s) => ({
        messages: [...s.messages, pendingMsg],
        loading: true,
        error: null,
      }));

      try {
        const { answer, conversation_id } = await askStream(text, cid);
        const finalCID = conversation_id ?? cid;
        if (finalCID !== cid) set({ conversationId: finalCID });

        /* 5. replace placeholder with real answer */
        set((s) => ({
          messages: s.messages.map((m) =>
            m.id === placeholderId
              ? { ...m, text: answer, pending: false, animate: true }
              : m
          ),
          loading: false,
        }));

        return finalCID;
      } catch (err: any) {
        set({
          loading: false,
          error:
            err.message || "Failed to fetch answer. Please try again later.",
        });
        return undefined;
      }
    },

    async loadHistory(cid) {
      set({ loading: true, error: null });
      try {
        const { data } = await fetchHistory(cid);
        const history: Message[] = data.flatMap((h: any) => [
          { id: uuidv4(), role: "user", text: h.question, animate: false },
          { id: uuidv4(), role: "assistant", text: h.answer, animate: false },
        ]);
        set({ conversationId: cid, messages: history, loading: false });
      } catch (err: any) {
        set({
          loading: false,
          error:
            err.response?.data?.detail ||
            err.message ||
            "Failed loading history",
        });
      }
    },

    clearChat: () =>
      set({ conversationId: undefined, messages: [], error: null }),
  }))
);
