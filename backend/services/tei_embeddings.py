# pip install httpx langchain
from typing import List, Optional
import httpx
from langchain.embeddings.base import Embeddings


class TEIEmbeddings(Embeddings):
    def __init__(
        self,
        base_url: str,
        api_key: Optional[str] = None,
        timeout: float = 60.0,
        batch_size: int = 32,
    ):
        headers = {"Content-Type": "application/json"}
        if api_key:
            headers["Authorization"] = f"Bearer {api_key}"
        self.client = httpx.Client(base_url=base_url, headers=headers, timeout=timeout)
        # Send to TEI in smaller requests to avoid 413s
        self.batch_size = max(1, batch_size)

    def _post_embed(self, batch: List[str]) -> List[List[float]]:
        r = self.client.post("/embed", json={"inputs": batch})
        r.raise_for_status()
        payload = r.json()
        # Support multiple common response shapes
        if isinstance(payload, dict):
            if "embeddings" in payload:
                return payload["embeddings"]
            if "data" in payload and isinstance(payload["data"], list):
                items = payload["data"]
                if items and isinstance(items[0], dict):
                    if "embedding" in items[0]:
                        return [it["embedding"] for it in items]
                    if "vector" in items[0]:
                        return [it["vector"] for it in items]
        elif isinstance(payload, list):
            if payload and isinstance(payload[0], dict):
                if "embedding" in payload[0]:
                    return [it["embedding"] for it in payload]
                if "vector" in payload[0]:
                    return [it["vector"] for it in payload]
            # Assume it's already a list of vectors
            return payload
        raise ValueError("Unexpected TEI embeddings response format")

    def embed_documents(self, texts: List[str]) -> List[List[float]]:
        # Batch requests to avoid exceeding server request size limits
        if not texts:
            return []
        all_embeddings: List[List[float]] = []
        for i in range(0, len(texts), self.batch_size):
            batch = texts[i : i + self.batch_size]
            embeddings = self._post_embed(batch)
            all_embeddings.extend(embeddings)
        return all_embeddings

    def embed_query(self, text: str) -> List[float]:
        return self.embed_documents([text])[0]
