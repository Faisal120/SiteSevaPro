export function Door({ x, y }) {
    return (
        <>
            <line
                x1={x}
                y1={y}
                x2={x + 25}
                y2={y}
                stroke="black"
                strokeWidth="2"
            />

            <path
                d={`
                    M ${x}
                    ${y}
                    A 25 25 0 0 1
                    ${x + 25}
                    ${y - 25}
                `}
                fill="none"
                stroke="black"
            />
        </>
    );
}

export function Window({ x, y, width = 40 }) {
    return (
        <>
            <line
                x1={x}
                y1={y}
                x2={x + width}
                y2={y}
                stroke="#3b82f6"
                strokeWidth="5"
            />
        </>
    );
}

export function Bed({ x, y }) {
    return (
        <>
            <rect
                x={x}
                y={y}
                width="60"
                height="80"
                fill="none"
                stroke="black"
            />

            <rect
                x={x + 5}
                y={y + 5}
                width="50"
                height="15"
                fill="none"
                stroke="black"
            />
        </>
    );
}

export function Sofa({ x, y }) {
    return (
        <>
            <rect
                x={x}
                y={y}
                width="70"
                height="30"
                fill="none"
                stroke="black"
            />
        </>
    );
}