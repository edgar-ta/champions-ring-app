export const IMAGE_TYPES = ["image/jpeg", "image/png", "image/webp"];
const MB = 1024 * 1024;

/** Mismos límites que la app (UserStorageService). */
export const FILE_LIMITS = { photo: 5 * MB, ineFront: 5 * MB, ineBack: 5 * MB, curp: 20 * MB } as const;
export type DocumentField = keyof typeof FILE_LIMITS;

export const DOCUMENT_LABELS: Record<DocumentField, string> = {
  photo: "Foto de perfil",
  ineFront: "INE (frente)",
  ineBack: "INE (reverso)",
  curp: "CURP del menor",
};

/** Mensaje de error si el archivo no es una imagen permitida o es demasiado grande; null si es válido. */
export function imageError(field: DocumentField, file: File): string | null {
  if (!IMAGE_TYPES.includes(file.type)) return `${DOCUMENT_LABELS[field]}: usa una imagen JPG, PNG o WEBP.`;
  if (file.size > FILE_LIMITS[field]) return `${DOCUMENT_LABELS[field]}: el archivo supera ${FILE_LIMITS[field] / MB} MB.`;
  return null;
}
