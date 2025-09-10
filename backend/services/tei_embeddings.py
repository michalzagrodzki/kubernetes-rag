# pip install httpx langchain
from typing import List
import httpx
from langchain.embeddings.base import Embeddings

class TEIEmbeddings(Embeddings):
    def __init__(self, base_url: str, api_key: str | None = None, timeout: float = 60.0):
        headers = {"Content-Type": "application/json"}
        if api_key:
            headers["Authorization"] = f"Bearer {api_key}"
        self.client = httpx.Client(base_url=base_url, headers=headers, timeout=timeout)

    def embed_documents(self, texts: List[str]) -> List[List[float]]:
        r = self.client.post("/embed", json={"inputs": texts})
        r.raise_for_status()
        payload = r.json()
        # TEI returns {"embeddings":[...]} (see docs)
        return payload["embeddings"]

    def embed_query(self, text: str) -> List[float]:
        return self.embed_documents([text])[0]
