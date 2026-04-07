import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Política de Privacidad'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Política de Privacidad de FixyHomeService',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Última actualización: ${DateTime.now().toString().split(' ')[0]}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '1. Introducción',
              'En FixyHomeService, valoramos y respetamos su privacidad. Esta Política de Privacidad explica cómo recopilamos, usamos, protegemos y compartimos su información personal cuando utiliza nuestra aplicación.',
            ),
            _buildSection(
              context,
              '2. Información que Recopilamos',
              'Recopilamos los siguientes tipos de información:\n\n'
                  '• Información de cuenta: nombre, correo electrónico, teléfono\n'
                  '• Información de ubicación: dirección, ciudad, código postal\n'
                  '• Información de pago: métodos de pago (encriptados)\n'
                  '• Información de uso: servicios contratados, historial de reservaciones\n'
                  '• Información de dispositivo: tipo de dispositivo, sistema operativo\n'
                  '• Imágenes y análisis: fotos de problemas domésticos (con su consentimiento)\n'
                  '• Audio: grabaciones de voz para análisis de IA (opcional)',
            ),
            _buildSection(
              context,
              '3. Cómo Usamos su Información',
              'Utilizamos su información para:\n\n'
                  '• Procesar y gestionar sus reservaciones de servicios\n'
                  '• Facilitar pagos y emitir comprobantes\n'
                  '• Proporcionar análisis de IA sobre problemas del hogar\n'
                  '• Mejorar nuestros servicios y experiencia de usuario\n'
                  '• Enviar notificaciones sobre el estado de sus servicios\n'
                  '• Comunicaciones de soporte al cliente\n'
                  '• Prevenir fraudes y garantizar la seguridad\n'
                  '• Cumplir con obligaciones legales',
            ),
            _buildSection(
              context,
              '4. Base Legal para el Procesamiento',
              'Procesamos sus datos personales bajo las siguientes bases legales:\n\n'
                  '• Ejecución de contrato: para proveer los servicios solicitados\n'
                  '• Consentimiento: para funciones opcionales como análisis de IA\n'
                  '• Intereses legítimos: para mejorar nuestros servicios\n'
                  '• Cumplimiento legal: para cumplir con regulaciones aplicables',
            ),
            _buildSection(
              context,
              '5. Compartir Información',
              'Compartimos su información solo cuando es necesario:\n\n'
                  '• Con proveedores de servicios para completar reservaciones\n'
                  '• Con procesadores de pago para transacciones seguras\n'
                  '• Con servicios de análisis de IA (DeepSeek) para análisis de problemas\n'
                  '• Con autoridades legales cuando sea requerido por ley\n\n'
                  'Nunca vendemos su información personal a terceros.',
            ),
            _buildSection(
              context,
              '6. Seguridad de Datos',
              'Implementamos medidas de seguridad robustas:\n\n'
                  '• Encriptación de datos en tránsito y en reposo\n'
                  '• Autenticación segura con Supabase\n'
                  '• Políticas de acceso restringido (Row Level Security)\n'
                  '• Monitoreo continuo de seguridad\n'
                  '• Copias de seguridad regulares\n'
                  '• Auditorías de seguridad periódicas',
            ),
            _buildSection(
              context,
              '7. Sus Derechos',
              'Usted tiene derecho a:\n\n'
                  '• Acceder a sus datos personales\n'
                  '• Rectificar información inexacta\n'
                  '• Solicitar la eliminación de sus datos\n'
                  '• Oponerse al procesamiento de sus datos\n'
                  '• Solicitar la portabilidad de datos\n'
                  '• Retirar su consentimiento en cualquier momento\n'
                  '• Presentar una queja ante la autoridad de protección de datos',
            ),
            _buildSection(
              context,
              '8. Retención de Datos',
              'Conservamos sus datos personales:\n\n'
                  '• Mientras su cuenta esté activa\n'
                  '• Durante el tiempo necesario para proveer servicios\n'
                  '• Según lo requieran obligaciones legales (generalmente 7 años para registros financieros)\n'
                  '• Datos de marketing: hasta que retire su consentimiento\n\n'
                  'Después de este período, eliminamos o anonimizamos sus datos.',
            ),
            _buildSection(
              context,
              '9. Cookies y Tecnologías Similares',
              'Utilizamos tecnologías de seguimiento para:\n\n'
                  '• Mantener su sesión activa\n'
                  '• Recordar sus preferencias\n'
                  '• Analizar el uso de la aplicación\n'
                  '• Mejorar el rendimiento\n\n'
                  'Puede gestionar las cookies desde la configuración de la aplicación.',
            ),
            _buildSection(
              context,
              '10. Servicios de Terceros',
              'Nuestra aplicación integra servicios de terceros:\n\n'
                  '• Supabase (almacenamiento y autenticación)\n'
                  '• DeepSeek (análisis de IA)\n'
                  '• Procesadores de pago\n'
                  '• Servicios de mapas y ubicación\n\n'
                  'Estos servicios tienen sus propias políticas de privacidad.',
            ),
            _buildSection(
              context,
              '11. Transferencias Internacionales',
              'Sus datos pueden ser transferidos y procesados en:\n\n'
                  '• Servidores ubicados fuera del Perú\n'
                  '• Centros de datos de nuestros proveedores de servicios\n\n'
                  'Garantizamos que estas transferencias cumplan con estándares de protección adecuados.',
            ),
            _buildSection(
              context,
              '12. Privacidad de Menores',
              'Nuestros servicios están dirigidos a mayores de 18 años. No recopilamos intencionalmente información de menores sin el consentimiento de sus tutores legales.',
            ),
            _buildSection(
              context,
              '13. Análisis de IA y Procesamiento de Imágenes',
              'Cuando utiliza nuestro servicio de análisis de IA:\n\n'
                  '• Las imágenes se envían a DeepSeek para análisis\n'
                  '• Los datos se procesan de forma segura y encriptada\n'
                  '• No almacenamos imágenes sin su consentimiento\n'
                  '• Los resultados del análisis se guardan en su historial\n'
                  '• Puede eliminar análisis previos en cualquier momento',
            ),
            _buildSection(
              context,
              '14. Notificaciones y Comunicaciones',
              'Enviamos notificaciones sobre:\n\n'
                  '• Estado de sus reservaciones\n'
                  '• Confirmaciones de pago\n'
                  '• Actualizaciones de servicio\n'
                  '• Ofertas y promociones (opcional)\n\n'
                  'Puede gestionar sus preferencias de notificación en Configuración.',
            ),
            _buildSection(
              context,
              '15. Cambios a esta Política',
              'Podemos actualizar esta Política de Privacidad periódicamente. Le notificaremos sobre cambios significativos mediante:\n\n'
                  '• Notificación en la aplicación\n'
                  '• Correo electrónico\n'
                  '• Aviso en nuestra página principal',
            ),
            _buildSection(
              context,
              '16. Contacto',
              'Para consultas sobre privacidad, contáctenos:\n\n'
                  '• Email: privacidad@fixyhomeservice.com\n'
                  '• Teléfono: +51 1 234 5678\n'
                  '• Dirección: Av. Principal 123, Lima, Perú\n'
                  '• Oficial de Protección de Datos: dpo@fixyhomeservice.com',
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.security, color: Colors.green, size: 32),
                  const SizedBox(height: 12),
                  Text(
                    'Su Privacidad es Importante',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nos comprometemos a proteger su información personal y respetar sus derechos de privacidad en todo momento.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                ),
          ),
        ],
      ),
    );
  }
}
