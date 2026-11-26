import React from "react";

/**
 * Accessible six-digit OTP control. The value remains owned by the parent so
 * it can be cleared immediately after verification or when the page unmounts.
 */
export default function OtpCodeInput({ value, onChange, disabled = false }) {
  const refs = React.useRef([]);
  const digits = Array.from({ length: 6 }, (_, index) => value[index] || "");

  const commit = (nextValue, focusIndex) => {
    onChange(nextValue.replace(/\D/g, "").slice(0, 6));
    if (typeof focusIndex === "number") {
      window.requestAnimationFrame(() => refs.current[focusIndex]?.focus());
    }
  };

  const enterDigits = (index, rawValue) => {
    const incoming = rawValue.replace(/\D/g, "").slice(0, 6);
    if (!incoming) return;
    const next = `${value.slice(0, index)}${incoming}`.slice(0, 6);
    const lastFilledIndex = Math.min(index + incoming.length - 1, 5);
    commit(next, Math.min(lastFilledIndex + 1, 5));
  };

  const handleKeyDown = (event, index) => {
    if (event.key === "Backspace" && digits[index]) {
      event.preventDefault();
      commit(value.slice(0, index), Math.max(index - 1, 0));
      return;
    }
    if (event.key === "Backspace" && index > 0) {
      event.preventDefault();
      commit(value.slice(0, index - 1), index - 1);
    }
  };

  const handlePaste = (event, index) => {
    const pasted = event.clipboardData?.getData("text") || "";
    if (!pasted) return;
    event.preventDefault();
    enterDigits(index, pasted);
  };

  return (
    <div className="flex justify-between gap-2" role="group" aria-label="Six digit verification code">
      {digits.map((digit, index) => (
        <input
          key={index}
          ref={(element) => { refs.current[index] = element; }}
          aria-label={`Verification code digit ${index + 1}`}
          autoComplete={index === 0 ? "one-time-code" : "off"}
          className="h-12 min-w-0 flex-1 rounded-lg border border-gray-300 bg-white text-center font-mono text-xl font-bold text-gray-900 outline-none transition focus:border-[#3B82F6] focus:ring-2 focus:ring-[#3B82F6]/20 disabled:cursor-not-allowed disabled:opacity-60 dark:border-white/10 dark:bg-[#171717] dark:text-white"
          disabled={disabled}
          inputMode="numeric"
          maxLength={6}
          onChange={(event) => enterDigits(index, event.target.value)}
          onKeyDown={(event) => handleKeyDown(event, index)}
          onPaste={(event) => handlePaste(event, index)}
          pattern="[0-9]*"
          type="text"
          value={digit}
        />
      ))}
    </div>
  );
}
