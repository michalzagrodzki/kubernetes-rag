from typing import List, Dict
from uuid import UUID as PyUUID
from sqlmodel import select
from services.db import get_session
from services.models import ChatHistory

def get_history(conversation_id: str) -> List[Dict[str, str]]:
    """Fetch all prior turns for this conversation, ordered by timestamp."""
    with get_session() as session:
        stmt = (
            select(ChatHistory.question, ChatHistory.answer)
            .where(ChatHistory.conversation_id == PyUUID(conversation_id))
            .order_by(ChatHistory.created_at)
        )
        result = session.exec(stmt)
        rows = result.all()
    return [{"question": q, "answer": a} for q, a in rows]

def append_history(conversation_id: str, question: str, answer: str) -> None:
    """Insert the latest Q&A turn into chat_history."""
    with get_session() as session:
        rec = ChatHistory(
            conversation_id=PyUUID(conversation_id),
            question=question,
            answer=answer,
        )
        session.add(rec)
        session.commit()
