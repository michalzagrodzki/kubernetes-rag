import axios from "axios";

// Resolve API base URL with robust defaults:
// - Prefer VITE_API_URL when provided (e.g., separate API host)
// - Otherwise, use current origin so Nginx can proxy /v1 to backend in-cluster
const resolvedBaseURL = ((): string => {
  const envUrl = (import.meta as any)?.env?.VITE_API_URL as string | undefined;
  if (envUrl && envUrl.trim() !== "") {
    return envUrl.replace(/\/$/, "");
  }
  if (typeof window !== "undefined" && window.location?.origin) {
    return window.location.origin;
  }
  // Final fallback for non-browser contexts
  return "";
})();

export const http = axios.create({
  baseURL: resolvedBaseURL,
  timeout: 30_000,
});

http.interceptors.response.use(
  (res) => res,
  (err) => {
    return Promise.reject(err);
  }
);
