This is a [Next.js](https://nextjs.org) project bootstrapped with [`create-next-app`](https://nextjs.org/docs/app/api-reference/cli/create-next-app).

## Getting Started

First, run the development server:

```bash
npm run dev
# or
yarn dev
# or
pnpm dev
# or
bun dev
```

Open [http://localhost:3000](http://localhost:3000) with your browser to see the result.

You can start editing the page by modifying `app/page.tsx`. The page auto-updates as you edit the file.

This project uses [`next/font`](https://nextjs.org/docs/app/building-your-application/optimizing/fonts) to automatically optimize and load [Geist](https://vercel.com/font), a new font family for Vercel.

## Learn More

To learn more about Next.js, take a look at the following resources:

- [Next.js Documentation](https://nextjs.org/docs) - learn about Next.js features and API.
- [Learn Next.js](https://nextjs.org/learn) - an interactive Next.js tutorial.

You can check out [the Next.js GitHub repository](https://github.com/vercel/next.js) - your feedback and contributions are welcome!

## Deploy on Vercel

The easiest way to deploy your Next.js app is to use the [Vercel Platform](https://vercel.com/new?utm_medium=default-template&filter=next.js&utm_source=create-next-app&utm_campaign=create-next-app-readme) from the creators of Next.js.

Check out our [Next.js deployment documentation](https://nextjs.org/docs/app/building-your-application/deploying) for more details.

## Inicio de sesión de recepcionistas

La web autentica por correo y contraseña con Firebase Authentication y consulta
`users/{uid}` en la base de Firestore `default` (sin paréntesis). La cuenta debe existir en Authentication, tener el
mismo `uid` en su documento, `type: "receptionist"` y `deletion_date` ausente o
`null`. No se crean cuentas ni documentos durante el inicio de sesión.

Habilita Email/Password en Firebase Authentication y autoriza el dominio de la
web. Las reglas de Firestore deben permitir al usuario autenticado leer su propio
perfil. Los permisos sobre otros datos deben validar también el rol y la baja en
las reglas de Firestore; la validación de la interfaz no sustituye esas reglas.
No se modifican ni despliegan reglas desde esta implementación.

“Recordarme” conserva la sesión al cerrar el navegador; sin marcarlo, la sesión
se limita a la pestaña. Al recargar se vuelve a consultar el perfil. Al entrar se
muestra el nombre del recepcionista y una opción para cerrar sesión, como pantalla
inicial hasta que exista el panel de recepción.

Referencia: [persistencia de Firebase Auth](https://firebase.google.com/docs/auth/web/auth-state-persistence).
