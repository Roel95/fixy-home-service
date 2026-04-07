import 'package:flutter/material.dart';
import 'package:fixy_home_service/theme/app_theme.dart';
import 'package:fixy_home_service/services/ai_assistant_service.dart';
import 'package:fixy_home_service/services/speech_service.dart';
import 'package:fixy_home_service/models/ai_conversation_model.dart';
import 'package:fixy_home_service/models/service_model.dart';
import 'package:uuid/uuid.dart';

class VoiceBookingDialog extends StatefulWidget {
  final ServiceModel? service;

  const VoiceBookingDialog({super.key, this.service});

  @override
  State<VoiceBookingDialog> createState() => _VoiceBookingDialogState();
}

class _VoiceBookingDialogState extends State<VoiceBookingDialog>
    with SingleTickerProviderStateMixin {
  final SpeechService _speechService = SpeechService();
  final List<AIConversationMessage> _messages = [];

  bool _isListening = false;
  bool _isLoading = false;
  String _currentTranscript = '';
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    // Mensaje inicial
    if (widget.service != null) {
      _addAssistantMessage(
        '¡Perfecto! Vamos a reservar ${widget.service!.title}.\n\n¿Cuándo lo necesitas? Puedes decir, por ejemplo: "Mañana a las 2 de la tarde" o "El viernes por la mañana"',
      );
    } else {
      _addAssistantMessage(
        '¡Hola! Soy tu asistente de reservas por voz 🎙️\n\n¿Qué servicio necesitas? Por ejemplo: "Necesito un plomero", "Quiero un electricista mañana", etc.',
      );
    }
  }

  Future<void> _initializeSpeech() async {
    await _speechService.initialize();

    _speechService.textStream.listen((text) {
      setState(() => _currentTranscript = text);
    });

    _speechService.listeningStream.listen((listening) {
      setState(() => _isListening = listening);

      // Cuando termina de escuchar, procesar el mensaje
      if (!listening && _currentTranscript.isNotEmpty) {
        _processUserMessage(_currentTranscript);
        _currentTranscript = '';
      }
    });
  }

  void _addAssistantMessage(String content) {
    setState(() {
      _messages.add(AIConversationMessage(
        id: const Uuid().v4(),
        role: 'assistant',
        content: content,
        timestamp: DateTime.now(),
      ));
    });
  }

  void _addUserMessage(String content) {
    setState(() {
      _messages.add(AIConversationMessage(
        id: const Uuid().v4(),
        role: 'user',
        content: content,
        timestamp: DateTime.now(),
      ));
    });
  }

  Future<void> _processUserMessage(String message) async {
    _addUserMessage(message);
    setState(() => _isLoading = true);

    try {
      String systemContext;

      if (widget.service != null) {
        // Modo con servicio específico
        systemContext =
            '''Estás ayudando al usuario a reservar el servicio: "${widget.service!.title}".
Precio: ${widget.service!.currency}${widget.service!.price}/${widget.service!.timeUnit}.
Ya tienes esta información, así que extrae SOLO:
1. Fecha (ejemplo: "mañana", "el viernes", "15 de enero")
2. Hora (ejemplo: "2 de la tarde", "10 am", "por la mañana")
3. Dirección (si la menciona)

Responde confirmando la información y preguntando lo que falta. Sé muy breve (máximo 2 líneas).
Cuando tengas fecha Y hora, responde: "¡Perfecto! [CONFIRMAR]" y resume los datos.''';
      } else {
        // Modo búsqueda general
        systemContext = '''Ayuda al usuario a encontrar servicios del hogar.
Identifica qué servicio necesita (plomería, electricidad, limpieza, etc.).
Responde brevemente y confirma el servicio. Sé muy breve (máximo 2 líneas).
Si identificas claramente el servicio, responde: "¡Entendido! [BUSCAR:tipo_servicio]"
Ejemplos: [BUSCAR:plomero], [BUSCAR:electricista], [BUSCAR:limpieza]''';
      }

      final result = await AIAssistantService.processMessage(
        userMessage: '$systemContext\n\nUsuario dice: $message',
        conversationHistory: _messages.take(_messages.length - 1).toList(),
      );

      String aiResponse = result['response'];

      // Si NO tiene servicio y detecta búsqueda
      if (widget.service == null && aiResponse.contains('[BUSCAR:')) {
        final searchMatch =
            RegExp(r'\[BUSCAR:([^\]]+)\]').firstMatch(aiResponse);
        if (searchMatch != null) {
          final searchQuery = searchMatch.group(1) ?? '';
          aiResponse =
              aiResponse.replaceAll(RegExp(r'\[BUSCAR:[^\]]+\]'), '').trim();
          _addAssistantMessage(aiResponse);

          await Future.delayed(const Duration(seconds: 1));

          if (mounted) {
            Navigator.pop(context);
            // Navegar a la pantalla de búsqueda con el query
            Navigator.pushNamed(
              context,
              '/search',
              arguments: {'query': searchQuery},
            );
          }
        }
      } else {
        _addAssistantMessage(aiResponse);
      }
    } catch (e) {
      _addAssistantMessage('Lo siento, hubo un error. ¿Puedes repetir?');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleListening() {
    if (_isListening) {
      _speechService.stopListening();
    } else {
      _speechService.startListening();
    }
  }

  @override
  void dispose() {
    _speechService.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                  ),
                  child: const Icon(Icons.mic, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reserva por Voz',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (widget.service != null)
                        Text(
                          widget.service!.title,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),

            // Chat messages
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isUser = message.role == 'user';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: isUser
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      children: [
                        if (!isUser) ...[
                          const Icon(Icons.smart_toy,
                              size: 20, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? AppTheme.primaryColor
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              message.content,
                              style: TextStyle(
                                color: isUser
                                    ? Colors.white
                                    : AppTheme.textPrimary,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Current transcript
            if (_isListening && _currentTranscript.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.hearing, color: Colors.blue, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _currentTranscript,
                        style: const TextStyle(
                            fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),

            // Loading indicator
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Procesando...', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Voice button
            GestureDetector(
              onTap: _isLoading ? null : _toggleListening,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale =
                      _isListening ? 1.0 + (_pulseController.value * 0.1) : 1.0;
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: _isListening
                              ? [Colors.red.shade400, Colors.red.shade600]
                              : [
                                  const Color(0xFF6366F1),
                                  const Color(0xFF8B5CF6)
                                ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_isListening
                                    ? Colors.red
                                    : AppTheme.primaryColor)
                                .withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            Text(
              _isListening ? 'Escuchando...' : 'Toca para hablar',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
