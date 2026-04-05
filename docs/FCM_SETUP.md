# Configuración de Push Notifications (FCM) - Fixy Home Service

## Resumen de Implementación

Se ha implementado Firebase Cloud Messaging (FCM) para notificaciones push en tiempo real:

### 1. Dependencias Agregadas (pubspec.yaml)
```yaml
firebase_core: ^3.0.0
firebase_messaging: ^15.0.0
flutter_local_notifications: ^17.0.0
```

### 2. Servicio FCM Creado (lib/services/fcm_service.dart)
- Inicialización de Firebase y FCM
- Manejo de notificaciones en foreground, background y cuando la app está cerrada
- Guardado automático del token FCM en Supabase
- Manejo de navegación basado en el tipo de notificación

### 3. Permisos Android Configurados (AndroidManifest.xml)
- Permisos de notificación
- Servicio de Firebase Cloud Messaging
- Configuración de icono y color por defecto

## Configuración Requerida en Supabase

### Paso 1: Agregar campo fcm_token a user_profiles

Ejecutar en SQL Editor de Supabase:

```sql
-- Agregar columna fcm_token a user_profiles
ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- Crear índice para búsquedas rápidas
CREATE INDEX IF NOT EXISTS idx_user_profiles_fcm_token 
ON user_profiles(fcm_token) 
WHERE fcm_token IS NOT NULL;
```

### Paso 2: Crear Edge Function para enviar FCM

1. Instalar Supabase CLI si no lo tienes:
```bash
npm install -g supabase
```

2. Inicializar Supabase en tu proyecto:
```bash
supabase login
supabase init
```

3. Crear la Edge Function:
```bash
supabase functions new send-fcm-notification
```

4. Reemplazar el contenido de `supabase/functions/send-fcm-notification/index.ts`:

```typescript
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

const FIREBASE_SERVER_KEY = Deno.env.get('FIREBASE_SERVER_KEY')

serve(async (req) => {
  try {
    const { userId, title, body, data, type } = await req.json()

    if (!userId || !title || !body) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Obtener el FCM token del usuario desde Supabase
    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
    
    const userResponse = await fetch(
      `${supabaseUrl}/rest/v1/user_profiles?id=eq.${userId}&select=fcm_token`,
      {
        headers: {
          'Authorization': `Bearer ${supabaseServiceKey}`,
          'apikey': supabaseServiceKey,
        },
      }
    )

    const users = await userResponse.json()
    
    if (!users || users.length === 0 || !users[0].fcm_token) {
      return new Response(
        JSON.stringify({ error: 'User not found or no FCM token' }),
        { status: 404, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const fcmToken = users[0].fcm_token

    // Enviar notificación a través de FCM HTTP API
    const fcmResponse = await fetch('https://fcm.googleapis.com/fcm/send', {
      method: 'POST',
      headers: {
        'Authorization': `key=${FIREBASE_SERVER_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        to: fcmToken,
        notification: {
          title: title,
          body: body,
          sound: 'default',
          badge: '1',
        },
        data: {
          ...data,
          type: type || 'general',
        },
        priority: 'high',
      }),
    })

    const fcmResult = await fcmResponse.json()

    if (fcmResponse.ok) {
      return new Response(
        JSON.stringify({ 
          success: true, 
          messageId: fcmResult.message_id,
          result: fcmResult 
        }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      )
    } else {
      return new Response(
        JSON.stringify({ 
          error: 'FCM send failed', 
          details: fcmResult 
        }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
```

### Paso 3: Configurar Variables de Entorno

En el dashboard de Supabase, ir a Project Settings > Functions:

1. Agregar `FIREBASE_SERVER_KEY`: Obtener de Firebase Console > Project Settings > Cloud Messaging > Server Key
2. Agregar `SUPABASE_URL`: URL de tu proyecto Supabase
3. Agregar `SUPABASE_SERVICE_ROLE_KEY`: Service Role Key de Supabase

### Paso 4: Desplegar la Edge Function

```bash
supabase functions deploy send-fcm-notification
```

### Paso 5: Crear Trigger en Supabase para Notificaciones Automáticas

Ejecutar en SQL Editor:

```sql
-- Función para enviar notificación cuando se crea una reserva
CREATE OR REPLACE FUNCTION notify_provider_on_reservation()
RETURNS TRIGGER AS $$
DECLARE
  provider_fcm_token TEXT;
  service_name TEXT;
  customer_name TEXT;
BEGIN
  -- Obtener el FCM token del proveedor
  SELECT fcm_token INTO provider_fcm_token
  FROM user_profiles
  WHERE id = NEW.provider_id;

  -- Obtener nombre del servicio
  SELECT name INTO service_name
  FROM services
  WHERE id = NEW.service_id;

  -- Obtener nombre del cliente
  SELECT full_name INTO customer_name
  FROM user_profiles
  WHERE id = NEW.user_id;

  -- Solo enviar si el proveedor tiene FCM token
  IF provider_fcm_token IS NOT NULL THEN
    -- Llamar a la Edge Function
    PERFORM
      net.http_post(
        url := 'https://your-project-ref.supabase.co/functions/v1/send-fcm-notification',
        headers := jsonb_build_object(
          'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key'),
          'Content-Type', 'application/json'
        ),
        body := jsonb_build_object(
          'userId', NEW.provider_id,
          'title', '📅 Nueva Reserva',
          'body', customer_name || ' ha reservado ' || service_name,
          'type', 'provider_reservation',
          'data', jsonb_build_object(
            'reservation_id', NEW.id,
            'service_name', service_name,
            'customer_name', customer_name
          )
        )
      );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Crear trigger para reservas
DROP TRIGGER IF EXISTS reservation_created_notification ON reservations;
CREATE TRIGGER reservation_created_notification
  AFTER INSERT ON reservations
  FOR EACH ROW
  EXECUTE FUNCTION notify_provider_on_reservation();
```

## Uso desde Flutter

El servicio FCM ya está configurado en `lib/services/fcm_service.dart` y se inicializa automáticamente en `main.dart`.

### Para enviar notificación manualmente desde Flutter:

```dart
import 'package:fixy_home_service/services/notification_service.dart';

// Enviar notificación al crear una orden
await NotificationService.createNotification(
  userId: user.id,
  title: '🛒 Nueva Orden',
  body: 'Tu orden ha sido creada exitosamente',
  type: 'order',
  data: {'order_id': orderId},
);
```

### Tipos de Notificaciones Soportadas:

- `order` - Notificaciones de órdenes
- `reservation` - Notificaciones de reservas para clientes
- `provider_reservation` - Notificaciones de reservas para proveedores
- `order_status` - Actualizaciones de estado de orden

## Prueba

1. Ejecutar la app en un dispositivo físico (el emulador puede tener problemas con FCM)
2. Crear una reserva u orden
3. Verificar que llegue la notificación push incluso con la app cerrada

## Troubleshooting

### No llegan las notificaciones:
1. Verificar que el dispositivo tenga conexión a internet
2. Verificar que el token FCM se guardó en Supabase (campo `fcm_token` en `user_profiles`)
3. Revisar logs de Flutter: `flutter run` para ver mensajes de debug
4. Verificar que las variables de entorno de la Edge Function estén configuradas
5. Verificar que el Server Key de Firebase sea correcto

### Errores de permisos:
- En Android 13+ (API 33+), los permisos de notificación deben solicitarse en tiempo de ejecución
- El servicio FCM ya maneja esto automáticamente

## Archivos Modificados/Creados

1. `pubspec.yaml` - Agregadas dependencias Firebase
2. `lib/main.dart` - Inicialización de Firebase y FCM
3. `lib/services/fcm_service.dart` - Nuevo servicio de FCM
4. `android/app/src/main/AndroidManifest.xml` - Permisos y configuración FCM
5. `supabase/functions/send-fcm-notification/index.ts` - Edge Function (crear manualmente)

## Próximos Pasos

1. Configurar Firebase Console con tu proyecto
2. Agregar el campo `fcm_token` a la tabla `user_profiles`
3. Crear y desplegar la Edge Function
4. Probar las notificaciones en un dispositivo físico
