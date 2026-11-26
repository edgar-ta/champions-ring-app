import type { Receptionist } from "../models/receptionist-model";

export interface ReceptionistRepository {
  /** Inicia sesión y devuelve el perfil de `receptionists/{uid}`. */
  login(email: string, password: string, remember: boolean): Promise<Receptionist>;

  logout(): Promise<void>;

  /** Envía el correo de Firebase para restablecer la contraseña de esa cuenta. */
  sendPasswordReset(email: string): Promise<void>;

  /** Notifica el perfil del recepcionista con sesión, o null. Devuelve la función para dejar de escuchar. */
  observeSession(onChange: (receptionist: Receptionist | null) => void, onError: (error: unknown) => void): () => void;
}
