import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Términos y Condiciones'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Términos y Condiciones de FixyHomeService',
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
              '1. Aceptación de los Términos',
              'Al acceder y utilizar la aplicación FixyHomeService, usted acepta estar sujeto a estos Términos y Condiciones. Si no está de acuerdo con alguna parte de estos términos, no debe utilizar nuestra aplicación.',
            ),
            _buildSection(
              context,
              '2. Descripción del Servicio',
              'FixyHomeService es una plataforma digital que conecta a usuarios con proveedores de servicios para el hogar. Nuestra plataforma facilita:\n\n'
                  '• Búsqueda y contratación de servicios profesionales para el hogar\n'
                  '• Análisis de problemas domésticos mediante inteligencia artificial\n'
                  '• Compra de productos relacionados con el hogar\n'
                  '• Sistema de pagos seguros\n'
                  '• Gestión de reservaciones y seguimiento de servicios',
            ),
            _buildSection(
              context,
              '3. Registro de Usuario',
              'Para utilizar nuestros servicios, debe:\n\n'
                  '• Proporcionar información precisa y completa durante el registro\n'
                  '• Mantener la seguridad de su contraseña\n'
                  '• Notificarnos inmediatamente de cualquier uso no autorizado de su cuenta\n'
                  '• Ser mayor de 18 años o tener el consentimiento de un tutor legal\n'
                  '• No compartir su cuenta con terceros',
            ),
            _buildSection(
              context,
              '4. Uso de la Plataforma',
              'Los usuarios se comprometen a:\n\n'
                  '• Utilizar la plataforma solo para fines legales\n'
                  '• No publicar contenido ofensivo, difamatorio o ilegal\n'
                  '• Respetar los derechos de propiedad intelectual\n'
                  '• No intentar acceder a áreas restringidas del sistema\n'
                  '• Proporcionar información veraz en todas las transacciones',
            ),
            _buildSection(
              context,
              '5. Proveedores de Servicios',
              'Los proveedores de servicios deben:\n\n'
                  '• Estar debidamente registrados y verificados\n'
                  '• Cumplir con todas las regulaciones locales aplicables\n'
                  '• Proporcionar servicios de calidad según lo acordado\n'
                  '• Mantener las certificaciones y licencias necesarias\n'
                  '• Respetar los horarios y términos acordados con los clientes',
            ),
            _buildSection(
              context,
              '6. Pagos y Facturación',
              '• Todos los precios están en Soles peruanos (S/)\n'
                  '• Los pagos se procesan a través de métodos seguros\n'
                  '• Se requiere un adelanto para confirmar la reservación\n'
                  '• Las cancelaciones están sujetas a la política de cancelación\n'
                  '• FixyHomeService actúa como intermediario en las transacciones\n'
                  '• Se emitirán comprobantes electrónicos de pago',
            ),
            _buildSection(
              context,
              '7. Cancelaciones y Reembolsos',
              'Política de cancelación:\n\n'
                  '• Cancelación con 24+ horas de anticipación: reembolso completo\n'
                  '• Cancelación con 12-24 horas: reembolso del 50%\n'
                  '• Cancelación con menos de 12 horas: sin reembolso\n'
                  '• Los proveedores que cancelen sin justificación serán penalizados\n'
                  '• Los reembolsos se procesan en 5-10 días hábiles',
            ),
            _buildSection(
              context,
              '8. Responsabilidades y Limitaciones',
              'FixyHomeService no se hace responsable de:\n\n'
                  '• La calidad del servicio prestado por los proveedores\n'
                  '• Daños o pérdidas resultantes de los servicios contratados\n'
                  '• Disputas entre usuarios y proveedores\n'
                  '• Interrupciones del servicio por causas de fuerza mayor\n\n'
                  'Nuestra responsabilidad se limita a facilitar la conexión entre usuarios y proveedores.',
            ),
            _buildSection(
              context,
              '9. Privacidad y Protección de Datos',
              'Nos comprometemos a:\n\n'
                  '• Proteger sus datos personales según nuestra Política de Privacidad\n'
                  '• Cumplir con la Ley de Protección de Datos Personales del Perú\n'
                  '• No compartir información sin su consentimiento\n'
                  '• Implementar medidas de seguridad apropiadas\n'
                  '• Permitir el acceso, rectificación y eliminación de sus datos',
            ),
            _buildSection(
              context,
              '10. Propiedad Intelectual',
              'Todo el contenido de la aplicación, incluyendo:\n\n'
                  '• Logotipos, marcas y diseños\n'
                  '• Código fuente y funcionalidad\n'
                  '• Textos, imágenes y multimedia\n'
                  '• Algoritmos de IA y análisis\n\n'
                  'Son propiedad exclusiva de FixyHomeService y están protegidos por las leyes de propiedad intelectual.',
            ),
            _buildSection(
              context,
              '11. Sistema de Calificaciones y Reseñas',
              '• Los usuarios pueden calificar y reseñar servicios recibidos\n'
                  '• Las reseñas deben ser honestas y basadas en experiencias reales\n'
                  '• Nos reservamos el derecho de eliminar reseñas inapropiadas\n'
                  '• Las calificaciones afectan la visibilidad de los proveedores\n'
                  '• No se permiten calificaciones falsas o manipuladas',
            ),
            _buildSection(
              context,
              '12. Programa de Recompensas',
              '• Los puntos de recompensa son intransferibles\n'
                  '• Los puntos pueden caducar según las condiciones del programa\n'
                  '• FixyHomeService puede modificar el programa en cualquier momento\n'
                  '• Los puntos no tienen valor monetario\n'
                  '• Se requiere cuenta activa para mantener los puntos',
            ),
            _buildSection(
              context,
              '13. Modificaciones del Servicio',
              'FixyHomeService se reserva el derecho de:\n\n'
                  '• Modificar o discontinuar servicios en cualquier momento\n'
                  '• Cambiar estos términos con aviso previo\n'
                  '• Suspender o terminar cuentas que violen los términos\n'
                  '• Actualizar precios y tarifas con notificación anticipada',
            ),
            _buildSection(
              context,
              '14. Ley Aplicable y Jurisdicción',
              'Estos términos se rigen por las leyes de la República del Perú. Cualquier disputa será resuelta en los tribunales de Lima, Perú.',
            ),
            _buildSection(
              context,
              '15. Contacto',
              'Para preguntas sobre estos términos, contáctenos:\n\n'
                  '• Email: soporte@fixyhomeservice.com\n'
                  '• Teléfono: +51 1 234 5678\n'
                  '• Dirección: Av. Principal 123, Lima, Perú\n'
                  '• Horario: Lunes a Viernes, 9:00 AM - 6:00 PM',
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 32),
                  const SizedBox(height: 12),
                  Text(
                    'Acuerdo Importante',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Al continuar usando FixyHomeService, confirmas que has leído, entendido y aceptado estos Términos y Condiciones en su totalidad.',
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
