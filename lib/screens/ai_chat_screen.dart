import 'package:flutter/material.dart';
import 'package:fixy_home_service/theme/app_theme.dart';
import 'package:fixy_home_service/services/ai_assistant_service.dart';
import 'package:fixy_home_service/services/speech_service.dart';
import 'package:fixy_home_service/services/openai_service.dart';
import 'package:fixy_home_service/services/order_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:fixy_home_service/models/ai_conversation_model.dart';
import 'package:fixy_home_service/models/service_model.dart';
import 'package:fixy_home_service/models/product_model.dart';
import 'package:fixy_home_service/screens/shop/cart_screen.dart';
import 'package:fixy_home_service/data/service_repository.dart';
import 'package:fixy_home_service/data/product_repository.dart';
import 'package:fixy_home_service/providers/cart_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import 'package:fixy_home_service/providers/profile_provider.dart';
import 'package:fixy_home_service/utils/page_transitions.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({Key? key}) : super(key: key);

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SpeechService _speechService = SpeechService();

  List<AIConversationMessage> _messages = [];
  bool _isLoading = false;
  bool _isListening = false;
  String? _conversationId;
  String? _userId;

  final ServiceRepository _serviceRepo = ServiceRepository();
  final ProductRepository _productRepo = ProductRepository();
  List<ServiceModel> _availableServices = [];
  List<ProductModel> _availableProducts = [];
  List<OrderModel> _userOrders = [];

  // Análisis de imágenes con IA
  File? _selectedImage;
  bool _isAnalyzingImage = false;
  final OpenAIService _openAIService = OpenAIService();

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _initializeSpeech();
  }

  Future<void> _initializeChat() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        _userId = user.id;
      });

      // Cargar perfil del usuario desde ProfileProvider
      final profileProvider = context.read<ProfileProvider>();
      await profileProvider.loadUserProfile();

      // 🛒 Cargar historial de compras del usuario
      await _loadUserOrders();

      // Cargar servicios y productos disponibles
      _loadAvailableOptions();

      // 🔄 Cargar conversaciones previas del usuario
      await _loadPreviousConversations();

      // Si no hay conversación previa, crear nueva con mensaje de bienvenida
      if (_conversationId == null) {
        setState(() {
          _conversationId = const Uuid().v4();
        });
        _addMessage(AIConversationMessage(
          id: const Uuid().v4(),
          role: 'assistant',
          content:
              '¡Hola! Soy tu asistente virtual. ¿En qué puedo ayudarte hoy?\n\nPuedo ayudarte a:\n• Reservar servicios (limpieza, fontanería, electricidad, etc.)\n• Comprar productos de la tienda\n• Responder tus preguntas',
          timestamp: DateTime.now(),
        ));
      }
    }
  }

  /// Cargar conversaciones previas del usuario desde Supabase
  Future<void> _loadPreviousConversations() async {
    try {
      debugPrint('🔄 [CHAT] Cargando conversaciones previas...');
      final conversations =
          await AIAssistantService.loadUserConversations(_userId!);

      if (conversations.isNotEmpty) {
        // Cargar la conversación más reciente
        final lastConversation = conversations.first;
        setState(() {
          _conversationId = lastConversation.id;
          _messages =
              List<AIConversationMessage>.from(lastConversation.messages);
        });
        debugPrint('✅ [CHAT] Conversación cargada: ${lastConversation.id}');
        debugPrint('   - Mensajes: ${_messages.length}');

        // 📜 Scroll al final para mostrar donde quedó la conversación
        _scrollToBottom();
      } else {
        debugPrint('ℹ️ [CHAT] No hay conversaciones previas');
      }
    } catch (e) {
      debugPrint('⚠️ [CHAT] Error cargando conversaciones: $e');
    }
  }

  /// 🛒 Cargar historial de compras del usuario
  Future<void> _loadUserOrders() async {
    try {
      debugPrint('🛒 [CHAT] Cargando historial de compras...');
      final orderService = OrderService();
      final orders = await orderService.getUserOrders();
      setState(() {
        _userOrders = orders;
      });
      debugPrint('✅ [CHAT] ${orders.length} órdenes cargadas');
    } catch (e) {
      debugPrint('⚠️ [CHAT] Error cargando órdenes: $e');
    }
  }

  Future<void> _loadAvailableOptions() async {
    try {
      final services = await _serviceRepo.getPopularServices();
      final products = await _productRepo.getAllProducts();
      setState(() {
        _availableServices = services;
        _availableProducts = products;
      });
      debugPrint(
          '✅ [CHAT] Opciones cargadas: ${services.length} servicios, ${products.length} productos');
      if (products.isNotEmpty) {
        debugPrint(
            '📦 [CHAT] Primeros 3 productos: ${products.take(3).map((p) => p.name).join(", ")}');
      }
    } catch (e) {
      debugPrint('⚠️ [CHAT] Error cargando opciones: $e');
    }
  }

  Future<void> _initializeSpeech() async {
    await _speechService.initialize();

    _speechService.textStream.listen((text) {
      setState(() => _messageController.text = text);
    });

    _speechService.listeningStream.listen((listening) {
      setState(() => _isListening = listening);
    });
  }

  void _addMessage(AIConversationMessage message) {
    setState(() {
      _messages.add(message);
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    // Si hay imagen, analizar con visión IA
    if (_selectedImage != null) {
      await _analyzeImageWithAI(message);
      return;
    }

    // Agregar mensaje del usuario
    final userMessage = AIConversationMessage(
      id: const Uuid().v4(),
      role: 'user',
      content: message,
      timestamp: DateTime.now(),
    );
    _addMessage(userMessage);
    _messageController.clear();

    setState(() => _isLoading = true);

    try {
      debugPrint(
          '📤 [CHAT] Enviando mensaje con ${_availableProducts.length} productos disponibles');

      // Obtener perfil del usuario actual
      final profileProvider = context.read<ProfileProvider>();
      final userProfile = profileProvider.userProfile;

      // Procesar mensaje con IA
      final result = await AIAssistantService.processMessage(
        userMessage: message,
        conversationHistory: _messages,
        availableServices: _availableServices,
        availableProducts: _availableProducts,
        userProfile: userProfile,
        userOrders: _userOrders,
        onFetchServices: (category) async {
          final services = await _serviceRepo.searchServices(query: category);
          setState(() => _availableServices = services);
        },
        onFetchProducts: (category) async {
          final products = await _productRepo.searchProducts(category);
          setState(() => _availableProducts = products);
        },
      );

      debugPrint('📥 [CHAT] Resultado recibido:');
      debugPrint('   - Intent: ${result['intent']?['type']}');
      debugPrint(
          '   - Visual Options: ${result['visualOptions']?.length ?? 0}');
      if (result['visualOptions'] != null &&
          result['visualOptions'].isNotEmpty) {
        debugPrint(
            '   - Opciones: ${result['visualOptions'].map((o) => o is ProductModel ? o.name : o.toString()).join(", ")}');
      }

      // Limpiar acciones de la respuesta antes de mostrarla
      String aiResponse = result['response'];
      aiResponse =
          aiResponse.replaceAll(RegExp(r'\[ACTION:[^\]]+\]'), '').trim();

      // 🔄 POST-PROCESAMIENTO: Si el usuario preguntó por su dirección, reemplazar con datos reales
      if (userProfile != null) {
        final lowerMessage = message.toLowerCase();
        final isAskingForAddress = lowerMessage.contains('dirección') ||
            lowerMessage.contains('direccion') ||
            lowerMessage.contains('tienes mi direccion') ||
            lowerMessage.contains('tienes mi dirección') ||
            lowerMessage.contains('acceso a mi direccion') ||
            lowerMessage.contains('mi direccion guardada') ||
            lowerMessage.contains('mi dirección guardada') ||
            lowerMessage.contains('donde vivo') ||
            lowerMessage.contains('mi ubicacion') ||
            lowerMessage.contains('mi ubicación');

        if (isAskingForAddress && userProfile.address.isNotEmpty) {
          final address = userProfile.address;
          final city =
              userProfile.city.isNotEmpty ? ', ${userProfile.city}' : '';
          aiResponse =
              'Sí, tengo tu dirección guardada: **$address$city**. Puedo usar esta dirección automáticamente cuando hagas reservas de servicios. ¿Te gustaría hacer una reserva ahora?';
          debugPrint(
              '✅ [CHAT] Reemplazando respuesta con dirección real: $address$city');
        }
      }

      // Agregar respuesta de IA
      final aiMessage = AIConversationMessage(
        id: const Uuid().v4(),
        role: 'assistant',
        content: aiResponse,
        timestamp: DateTime.now(),
        metadata: result['intent'],
        visualOptions: result['visualOptions'],
      );

      debugPrint(
          '💬 [CHAT] Mensaje creado con ${aiMessage.visualOptions?.length ?? 0} opciones visuales');
      _addMessage(aiMessage);

      // Ejecutar acciones detectadas
      await _handleAIIntent(result['intent']);

      // Guardar conversación
      if (_userId != null && _conversationId != null) {
        final conversation = AIConversation(
          id: _conversationId!,
          userId: _userId!,
          title: _messages.length <= 2
              ? AIAssistantService.generateConversationTitle(message)
              : 'Conversación',
          messages: _messages,
          createdAt: _messages.first.timestamp,
          updatedAt: DateTime.now(),
        );
        await AIAssistantService.saveConversation(conversation);
      }
    } catch (e) {
      debugPrint('Error enviando mensaje: $e');
      _addMessage(AIConversationMessage(
        id: const Uuid().v4(),
        role: 'assistant',
        content: 'Lo siento, hubo un error. Por favor intenta de nuevo.',
        timestamp: DateTime.now(),
      ));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAIIntent(Map<String, dynamic> intent) async {
    final type = intent['type'];

    debugPrint('🎯 [HANDLE_INTENT] Tipo de acción recibida: $type');
    debugPrint('🎯 [HANDLE_INTENT] Datos completos del intent: $intent');

    switch (type) {
      case 'add_to_cart':
        await _addProductToCart(intent);
        break;
      case 'show_search_results':
        debugPrint('🔍 Mostrando resultados de búsqueda en el chat');
        break;
      case 'show_services':
      case 'browse_services':
        debugPrint('🎯 Mostrando servicios en el chat');
        break;
      case 'show_products':
      case 'browse_products':
      case 'shopping':
        debugPrint('🎯 Mostrando productos en el chat');
        break;
    }
  }

  Future<void> _addProductToCart(Map<String, dynamic> intent) async {
    try {
      // Extraer el ID del último mensaje del usuario (si está entre paréntesis)
      String? productId = intent['product_id'];

      // Si no viene en el intent, buscar en el último mensaje del usuario
      if (productId == null && _messages.isNotEmpty) {
        final lastUserMessage = _messages.lastWhere(
          (m) => m.role == 'user',
          orElse: () => _messages.last,
        );
        final idMatch =
            RegExp(r'\(ID:\s*([^)]+)\)').firstMatch(lastUserMessage.content);
        if (idMatch != null) {
          productId = idMatch.group(1);
        }
      }

      final quantity = intent['quantity'] ?? 1;

      if (productId == null) {
        debugPrint('⚠️ Falta el ID del producto');
        return;
      }

      final product = _availableProducts.firstWhere(
        (p) => p.id == productId,
        orElse: () => _availableProducts.first,
      );

      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      await cartProvider.addToCart(product, quantity: quantity);

      debugPrint('✅ Producto agregado al carrito');

      // Mensaje de confirmación con botón de acción
      _addMessage(AIConversationMessage(
        id: const Uuid().v4(),
        role: 'assistant',
        content:
            '¡Perfecto! ✅ He agregado ${quantity}x "${product.name}" a tu carrito.\n\n🛒 Total en carrito: ${cartProvider.items.length} producto(s)\n💰 Subtotal: S/ ${cartProvider.cart.subtotal.toStringAsFixed(2)}\n\n¿Quieres proceder al pago o agregar más productos?',
        timestamp: DateTime.now(),
        metadata: {'action': 'product_added', 'show_cart_button': true},
      ));
    } catch (e) {
      debugPrint('❌ Error agregando al carrito: $e');
      _addMessage(AIConversationMessage(
        id: const Uuid().v4(),
        role: 'assistant',
        content: 'Lo siento, hubo un error al agregar el producto al carrito.',
        timestamp: DateTime.now(),
      ));
    }
  }

  void _toggleListening() {
    if (_isListening) {
      _speechService.stopListening();
    } else {
      _speechService.startListening();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _messageController.text = '¿Qué problema tiene esto?';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.camera_alt, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Imagen lista. Describe el problema o envía directamente'),
              ],
            ),
            backgroundColor: Color(0xFF6366F1),
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error al seleccionar imagen: \$e');
    }
  }

  Future<void> _analyzeImageWithAI(String userMessage) async {
    // Agregar mensaje del usuario con la imagen
    final userMsg = AIConversationMessage(
      id: const Uuid().v4(),
      role: 'user',
      content: '📷 [Imagen adjunta]\n$userMessage',
      timestamp: DateTime.now(),
    );
    _addMessage(userMsg);
    _messageController.clear();

    setState(() => _isAnalyzingImage = true);

    try {
      // Analizar imagen con OpenAI Vision
      debugPrint('🔍 Analizando imagen con IA...');

      // Nota: La imagen se analiza visualmente por el usuario, el AI procesa la descripción
      final prompt = userMessage.isEmpty
          ? 'El usuario ha enviado una imagen de un problema en su casa. Por favor analiza problemas comunes del hogar relacionados con construcción, fontanería, electricidad, o mantenimiento.'
          : 'El usuario ha enviado una imagen y describe: $userMessage';

      // Analizar la imagen con OpenAI
      final analysisStream =
          _openAIService.analyzeHouseholdProblemStream(prompt);

      String analysisText = '';

      await for (var update in analysisStream) {
        if (update['status'] == 'done') {
          final response = update['data'];
          analysisText =
              response['analysis'] ?? 'No se pudo analizar la imagen';
          break;
        }
      }

      if (analysisText.isNotEmpty) {
        // Construir respuesta simple
        final aiResponse = '''🔍 **Análisis de imagen completado**

$analysisText

¿Te gustaría ver productos o servicios relacionados con este problema?''';

        // Agregar respuesta de IA
        final aiMessage = AIConversationMessage(
          id: const Uuid().v4(),
          role: 'assistant',
          content: aiResponse,
          timestamp: DateTime.now(),
          metadata: {'type': 'image_analysis'},
        );
        _addMessage(aiMessage);
      }
    } catch (e) {
      debugPrint('❌ Error analizando imagen: \$e');
      _addMessage(AIConversationMessage(
        id: const Uuid().v4(),
        role: 'assistant',
        content:
            'Lo siento, hubo un error al analizar la imagen. Por favor intenta de nuevo o descríbeme el problema.',
        timestamp: DateTime.now(),
      ));
    } finally {
      setState(() {
        _isAnalyzingImage = false;
        _selectedImage = null;
      });
    }
  }

  Widget _buildCartButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 44),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                  context, SlideRightRoute(page: const CartScreen()));
            },
            icon:
                const Icon(Icons.shopping_cart, size: 18, color: Colors.white),
            label: const Text('Ver Carrito',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () {
              setState(() =>
                  _messageController.text = 'Quiero agregar más productos');
              _sendMessage();
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Agregar Más',
                style: TextStyle(fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              side: const BorderSide(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 44),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // El usuario puede ir a Perfil > Historial de Servicios desde el nav bar
            },
            icon:
                const Icon(Icons.calendar_today, size: 18, color: Colors.white),
            label: const Text('Ver Mis Reservas',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () {
              setState(() =>
                  _messageController.text = 'Quiero reservar otro servicio');
              _sendMessage();
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Reservar Más',
                style: TextStyle(fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              side: const BorderSide(color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _speechService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
              ),
              child:
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Asistente IA',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Siempre disponible',
                    style: TextStyle(fontSize: 11, color: Colors.green)),
              ],
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            ),
                          ),
                          child: const Icon(Icons.auto_awesome,
                              color: Colors.white, size: 40),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Asistente IA',
                          style: AppTheme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '¿En qué puedo ayudarte hoy?',
                          style: AppTheme.textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];

                      // Debug log para rastrear visualOptions
                      if (message.role == 'assistant' &&
                          index == _messages.length - 1) {
                        debugPrint('🎨 [RENDER] Último mensaje asistente:');
                        debugPrint(
                            '   - visualOptions: ${message.visualOptions?.length ?? "null"}');
                        debugPrint('   - metadata: ${message.metadata}');
                      }

                      return Column(
                        children: [
                          _buildMessageBubble(message),
                          if (message.visualOptions != null &&
                              message.visualOptions!.isNotEmpty)
                            _buildVisualOptions(message.visualOptions!),
                          if (message.metadata != null &&
                              message.metadata!['show_cart_button'] == true)
                            _buildCartButton(),
                          if (message.metadata != null &&
                              message.metadata!['action'] ==
                                  'reservation_created')
                            _buildReservationButton(),
                        ],
                      );
                    },
                  ),
          ),

          // Loading indicator
          if (_isLoading || _isAnalyzingImage)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                      _isAnalyzingImage
                          ? 'Analizando imagen...'
                          : 'Escribiendo...',
                      style: const TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            ),

          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Camera button
                  GestureDetector(
                    onTap: () => _pickImage(ImageSource.camera),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Color(0xFF6366F1),
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Gallery button
                  GestureDetector(
                    onTap: () => _pickImage(ImageSource.gallery),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.photo_library,
                        color: Color(0xFF8B5CF6),
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Voice input button
                  GestureDetector(
                    onTap: _toggleListening,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _isListening
                            ? Colors.red.shade50
                            : AppTheme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color:
                            _isListening ? Colors.red : AppTheme.primaryColor,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Image preview
                  if (_selectedImage != null)
                    Stack(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: const Color(0xFF6366F1), width: 2),
                            image: DecorationImage(
                              image: FileImage(_selectedImage!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: -4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedImage = null),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),

                  // Text input
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: _isListening
                              ? 'Escuchando...'
                              : 'Escribe tu mensaje...',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Send button
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child:
                          const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(AIConversationMessage message) {
    final isUser = message.role == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
              ),
              child:
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.primaryColor : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isUser ? 16 : 4),
                  topRight: Radius.circular(isUser ? 4 : 16),
                  bottomLeft: const Radius.circular(16),
                  bottomRight: const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: isUser ? Colors.white : AppTheme.textPrimary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser)
            Consumer<ProfileProvider>(
              builder: (context, profileProvider, child) {
                final avatarUrl = profileProvider.userProfile?.avatarUrl;
                final userName = profileProvider.userProfile?.name ?? 'U';

                return Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade300,
                    image: avatarUrl != null &&
                            avatarUrl.isNotEmpty &&
                            !avatarUrl.contains('placeholder') &&
                            !avatarUrl.contains('ui-avatars')
                        ? DecorationImage(
                            image: NetworkImage(avatarUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: avatarUrl == null ||
                          avatarUrl.isEmpty ||
                          avatarUrl.contains('placeholder') ||
                          avatarUrl.contains('ui-avatars')
                      ? Center(
                          child: Text(
                            userName.isNotEmpty
                                ? userName[0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildVisualOptions(List<dynamic> options) {
    return Container(
      height: 200,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        itemBuilder: (context, index) {
          final option = options[index];
          if (option is ServiceModel) {
            return _buildServiceCard(option);
          } else if (option is ProductModel) {
            return _buildProductCard(option);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildServiceCard(ServiceModel service) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _messageController.text =
              'Quiero reservar "${service.title}" (ID: ${service.id})';
        });
        _sendMessage();
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                service.imageUrl,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 100,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${service.currency}${service.price}/${service.timeUnit}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _messageController.text =
              'Quiero comprar "${product.name}" (ID: ${product.id})';
        });
        _sendMessage();
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                product.images.isNotEmpty ? product.images.first : '',
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 100,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.shopping_bag, color: Colors.grey),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'S/ ${product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
