# CineVault · Supabase + Vercel

Sin configurar nada, la app funciona en **modo local**: las cuentas y los datos viven solo en tu navegador (sirve para probar).

## 1. Supabase
1. Crea un proyecto en https://supabase.com.
2. SQL Editor → pega y ejecuta `supabase.sql`.
3. Authentication → Providers → Email: activado. Si quieres entrar sin confirmar el correo mientras pruebas, desactiva «Confirm email».
4. Authentication → URL Configuration: pon como *Site URL* la URL de Vercel (y `http://localhost:3000` si pruebas en local). Es necesaria para el enlace de «¿Olvidaste tu contraseña?».
5. Project Settings → API: copia **Project URL** y la clave **anon public**.
6. En `index.html`, busca `CV_CONFIG` y pégalas:
   ```js
   const CV_CONFIG={SUPABASE_URL:'https://xxxx.supabase.co',SUPABASE_ANON_KEY:'eyJ...'};
   ```
   La anon key es pública por diseño; la protección real son las políticas RLS del SQL. **Nunca** pongas la `service_role` key en el HTML.

## 2. Vercel
- Con la CLI: `npm i -g vercel` y, dentro de esta carpeta, `vercel --prod`.
- O sube la carpeta a un repositorio de GitHub e impórtalo en https://vercel.com/new (framework: *Other*, sin build).

## Cómo funciona
- Registro: correo + contraseña + nombre de usuario (único, 3–24 caracteres).
- Inicio de sesión: correo + contraseña. La sesión se mantiene al recargar.
- Cada usuario tiene sus datos separados; con Supabase se sincronizan en la tabla `cinevault_data` (la clave de TMDB se queda solo en cada dispositivo).
- Los datos de ejemplo ya no se cargan: cada cuenta nueva empieza vacía. Los datos que tuvieras guardados antes en este navegador se asignan a la primera cuenta que inicie sesión.
