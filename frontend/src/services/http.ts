import axios from "axios";

export const http = axios.create({
  baseURL: import.meta.env.VITE_API_URL ?? "http://localhost:8000",
  timeout: 30_000,
});

http.interceptors.response.use(
  (res) => res,
  (err) => {
    return Promise.reject(err);
  }
);
