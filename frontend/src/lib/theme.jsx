import React from "react";

const KEY = "ss_theme";
const ThemeContext = React.createContext({ theme: "dark", toggle: () => {} });

function getInitialTheme() {
  if (typeof window === "undefined") return "dark";
  const saved = window.localStorage.getItem(KEY);
  return saved === "light" || saved === "dark" ? saved : "dark";
}

export function ThemeProvider({ children }) {
  const [theme, setTheme] = React.useState(getInitialTheme);

  React.useEffect(() => {
    window.localStorage.setItem(KEY, theme);
    document.documentElement.classList.toggle("ss-dark", theme === "dark");
    document.documentElement.style.colorScheme = theme;
  }, [theme]);

  const value = React.useMemo(() => ({
    theme,
    toggle: () => setTheme((current) => current === "dark" ? "light" : "dark"),
    setTheme,
  }), [theme]);

  return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>;
}

export function useTheme() {
  return React.useContext(ThemeContext);
}
