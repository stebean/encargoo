# En-cargoo 📦

Sistema de gestión de pedidos y encargos diseñado para negocios pequeños o medianos.

## 🚀 Cómo empezar

Este proyecto utiliza **Flutter** y **Supabase**. Para ejecutarlo localmente y conectar con tu propio proyecto de Supabase, sigue estos pasos:

### 1. Requisitos previos
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (>= 3.2.0)
- Una cuenta en [Supabase](https://supabase.com/)

### 2. Configuración de Supabase
1. Crea un nuevo proyecto en Supabase.
2. Ve a **Settings > API** para obtener tu:
   - `Project URL`
   - `Anon Key`
3. Ejecuta los scripts SQL que se encuentran en la carpeta del proyecto (si los hay) para configurar las tablas necesarias.

### 3. Configuración local
1. Clona este repositorio.
2. Copia el archivo de ejemplo para crear tu archivo de variables de entorno:
   ```bash
   cp .env.example .env
   ```
3. Edita el archivo `.env` y rellena con tus credenciales de Supabase:
   ```env
   SUPABASE_URL=tu_url_aqui
   SUPABASE_ANON_KEY=tu_anon_key_aqui
   ```

### 4. Ejecución
Instala las dependencias y corre la aplicación:
```bash
flutter pub get
flutter run
```

## Estructura del Proyecto
- `lib/core`: Configuración global, temas, rutas y constantes.
- `lib/features`: Funcionalidades divididas por módulos.
- `lib/shared`: Widgets y modelos compartidos.

## 📄 Licencia
Este proyecto está bajo la **Licencia MIT**. Para más detalles, consulta el archivo [LICENSE](LICENSE).
