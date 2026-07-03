import { api } from "@/lib/api";

export async function get(url, params = {}) {
  const { data } = await api.get(url, { params });
  return data;
}

export async function post(url, body = {}) {
  const { data } = await api.post(url, body);
  return data;
}

export async function put(url, body = {}) {
  const { data } = await api.put(url, body);
  return data;
}

export async function remove(url) {
  const { data } = await api.delete(url);
  return data;
}