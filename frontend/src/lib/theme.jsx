import React from "react";

const KEY = "ss_theme";

export function ThemeProvider({ children }) {
  React.useEffect(() => {
    const t = localStorage.getItem(KEY) || "light";
    if (t === "dark") document.documentElement.classList.add("ss-dark");
    else document.documentElement.classList.remove("ss-dark");
  }, []);
  return children;
}

export function useTheme() {
  const [theme, setTheme] = React.useState(() => localStorage.getItem(KEY) || "light");
  const toggle = () => {
    const next = theme === "dark" ? "light" : "dark";
    setTheme(next);
    localStorage.setItem(KEY, next);
    if (next === "dark") document.documentElement.classList.add("ss-dark");
    else document.documentElement.classList.remove("ss-dark");
  };
  return { theme, toggle };
}
