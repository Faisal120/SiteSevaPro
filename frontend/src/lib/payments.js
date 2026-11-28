// CRA replaces REACT_APP_* values at build time. Payments stay off unless a
// deliberate production build sets this exact flag to true.
export const PAYMENTS_ENABLED = process.env.REACT_APP_PAYMENTS_ENABLED === "true";
