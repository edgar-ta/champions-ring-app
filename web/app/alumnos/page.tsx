import type { Metadata } from "next";
import { ReceptionistGate } from "../features/authentication/components/receptionist-session";
import { StudentsScreen } from "./students-screen";

export const metadata: Metadata = { title: "Alumnos | Champions Ring" };

export default function StudentsPage() {
  return <ReceptionistGate><StudentsScreen /></ReceptionistGate>;
}
