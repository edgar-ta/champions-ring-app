import {onRequest} from "firebase-functions/v2/https";
import {REGION} from "../core/utils/constants.js";

const RETURN_MESSAGES: Record<string, { title: string; body: string }> = {
  success: {
    title: "¡Gracias por tu pago!",
    body:
      "Estamos confirmando tu pago. Tu membresía se activará en " +
      "unos momentos. Ya puedes volver a la app Champions Ring.",
  },
  pending: {
    title: "Tu pago está pendiente",
    body:
      "Cuando Mercado Pago lo confirme, activaremos tu membresía. " +
      "Ya puedes volver a la app Champions Ring.",
  },
  failure: {
    title: "No se completó el pago",
    body:
      "No se realizó ningún cargo. Vuelve a la app Champions Ring " +
      "para intentarlo de nuevo.",
  },
  subscription: {
    title: "Cobro automático",
    body:
      "Cuando Mercado Pago confirme la autorización de tu tarjeta, " +
      "verás el cobro automático activo en la app Champions Ring.",
  },
};

// invoker "public": la abre el navegador del cliente al volver de
// Mercado Pago; sin esto Cloud Run responde 403.
export const paymentReturn = onRequest(
  {region: REGION, invoker: "public"},
  (req, res) => {
    const key = req.path.replace(/^\/+|\/+$/g, "");
    const message = RETURN_MESSAGES[key] ?? RETURN_MESSAGES.pending;

    // No se imprime ningún dato de la URL: solo textos fijos.
    res
      .status(200)
      .set("Cache-Control", "no-store")
      .set(
        "Content-Security-Policy",
        "default-src 'none'; style-src 'unsafe-inline'",
      )
      .type("html")
      .send(
        "<!doctype html><html lang=\"es\"><head>" +
          "<meta charset=\"utf-8\">" +
          "<meta name=\"viewport\" content=\"width=device-width," +
          "initial-scale=1\">" +
          "<title>Champions Ring</title>" +
          "<style>body{font-family:system-ui,sans-serif;display:flex;" +
          "min-height:100vh;margin:0;align-items:center;" +
          "justify-content:center;background:#fff;color:#1a1a1a}" +
          "main{max-width:360px;padding:24px;text-align:center}" +
          "h1{color:#ea3a3f;font-size:24px}p{line-height:1.5}</style>" +
          "</head><body><main>" +
          `<h1>${message.title}</h1><p>${message.body}</p>` +
          "</main></body></html>",
      );
  },
);
