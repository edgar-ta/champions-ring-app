import type { MemberSummary } from "../models/member-summary";
import type { VisitorSummary } from "../models/visitor-summary";

export interface MemberRepository {
  /** Alumnos activos en el sistema (sin `deletionDate`), del más reciente al más antiguo. */
  listMembers(): Promise<MemberSummary[]>;

  /**
   * Personas en `clients` que no son alumnos: quienes pagaron visitas y quienes solo tomaron su
   * clase muestra, con la fecha y hora de cada visita. `memberUids` son los alumnos a excluir.
   */
  listVisitors(memberUids: ReadonlySet<string>): Promise<VisitorSummary[]>;
}
