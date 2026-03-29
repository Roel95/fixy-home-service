import 'package:flutter/material.dart';
import 'package:fixy_home_service/models/ai_conversation_model.dart';
import 'package:fixy_home_service/models/service_model.dart';
import 'package:fixy_home_service/models/product_model.dart';
import 'package:fixy_home_service/models/profile_models.dart';
import 'package:fixy_home_service/services/order_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AIAssistantService {
  /// Procesar mensaje del usuario y generar respuesta de IA
  static Future<Map<String, dynamic>> processMessage({
    required String userMessage,
    required List<AIConversationMessage> conversationHistory,
    List<ServiceModel>? availableServices,
    List<ProductModel>? availableProducts,
    UserProfile? userProfile,
    List<OrderModel>? userOrders,
    Function(String)? onFetchServices,
    Function(String)? onFetchProducts,
  }) async {
    try {
      debugPrint('🤖 [AI_ASSISTANT] Procesando mensaje: $userMessage');

      // 🔍 BÚSQUEDA INTELIGENTE: Detectar si el usuario busca algo específico
      List<dynamic>? searchResults;
      String? searchQuery;
      final lowerMessage = userMessage.toLowerCase();

      // Lista de keywords de productos comunes
      final productKeywords = [
        'cemento',
        'pintura',
        'arena',
        'ladrillo',
        'cal',
        'yeso',
        'fierro',
        'acero',
        'tubo',
        'cable',
        'alambre',
        'clavo',
        'tornillo',
        'pegamento',
        'silicona',
        'brocha',
        'rodillo',
        'lija',
        'thinner',
        'barniz',
        'esmalte',
        'herramienta',
        'martillo',
        'destornillador',
        'llave',
        'alicate',
        'sierra',
        'taladro',
        'disco',
        'broca',
        'nivel',
        'cinta',
        'metro',
      ];

      // Extraer keywords de búsqueda (productos)
      if (lowerMessage.contains('quiero') ||
          lowerMessage.contains('necesito') ||
          lowerMessage.contains('busco') ||
          lowerMessage.contains('dame') ||
          lowerMessage.contains('muestra') ||
          lowerMessage.contains('ver') ||
          lowerMessage.contains('hay') ||
          lowerMessage.contains('tienes') ||
          lowerMessage.contains('tienen') ||
          lowerMessage.contains('comprar')) {
        // 🎯 Buscar keywords de productos en el mensaje
        for (final keyword in productKeywords) {
          if (lowerMessage.contains(keyword)) {
            searchQuery = keyword;
            debugPrint('🔍 Detectado producto: "$searchQuery" en mensaje');
            break;
          }
        }

        // Si no encontró keyword, intentar extraer la primera palabra significativa
        if (searchQuery == null) {
          final words = userMessage
              .toLowerCase()
              .replaceAll(RegExp(r'[^\wáéíóúñ\s]'), '')
              .split(' ')
              .where((w) =>
                  w.length > 3 &&
                  ![
                    'quiero',
                    'necesito',
                    'busco',
                    'dame',
                    'muestra',
                    'para',
                    'casa',
                    'metro',
                    'centimetro',
                    'comprar',
                    'bolsas'
                  ].contains(w) &&
                  !RegExp(r'^\d+$').hasMatch(w)) // Ignorar números puros
              .toList();

          if (words.isNotEmpty) {
            searchQuery = words.first;
            debugPrint('🔍 Extraída palabra clave: "$searchQuery"');
          }
        }

        if (searchQuery != null && searchQuery.isNotEmpty) {
          debugPrint('🔍 Buscando productos con keyword: "$searchQuery"');
          searchResults =
              await _searchProductsByKeyword(searchQuery, availableProducts);

          // 📝 Log para debugging
          if (searchResults.isNotEmpty) {
            debugPrint('✅ Encontrados ${searchResults.length} productos');
          } else {
            debugPrint('⚠️ No se encontraron productos para "$searchQuery"');
          }
        }
      }

      // Construir contexto del sistema con resultados de búsqueda, datos del perfil y órdenes
      final systemContext = _buildSystemContext(
        availableServices,
        availableProducts,
        userProfile: userProfile,
        userOrders: userOrders,
        searchResults: searchResults,
        searchQuery: searchQuery,
      );

      // Construir historial de mensajes
      final messages = [
        {'role': 'system', 'content': systemContext},
        ...conversationHistory.map((msg) => {
              'role': msg.role,
              'content': msg.content,
            }),
        {'role': 'user', 'content': userMessage},
      ];

      // 🚀 Llamar a Supabase Edge Function (evita problemas de CORS en web)
      final supabase = Supabase.instance.client;
      debugPrint('🚀 [AI_ASSISTANT] Invocando Edge Function ai-chat...');

      final response = await supabase.functions.invoke(
        'ai-chat',
        body: {
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 500,
          'user_id': supabase.auth.currentUser?.id,
        },
      );

      debugPrint('📡 [AI_ASSISTANT] Response status: ${response.status}');
      debugPrint(
          '📡 [AI_ASSISTANT] Response data type: ${response.data?.runtimeType}');
      debugPrint('📡 [AI_ASSISTANT] Response data: ${response.data}');

      if (response.status == 200 && response.data != null) {
        final data = response.data;

        // ✅ VALIDACIÓN ROBUSTA: Verificar estructura de respuesta
        debugPrint('📦 [AI_ASSISTANT] Response data: $data');

        if (data == null || data is! Map) {
          debugPrint('❌ [AI_ASSISTANT] Response data is null or not a Map');
          return {
            'response':
                'Lo siento, hubo un error procesando la respuesta. Por favor intenta de nuevo.',
            'intent': {'type': 'unknown'},
            'success': false,
          };
        }

        if (!data.containsKey('choices') ||
            data['choices'] == null ||
            data['choices'] is! List ||
            (data['choices'] as List).isEmpty) {
          debugPrint(
              '❌ [AI_ASSISTANT] Invalid response structure - missing choices');
          debugPrint('❌ [AI_ASSISTANT] Full response: $data');
          return {
            'response':
                'Lo siento, la IA no pudo generar una respuesta. Verifica que la API key esté configurada correctamente.',
            'intent': {'type': 'unknown'},
            'success': false,
          };
        }

        final firstChoice = data['choices'][0];
        if (firstChoice == null ||
            !firstChoice.containsKey('message') ||
            firstChoice['message'] == null) {
          debugPrint(
              '❌ [AI_ASSISTANT] Invalid choice structure - missing message');
          return {
            'response':
                'Lo siento, hubo un error en la estructura de respuesta.',
            'intent': {'type': 'unknown'},
            'success': false,
          };
        }

        final message = firstChoice['message'];
        if (!message.containsKey('content') || message['content'] == null) {
          debugPrint(
              '❌ [AI_ASSISTANT] Invalid message structure - missing content');
          return {
            'response': 'Lo siento, hubo un error obteniendo el contenido.',
            'intent': {'type': 'unknown'},
            'success': false,
          };
        }

        final aiResponse = message['content'].toString().trim();
        debugPrint('✅ [AI_ASSISTANT] Respuesta COMPLETA: $aiResponse');
        debugPrint(
            '🔍 [AI_ASSISTANT] ¿Contiene ACTION?: ${aiResponse.contains('[ACTION:')}');

        // Analizar intención del usuario
        final intent = _analyzeIntent(userMessage, aiResponse);
        debugPrint('🎯 [AI_ASSISTANT] Intent detectado: ${intent['type']}');
        debugPrint('🎯 [AI_ASSISTANT] Datos del intent: $intent');

        // Obtener opciones visuales basadas en búsqueda o intención
        List<dynamic>? visualOptions;
        if (searchResults != null && searchResults.isNotEmpty) {
          // ✅ SIEMPRE mostrar resultados de búsqueda específica
          visualOptions = searchResults;
          debugPrint(
              '📦 Mostrando ${searchResults.length} resultados de búsqueda');
          // Forzar el intent para que muestre las tarjetas
          intent['type'] = 'show_search_results';
        } else if (intent['type'] == 'show_services' ||
            intent['type'] == 'show_search_results') {
          if (availableServices != null && availableServices.isNotEmpty) {
            visualOptions = availableServices.take(6).toList();
          }
        } else if (intent['type'] == 'show_products') {
          if (availableProducts != null && availableProducts.isNotEmpty) {
            visualOptions = availableProducts.take(8).toList();
          }
        }

        return {
          'response': aiResponse,
          'intent': intent,
          'visualOptions': visualOptions,
          'searchQuery': searchQuery,
          'success': true,
        };
      } else {
        debugPrint('❌ [AI_ASSISTANT] Error status: ${response.status}');
        debugPrint('❌ [AI_ASSISTANT] Error data: ${response.data}');

        // Mensaje de error más específico
        String errorMessage = 'Lo siento, hubo un error con el servicio de IA.';
        if (response.status == 500) {
          errorMessage =
              'Error del servidor. Verifica que la API key de DeepSeek esté configurada en Supabase.';
        } else if (response.status == 401 || response.status == 403) {
          errorMessage =
              'Error de autenticación. Verifica las credenciales de la API.';
        }

        return {
          'response': errorMessage,
          'intent': {'type': 'unknown'},
          'success': false,
        };
      }
    } catch (e) {
      debugPrint('💥 [AI_ASSISTANT] Exception: $e');
      return {
        'response':
            'Lo siento, no puedo procesar tu solicitud en este momento.',
        'intent': {'type': 'unknown'},
        'success': false,
      };
    }
  }

  /// Buscar productos por keyword
  static Future<List<ProductModel>> _searchProductsByKeyword(
    String query,
    List<ProductModel>? availableProducts,
  ) async {
    if (availableProducts == null || availableProducts.isEmpty) return [];

    final lowerQuery = query.toLowerCase().trim();
    final matches = <ProductModel>[];
    final partialMatches = <ProductModel>[];

    for (final product in availableProducts) {
      final name = product.name.toLowerCase();
      final desc = product.description.toLowerCase();
      final brand = product.brand.toLowerCase();

      // Match exacto en el nombre (prioridad alta)
      if (name.contains(lowerQuery)) {
        matches.add(product);
      }
      // Match en descripción o marca (prioridad media)
      else if (desc.contains(lowerQuery) || brand.contains(lowerQuery)) {
        partialMatches.add(product);
      }
    }

    // Combinar matches exactos primero, luego parciales
    final results = [...matches, ...partialMatches];

    // Retornar top 6 resultados
    return results.take(6).toList();
  }

  /// Construir contexto del sistema
  static String _buildSystemContext(
    List<ServiceModel>? services,
    List<ProductModel>? products, {
    UserProfile? userProfile,
    List<OrderModel>? userOrders,
    List<dynamic>? searchResults,
    String? searchQuery,
  }) {
    final servicesContext = services != null && services.isNotEmpty
        ? '\n\nServicios disponibles: ${services.take(5).map((s) => '${s.title} (${s.currency}${s.price}/${s.timeUnit})').join(', ')}'
        : '';

    // Si hay resultados de búsqueda específicos, mostrarlos en el contexto
    String productsContext = '';
    if (searchResults != null &&
        searchResults.isNotEmpty &&
        searchQuery != null) {
      final productList = searchResults
          .whereType<ProductModel>()
          .take(6)
          .map((p) =>
              '${p.name} (ID: ${p.id}, S/ ${p.price}, Stock: ${p.stock})')
          .join(', ');
      productsContext =
          '\n\n🔍 RESULTADOS DE BÚSQUEDA para "$searchQuery": $productList\n\n⚠️ IMPORTANTE: El usuario está buscando "$searchQuery". SOLO menciona los productos de arriba que sean relevantes.';
    } else if (products != null && products.isNotEmpty) {
      productsContext =
          '\n\nProductos disponibles: ${products.take(5).map((p) => '${p.name} (S/ ${p.price})').join(', ')}';
    }

    // 📋 DATOS DEL USUARIO: Información del perfil para autocompletar
    String userProfileContext = '';
    if (userProfile != null) {
      final hasAddress = userProfile.address.isNotEmpty;
      final hasPhone = userProfile.phone.isNotEmpty;

      debugPrint(
          '👤 [AI_ASSISTANT] Perfil usuario: address=${userProfile.address}, phone=${userProfile.phone}, hasAddress=$hasAddress, hasPhone=$hasPhone');

      if (hasAddress || hasPhone) {
        userProfileContext =
            '\n\n📋 DATOS DEL USUARIO REGISTRADOS (Tienes permiso para usar estos datos):';
        if (hasAddress) {
          userProfileContext +=
              '\n• Dirección guardada: ${userProfile.address}${userProfile.city.isNotEmpty ? ', ${userProfile.city}' : ''}';
        }
        if (hasPhone) {
          userProfileContext += '\n• Teléfono registrado: ${userProfile.phone}';
        }
        userProfileContext +=
            '\n\n📝 REGLA OBLIGATORIA: Cuando el usuario pregunte "¿tienes mi dirección?" o similar, DEBES responder "Sí, tengo tu dirección: [dirección del perfil]". NO digas que no tienes acceso por privacidad.';
        userProfileContext +=
            '\n📝 REGLA OBLIGATORIA: Si el usuario quiere hacer una reserva y ya tiene dirección registrada arriba, USA esa dirección automáticamente. Solo pregunta por fecha y hora.';
      }
    } else {
      debugPrint(
          '⚠️ [AI_ASSISTANT] userProfile es NULL - no hay datos del usuario');
    }

    // 📦 HISTORIAL DE COMPRAS: Información de órdenes previas
    String userOrdersContext = '';
    if (userOrders != null && userOrders.isNotEmpty) {
      final recentOrders = userOrders.take(3);
      userOrdersContext = '\n\n📦 HISTORIAL DE COMPRAS RECIENTES:';
      for (final order in recentOrders) {
        userOrdersContext +=
            '\n• Orden #${order.orderNumber} (${order.statusText}): ${order.totalItems} productos, S/ ${order.total.toStringAsFixed(2)}';
        if (order.items.isNotEmpty) {
          final itemNames =
              order.items.take(2).map((i) => i.productName).join(', ');
          userOrdersContext +=
              ' - $itemNames${order.items.length > 2 ? '...' : ''}';
        }
      }
      userOrdersContext +=
          '\n\n💡 REGLA: Si el usuario pregunta por productos similares o recomendaciones, puedes referirte a su historial de compras.';
    }

    return '''Eres un asistente virtual de una plataforma de servicios del hogar en Perú. Tu nombre es "Asistente IA".

Tu trabajo es ayudar a los usuarios a:
1. Analizar problemas del hogar (con o sin imagen) y recomendar soluciones
2. Reservar servicios (limpieza, fontanería, electricidad, etc.)
3. Comprar productos de la tienda
4. Responder preguntas sobre servicios y productos
5. Dar recomendaciones personalizadas

📋 DATOS DEL USUARIO:
Tienes acceso a los datos del perfil del usuario que se muestran arriba. Cuando el usuario pregunte por su información (dirección, teléfono, nombre), USA ESOS DATOS directamente. NO digas que no tienes acceso por privacidad - ya tienes los datos en el contexto.

Cuando el usuario envía una IMAGEN:
- La imagen se analiza automáticamente con IA de visión
- Recibirás un análisis detallado del problema
- Tu rol es explicar las soluciones de forma clara y recomendar productos/servicios relacionados

Cuando el usuario BUSCA UN PRODUCTO ESPECÍFICO (ej: "quiero cemento", "necesito pintura"):
- Revisa los "RESULTADOS DE BÚSQUEDA" arriba si existen
- Di cuántos productos encontraste (usa el número exacto de resultados)
- Menciona brevemente los 2 principales productos con nombre y precio
- Al final, di "También te pueden interesar otros productos similares para tu proyecto."
- Ejemplo: "¡Hola! Te ayudo con el cemento para tu casa. Encontré 2 opciones disponibles:\n\n- Cemento Portland (S/ 25.50)\n- Cemento Gris (S/ 23.00)\n\nTambién te pueden interesar otros productos similares para tu proyecto."

Cuando un usuario quiera reservar un servicio:
- Si es la PRIMERA VEZ que menciona reservar o si pregunta "¿qué servicios tienes?", responde que le mostrarás opciones e incluye [ACTION:SHOW_SERVICES|categoria]
- Si el usuario dice "Quiero reservar [nombre del servicio] (ID: xxx)", RECONOCE que ya seleccionó un servicio específico y NO incluyas [ACTION:SHOW_SERVICES]
- Si tienes la dirección del perfil del usuario en "📋 DATOS DEL USUARIO REGISTRADOS": Solo pregunta fecha y hora, USA esa dirección automáticamente
- Si NO tienes dirección en el perfil: Pregunta fecha, hora y dirección completa

🚨 REGLA ABSOLUTAMENTE CRÍTICA - CREACIÓN DE RESERVAS:
Cuando tengas TODA la información necesaria (service_id, fecha, hora, dirección), DEBES:
1. Responder con un mensaje amigable confirmando la reserva
2. INCLUIR OBLIGATORIAMENTE al final de tu respuesta: [ACTION:BOOK_SERVICE|service_id|YYYY-MM-DD|HH:MM|dirección]
3. Ejemplo: "¡Perfecto! Tu reserva de Limpieza Profunda está confirmada para mañana 30/03/2026 a las 15:00 en Av. Arequipa 123, Miraflores, Lima. [ACTION:BOOK_SERVICE|uuid-del-servicio|2026-03-30|15:00|Av. Arequipa 123, Miraflores, Lima]"

⚠️ SIN EXCEPCIONES: Si no incluyes el token [ACTION:BOOK_SERVICE|...], la reserva NO se creará en el sistema. Este token es OBLIGATORIO.

Cuando un usuario quiera comprar un producto (sin especificar cuál):
- Si pregunta "¿qué productos tienes?", incluye [ACTION:SHOW_PRODUCTS|categoria]
- Si el usuario dice "Quiero comprar [nombre del producto] (ID: xxx)", RECONOCE que ya seleccionó un producto y NO incluyas [ACTION:SHOW_PRODUCTS]
- Pregunta cuántos necesita (si no lo menciona)
- Una vez confirmado, incluye [ACTION:ADD_TO_CART|product_id|cantidad]

REGLA CRÍTICA: NO muestres tarjetas visuales genéricas si el usuario ya mencionó un (ID: xxx) o si ya vio opciones antes. Solo muestra tarjetas cuando el usuario pregunta por primera vez o busca algo específico.

Responde de forma amigable, clara y en español peruano. Sé conciso (máximo 3-4 líneas).$servicesContext$productsContext$userProfileContext$userOrdersContext

IMPORTANTE: Cuando tengas toda la información necesaria para una reserva o compra, incluye en tu respuesta:
- Para reservas: [ACTION:BOOK_SERVICE|service_id|date|time|address]
- Para compras: [ACTION:ADD_TO_CART|product_id|quantity]
- Para ver más servicios: [ACTION:SHOW_SERVICES|category]
- Para ver productos genéricos: [ACTION:SHOW_PRODUCTS|category]''';
  }

  /// Analizar intención del usuario
  static Map<String, dynamic> _analyzeIntent(
      String userMessage, String aiResponse) {
    final lowerMessage = userMessage.toLowerCase();
    final lowerResponse = aiResponse.toLowerCase();

    debugPrint('🔍 [_analyzeIntent] Analizando respuesta AI...');
    debugPrint(
        '🔍 [_analyzeIntent] ¿Contiene [ACTION:?: ${aiResponse.contains('[ACTION:')}');

    // Detectar acciones en la respuesta de IA
    if (aiResponse.contains('[ACTION:')) {
      final actionRegex = RegExp(r'\[ACTION:([^\]]+)\]');
      final match = actionRegex.firstMatch(aiResponse);
      debugPrint('🔍 [_analyzeIntent] Match encontrado: ${match != null}');

      if (match != null) {
        final actionParts = match.group(1)!.split('|');
        final actionType = actionParts[0];
        debugPrint('🔍 [_analyzeIntent] Tipo de acción: $actionType');
        debugPrint('🔍 [_analyzeIntent] Partes: $actionParts');

        switch (actionType) {
          case 'SHOW_SEARCH_RESULTS':
            return {
              'type': 'show_search_results',
            };
          case 'BOOK_SERVICE':
            debugPrint('✅ [_analyzeIntent] Detectado BOOK_SERVICE');
            return {
              'type': 'book_service',
              'service_id': actionParts.length > 1 ? actionParts[1] : null,
              'date': actionParts.length > 2 ? actionParts[2] : null,
              'time': actionParts.length > 3 ? actionParts[3] : null,
              'address': actionParts.length > 4 ? actionParts[4] : null,
            };
          case 'ADD_TO_CART':
            return {
              'type': 'add_to_cart',
              'product_id': actionParts.length > 1 ? actionParts[1] : null,
              'quantity': actionParts.length > 2
                  ? int.tryParse(actionParts[2]) ?? 1
                  : 1,
            };
          case 'SHOW_SERVICES':
            return {
              'type': 'show_services',
              'category': actionParts.length > 1 ? actionParts[1] : null,
            };
          case 'SHOW_PRODUCTS':
            return {
              'type': 'show_products',
              'category': actionParts.length > 1 ? actionParts[1] : null,
            };
        }
      }
    }

    // Detectar intenciones por palabras clave SOLO si no hay ID en el mensaje
    final hasId = userMessage.contains(RegExp(r'\(ID:\s*[^)]+\)'));

    if (!hasId) {
      if (lowerMessage.contains('reservar') ||
          lowerMessage.contains('necesito') ||
          lowerMessage.contains('contratar')) {
        if (lowerMessage.contains('limpieza'))
          return {'type': 'book_service', 'category': 'limpieza'};
        if (lowerMessage.contains('fontaner') ||
            lowerMessage.contains('plomer'))
          return {'type': 'book_service', 'category': 'fontaneria'};
        if (lowerMessage.contains('electric'))
          return {'type': 'book_service', 'category': 'electricidad'};
        return {'type': 'book_service', 'category': null};
      }

      if (lowerMessage.contains('comprar') ||
          lowerMessage.contains('producto')) {
        return {'type': 'shopping', 'category': null};
      }

      if (lowerMessage.contains('precio') ||
          lowerMessage.contains('costo') ||
          lowerMessage.contains('cuanto')) {
        return {'type': 'pricing_inquiry'};
      }
    }

    return {'type': 'general_inquiry'};
  }

  /// Guardar conversación en Supabase
  static Future<void> saveConversation(AIConversation conversation) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        debugPrint('⚠️ Usuario no autenticado, no se guardará la conversación');
        return;
      }

      await supabase.from('ai_conversations').upsert({
        'id': conversation.id,
        'user_id': conversation.userId,
        'title': conversation.title,
        'messages': conversation.messages.map((m) => m.toJson()).toList(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Conversación guardada en Supabase');
    } catch (e) {
      debugPrint('⚠️ Error guardando conversación: $e');
    }
  }

  /// Cargar conversaciones del usuario
  static Future<List<AIConversation>> loadUserConversations(
      String userId) async {
    try {
      final supabase = Supabase.instance.client;

      final data = await supabase
          .from('ai_conversations')
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false);

      return (data as List)
          .map((json) => AIConversation.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('⚠️ Error cargando conversaciones: $e');
      return [];
    }
  }

  /// Generar título de conversación basado en el primer mensaje
  static String generateConversationTitle(String firstMessage) {
    if (firstMessage.length <= 40) return firstMessage;
    return '${firstMessage.substring(0, 37)}...';
  }
}
