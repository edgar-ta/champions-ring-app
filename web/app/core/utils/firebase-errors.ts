import { FirebaseError } from "firebase/app";

/** Mensaje para el recepcionista a partir de un error de Firestore. `action` completa la frase: "No se pudo …". */
export function firestoreErrorMessage(error: unknown, action: string): string {
  if (error instanceof FirebaseError) {
    switch (error.code) {
      case "permission-denied": return `No tienes permiso para ${action}. Revisa las reglas de Firestore.`;
      case "unavailable":
      case "deadline-exceeded": return `No se pudo ${action} por un problema de conexión. Inténtalo de nuevo.`;
      case "failed-precondition": return `No se pudo ${action}: falta un índice de Firestore. Revisa la consola del navegador.`;
    }
  }
  return `No se pudo ${action}. Inténtalo de nuevo.`;
}
