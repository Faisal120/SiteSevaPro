import axios from "axios";

const BACKEND_URL = (process.env.REACT_APP_BACKEND_URL || "http://127.0.0.1:8000").replace(/\/$/, "");
export const API_BASE = `${BACKEND_URL}/api`;

export const api = axios.create({ baseURL: API_BASE });

api.interceptors.request.use((config) => {
  const token = localStorage.getItem("access_token");
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

api.interceptors.response.use(
  (r) => r,
  (err) => {
    if (err?.response?.status === 428 && window.location.pathname !== "/activate-account") {
      // A pending password setup cannot use an old/stale dashboard session.
      // The activation UI asks for the identifier again and keeps its OTP token
      // in component memory only.
      localStorage.removeItem("access_token");
      localStorage.removeItem("user");
      window.location.href = "/activate-account";
      return Promise.reject(err);
    }
    if (err?.response?.status === 401 && window.location.pathname.startsWith("/app")) {
      localStorage.removeItem("access_token");
      localStorage.removeItem("user");
      window.location.href = "/login";
    }
    return Promise.reject(err);
  }
);

export async function uploadToCloudinary(file, folder = "siteseva/uploads") {
  const isVideo = file.type.startsWith("video/");
  const resource_type = isVideo ? "video" : "image";
  const { data: sig } = await api.get(`/cloudinary/signature`, { params: { resource_type, folder } });
  const form = new FormData();
  form.append("file", file);
  form.append("api_key", sig.api_key);
  form.append("timestamp", sig.timestamp);
  form.append("signature", sig.signature);
  form.append("folder", sig.folder);
  const res = await fetch(`https://api.cloudinary.com/v1_1/${sig.cloud_name}/${resource_type}/upload`, {
    method: "POST",
    body: form,
  });
  if (!res.ok) throw new Error("Upload failed");
  const json = await res.json();
  return { url: json.secure_url, public_id: json.public_id, type: resource_type };
}
