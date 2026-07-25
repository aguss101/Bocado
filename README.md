<p align="center">
  <img src="Logo.png" alt="Bocado" width="140">
</p>

<h1 align="center">Bocado</h1>

<p align="center">
  Red social de recetas: un espacio para aprender a cocinar, compartir conocimiento, ahorrar en las compras y comer más sano.
</p>

<p align="center">
  <img alt="Platform" src="https://img.shields.io/badge/platform-Android-3DDC84?logo=android&logoColor=white">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.44.2-02569B?logo=flutter&logoColor=white">
  <img alt="Backend" src="https://img.shields.io/badge/Backend-Supabase-3ECF8E?logo=supabase&logoColor=white">
  <img alt="Min SDK" src="https://img.shields.io/badge/minSdk-26-informational">
  <a href="https://github.com/aguss101/Bocado/actions/workflows/build-apk.yml"><img alt="Build" src="https://github.com/aguss101/Bocado/actions/workflows/build-apk.yml/badge.svg"></a>
</p>

---

## ¿Qué es Bocado?

**Bocado** es una aplicación Android para compartir recetas de cocina con una comunidad, pensada para quienes quieren cocinar con criterio: cada receta muestra su información nutricional (calorías, macros), porciones, costo estimado y valoraciones de otros usuarios.

Funcionalidades principales:

- 📱 **Feed** de recetas de la comunidad, con búsqueda de recetas y usuarios.
- 📝 **Publicación y edición de recetas**: ingredientes, cantidades, instrucciones, foto, porciones y etiquetas.
- 🧮 **Cálculo nutricional automático** a partir de los ingredientes cargados (calorías, macronutrientes, costo).
- 💬 **Comentarios**, respuestas anidadas, **calificaciones (rating)** y **favoritos**.
- 👤 **Perfiles de usuario**, sistema de seguidores (*follow*) y edición de perfil (foto, banner, datos).
- 🔐 **Autenticación** con email/contraseña y **Google Sign-In**, verificación de correo y recuperación de contraseña.
- 🔗 **Deep links**: enlaces directos a recetas y perfiles mediante esquema personalizado (`bocado://`) y App Links (`https://links.bocado.tech/...`).
- 🎨 **Tema claro/oscuro** y **modo daltónico** (accesibilidad para distintos tipos de daltonismo).
- 💎 Pantalla de **tienda premium**.

## Arquitectura

Bocado combina dos mundos con el patrón *add-to-app* de Flutter:

```
Bocado/
├── Desarrollo/                     # Código fuente de la app
│   ├── app/                        # Host nativo Android (Java)
│   │   └── src/main/java/com/example/bocado/MainActivity.java
│   ├── flutter_module/             # Módulo Flutter con toda la UI y lógica de negocio
│   │   └── lib/
│   │       ├── screens/            # Pantallas (Feed, Login, Perfil, Recetas, etc.)
│   │       ├── services/           # Acceso a datos (Supabase), sesión, navegación
│   │       ├── models/             # Modelos de datos
│   │       ├── theme/              # Temas y modo daltónico
│   │       └── widgets/            # Componentes reutilizables
│   ├── gradle/, gradlew, build.gradle, settings.gradle
│   └── local.properties            # Credenciales locales (no versionado)
├── Procesos/                       # Documentación del proceso de desarrollo
│   ├── Proceso#01-Propuestas/      # Propuesta e informe inicial
│   ├── Proceso#02-Funcionalidades/ # Relevamiento de requerimientos
│   └── Proceso #03-DER/            # Diagrama entidad-relación (DBML) y esquema de base de datos
├── Consigna.pdf                    # Consigna del trabajo práctico
├── Presentacion.pptx / Video presentacion.mp4
└── .github/workflows/build-apk.yml # CI: build y publicación del APK
```

- **App nativa Android** (`app/`): actúa como *host*, gestiona el splash screen, permisos, deep links/App Links y embebe el módulo Flutter como pantalla principal.
- **Módulo Flutter** (`flutter_module/`): contiene toda la interfaz y lógica de la aplicación.
- **Backend**: [Supabase](https://supabase.com/) (PostgreSQL + API REST) para datos, autenticación y almacenamiento de imágenes. El esquema completo de la base de datos está documentado en [`Procesos/Proceso #03-DER/DER.dbml`](<Procesos/Proceso #03-DER/DER.dbml>).

## Tecnologías

| Capa | Tecnología |
|---|---|
| App nativa | Android (Java), Gradle, Material Components |
| UI / lógica de negocio | Flutter / Dart |
| Backend | Supabase (PostgreSQL, Auth, Storage) |
| Autenticación | Email/contraseña + Google Sign-In |
| CI/CD | GitHub Actions |

Paquetes Flutter destacados: `google_sign_in`, `shared_preferences`, `image_picker`, `flutter_image_compress`, `cached_network_image`, `share_plus`, `google_fonts`.

## Requisitos previos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.44.2 (canal *stable*)
- JDK 21
- Android SDK (compileSdk 36, NDK 28.2.13676358) — vía Android Studio o `sdkmanager`
- Un proyecto de [Supabase](https://supabase.com/) con las tablas necesarias

## Puesta en marcha

1. **Cloná el repositorio**

   ```bash
   git clone https://github.com/aguss101/Bocado.git
   cd Bocado/Desarrollo
   ```

2. **Configurá las credenciales locales**

   Creá `Desarrollo/local.properties` (no se versiona) con el SDK de Android y tus credenciales de Supabase:

   ```properties
   sdk.dir=/ruta/a/tu/Android/sdk
   supabase.url=https://TU-PROYECTO.supabase.co
   supabase.api=TU_SUPABASE_ANON_KEY
   ```

3. **Instalá las dependencias del módulo Flutter**

   ```bash
   cd flutter_module
   flutter pub get
   cd ..
   ```

4. **Compilá y ejecutá**

   ```bash
   # Debug, con un dispositivo/emulador conectado
   ./gradlew installDebug

   # Generar un APK de release
   ./gradlew assembleRelease
   ```

   El APK queda en `Desarrollo/app/build/outputs/apk/`.

## Integración continua

El workflow [`build-apk.yml`](.github/workflows/build-apk.yml) se dispara en cada push a `main`:

1. Configura Java 21 y Flutter 3.44.2.
2. Genera `local.properties` con los secrets del repositorio (`SUPABASE_URL`, `SUPABASE_KEY`) y restaura el keystore de firma.
3. Compila el APK de release (`assembleRelease`) versionado con el número de corrida de GitHub Actions.
4. Publica el APK y un `version.json` en un repositorio de GitHub Pages, habilitando la descarga y el chequeo de actualizaciones desde la propia app.

## Documentación del proyecto

En la carpeta [`Procesos/`](Procesos) se encuentra la documentación generada durante el desarrollo:

- **Proceso #01 – Propuestas**: propuesta inicial e informe del equipo.
- **Proceso #02 – Funcionalidades**: relevamiento de requerimientos.
- **Proceso #03 – DER**: modelo de datos (diagrama entidad-relación en DBML + imagen).

También se incluyen la consigna del trabajo práctico ([`Consigna.pdf`](Consigna.pdf)) y el material de presentación final ([`Presentacion.pptx`](Presentacion.pptx), [`Video presentacion.mp4`](<Video presentacion.mp4>)).

## Equipo

Proyecto desarrollado por el **Equipo 8** como TESIS para la finalizacion de la Tecnicatura Universitaria en Programación.

## Licencia

Este proyecto no cuenta con una licencia pública definida. Todos los derechos reservados por sus autores.
