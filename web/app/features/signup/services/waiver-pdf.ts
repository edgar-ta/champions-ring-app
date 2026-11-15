import { isMinor, type MemberRecord, type PersonalData, type WaiverSignature } from "../models/registration";

/** Mismo texto que app/lib/features/inscription/models/liability_waiver.dart. */
export const WAIVER_TITLE = "CARTA DE LIBERACIÓN DE RESPONSABILIDAD";
export const WAIVER_PARAGRAPHS = [
  "Yo, por mi propio derecho, en mi calidad de alumno mayor de edad, o en representación del menor inscrito, declaro estar consciente de que la práctica del boxeo y entrenamiento físico de alta intensidad conlleva riesgos inherentes.",
  "Por lo anterior, deslindo a CHAMPIONS RING, sus entrenadores y personal de cualquier responsabilidad civil, médica o penal derivada de lesiones ocurridas durante el uso adecuado de las instalaciones y el desarrollo de las actividades deportivas.",
  "Declaro que mi estado de salud (o el del menor) me permite realizar actividad física, que la información proporcionada es verdadera y que me comprometo a respetar el reglamento interno del gimnasio.",
];

const LOGO_URL = "/images/logo-champions-ring.png";
const two = (value: number) => String(value).padStart(2, "0");
const formatDate = (date: Date) => `${two(date.getDate())}/${two(date.getMonth() + 1)}/${date.getFullYear()}`;
const formatDateTime = (date: Date) => `${formatDate(date)} a las ${two(date.getHours())}:${two(date.getMinutes())} hrs`;

/** Quien firma: el alumno, o su tutor si es menor de edad. */
export function waiverSigner(personal: PersonalData, record: MemberRecord): { name: string; role: string } {
  return isMinor(record.birthDate)
    ? { name: record.guardianName ?? "", role: "Firma del padre, madre o tutor" }
    : { name: `${personal.name} ${personal.lastName}`.trim(), role: "Firma del alumno" };
}

async function loadLogo(): Promise<string | null> {
  try {
    const blob = await (await fetch(LOGO_URL)).blob();
    return await new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = () => resolve(String(reader.result));
      reader.onerror = () => reject(reader.error);
      reader.readAsDataURL(blob);
    });
  } catch { return null; }
}

/** Genera la carta responsiva firmada en PDF, con el mismo contenido que la app. */
export async function buildWaiverPdf(personal: PersonalData, record: MemberRecord, signature: WaiverSignature): Promise<Blob> {
  const { jsPDF } = await import("jspdf");
  const pdf = new jsPDF({ unit: "pt", format: "letter" });
  const margin = 48;
  const width = pdf.internal.pageSize.getWidth() - margin * 2;
  let y = margin;

  const logo = await loadLogo();
  if (logo) { pdf.addImage(logo, "PNG", pdf.internal.pageSize.getWidth() / 2 - 35, y, 70, 70); y += 86; }

  pdf.setFont("helvetica", "bold").setFontSize(14);
  pdf.text(WAIVER_TITLE, pdf.internal.pageSize.getWidth() / 2, y, { align: "center" });
  y += 32;

  const minor = isMinor(record.birthDate);
  const fields: [string, string][] = [
    ["Alumno", `${personal.name} ${personal.lastName}`.trim()],
    ["Fecha de nacimiento", formatDate(record.birthDate)],
    ["Correo electrónico", personal.email],
    ["Teléfono", record.phone],
    ...(minor ? [["Padre, madre o tutor", record.guardianName ?? ""], ["Parentesco", record.guardianRelationship ?? ""], ["Teléfono del tutor", record.guardianPhone ?? ""]] as [string, string][] : []),
  ];
  pdf.setFontSize(11);
  for (const [label, value] of fields) {
    pdf.setFont("helvetica", "bold").text(`${label}: `, margin, y);
    pdf.setFont("helvetica", "normal").text(value, margin + pdf.getTextWidth(`${label}: `), y);
    y += 16;
  }
  y += 12;

  for (const paragraph of WAIVER_PARAGRAPHS) {
    const lines: string[] = pdf.splitTextToSize(paragraph, width);
    pdf.text(lines, margin, y, { align: "justify", maxWidth: width, lineHeightFactor: 1.35 });
    y += lines.length * 11 * 1.35 + 10;
  }

  y += 14;
  pdf.setFontSize(10).text(`Firmado electrónicamente el ${formatDateTime(signature.signedAt)}.`, margin, y);
  y += 20;

  const center = pdf.internal.pageSize.getWidth() / 2;
  pdf.addImage(signature.signatureDataUrl, "PNG", center - 120, y, 240, 90);
  y += 94;
  pdf.setLineWidth(1).line(center - 120, y, center + 120, y);
  const signer = waiverSigner(personal, record);
  pdf.setFont("helvetica", "bold").setFontSize(11).text(signer.name, center, y + 16, { align: "center" });
  pdf.setFont("helvetica", "normal").setFontSize(10).text(signer.role, center, y + 30, { align: "center" });

  return pdf.output("blob");
}
