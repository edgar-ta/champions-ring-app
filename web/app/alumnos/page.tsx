import type { Metadata } from "next";
import { StudentsScreen } from "./students-screen";

export const metadata: Metadata = { title: "Alumnos | Champions Ring" };

export default function StudentsPage() {
  return <StudentsScreen />;
}
