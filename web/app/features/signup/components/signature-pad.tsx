"use client";

import { useEffect, useImperativeHandle, useRef, useState, type Ref } from "react";

export interface SignaturePadHandle {
  /** PNG de la firma, o null si no se ha dibujado nada. */
  toDataUrl(): string | null;
  clear(): void;
}

/** Área para firmar con el mouse, el dedo o un lápiz. */
export function SignaturePad({ ref, onChange, label }: { ref: Ref<SignaturePadHandle>; onChange: (hasSignature: boolean) => void; label: string }) {
  const canvas = useRef<HTMLCanvasElement>(null);
  const drawing = useRef(false);
  const [hasStrokes, setHasStrokes] = useState(false);

  useEffect(() => {
    const element = canvas.current;
    if (!element) return;
    // Resolución real del dispositivo para que el trazo no se vea borroso.
    const ratio = window.devicePixelRatio || 1;
    element.width = element.offsetWidth * ratio;
    element.height = element.offsetHeight * ratio;
    const context = element.getContext("2d")!;
    context.scale(ratio, ratio);
    context.lineWidth = 2.4;
    context.lineCap = "round";
    context.lineJoin = "round";
    context.strokeStyle = "#111827";
  }, []);

  function point(event: React.PointerEvent<HTMLCanvasElement>) {
    const rect = event.currentTarget.getBoundingClientRect();
    return { x: event.clientX - rect.left, y: event.clientY - rect.top };
  }

  function start(event: React.PointerEvent<HTMLCanvasElement>) {
    event.currentTarget.setPointerCapture(event.pointerId);
    drawing.current = true;
    const { x, y } = point(event);
    const context = event.currentTarget.getContext("2d")!;
    context.beginPath();
    context.moveTo(x, y);
    context.lineTo(x + 0.1, y + 0.1);
    context.stroke();
  }

  function move(event: React.PointerEvent<HTMLCanvasElement>) {
    if (!drawing.current) return;
    const { x, y } = point(event);
    const context = event.currentTarget.getContext("2d")!;
    context.lineTo(x, y);
    context.stroke();
    if (!hasStrokes) { setHasStrokes(true); onChange(true); }
  }

  function end() { drawing.current = false; }

  useImperativeHandle(ref, () => ({
    toDataUrl: () => (hasStrokes && canvas.current ? canvas.current.toDataURL("image/png") : null),
    clear() {
      const element = canvas.current;
      if (!element) return;
      element.getContext("2d")!.clearRect(0, 0, element.width, element.height);
      setHasStrokes(false);
      onChange(false);
    },
  }), [hasStrokes, onChange]);

  return <canvas ref={canvas} className="signature-pad" aria-label={label} role="img"
    onPointerDown={start} onPointerMove={move} onPointerUp={end} onPointerCancel={end} onPointerLeave={end}/>;
}
