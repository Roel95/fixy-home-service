# Crear Bucket 'images' en Supabase

## Opción 1: Crear desde la Interfaz Web (Recomendado)

1. Ve a [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Selecciona tu proyecto
3. Ve al menú **Storage** (en el panel lateral izquierdo)
4. Haz clic en **New bucket**
5. Nombre del bucket: `images`
6. Marca la casilla **Public bucket** (para que las imágenes sean accesibles públicamente)
7. Haz clic en **Create bucket**

## Opción 2: Crear desde SQL Editor

Ve al **SQL Editor** de Supabase y ejecuta:

```sql
-- Crear el bucket 'images' si no existe
insert into storage.buckets (id, name, public)
select 'images', 'images', true
where not exists (
  select 1 from storage.buckets where id = 'images'
);
```

## Configurar Políticas de Acceso (IMPORTANTE)

Después de crear el bucket, debes configurar las políticas de acceso para permitir subir archivos:

### Política 1: Permitir subir archivos a usuarios autenticados

```sql
-- Permitir a usuarios autenticados subir archivos al bucket 'images'
create policy "Allow authenticated uploads"
on storage.objects
for insert
with check (
  bucket_id = 'images' 
  and auth.role() = 'authenticated'
);
```

### Política 2: Permitir leer archivos públicamente

```sql
-- Permitir que cualquiera vea los archivos (público)
create policy "Allow public read"
on storage.objects
for select
using (
  bucket_id = 'images'
);
```

## Verificar Configuración

1. Ve a **Storage** → **images** en tu dashboard
2. Deberías ver la carpeta vacía lista para recibir archivos
3. La URL base será: `https://[TU_PROYECTO].supabase.co/storage/v1/object/public/images/`

## Nota para el Desarrollo

Si estás en desarrollo local y no puedes acceder a Supabase, puedes:

1. Continuar sin imágenes (las categorías se guardan sin imagen)
2. Usar URLs de imágenes externas en el campo imageUrl
3. Configurar el bucket más tarde cuando tengas acceso
