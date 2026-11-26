// @docs[ docs/dev-team/modelo-de-datos-en-firebase.md v22.1.0 ]
import type { CoreReceptionist } from "@/src/core/models/core_receptionist";

export interface ReceptionistRepository {
  /** Inicia sesión y devuelve el perfil de `receptionists/{uid}`. */
  login(email: string, password: string, remember: boolean): Promise<CoreReceptionist>;

  logout(): Promise<void>;

  /** Envía el correo de Firebase para restablecer la contraseña de esa cuenta. */
  sendPasswordReset(email: string): Promise<void>;

  /** Notifica el perfil del recepcionista con sesión, o null. Devuelve la función para dejar de escuchar. */
  observeSession(onChange: (receptionist: CoreReceptionist | null) => void, onError: (error: unknown) => void): () => void;
}
