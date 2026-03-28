import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

class OpenAIService {
  static const String _deepseekApiKey = 'sk-d510ccacfaf842fabb01603bab4404d7';
  static const String _deepseekApiUrl =
      'https://api.deepseek.com/v1/chat/completions';

  // Call DeepSeek API with streaming support
  Stream<Map<String, dynamic>> analyzeHouseholdProblemStream(String userPrompt,
      {List<Map<String, dynamic>>? availableProviders}) async* {
    try {
      print('🚀 Llamando a DeepSeek API con streaming...');
      print('📝 Prompt: $userPrompt');

      // Build provider context
      String providerContext = '';
      if (availableProviders != null && availableProviders.isNotEmpty) {
        providerContext = '\n\nProveedores disponibles: ';
        providerContext += availableProviders
            .take(3)
            .map((p) => p['business_name'])
            .join(', ');
      }

      final request = http.Request('POST', Uri.parse(_deepseekApiUrl));
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_deepseekApiKey',
      });

      request.body = jsonEncode({
        'model': 'deepseek-chat',
        'messages': [
          {
            'role': 'system',
            'content':
                '''Eres un asistente de servicios del hogar en Perú. Responde SOLO con JSON válido (sin markdown).$providerContext

Estructura JSON:
{
  "problem_title": "Título corto (máx 50 caracteres)",
  "analysis": "Análisis del problema: causas, síntomas, riesgos (60-80 palabras)",
  "solutions": [
    {
      "title": "Nombre de la solución",
      "description": "Descripción con pasos específicos y materiales (40-60 palabras)",
      "is_diy": boolean,
      "estimated_cost": "Rango en soles (ej: 'S/20-50')",
      "required_time": "Tiempo estimado (ej: '30 min')"
    }
  ],
  "service_categories": ["Categorías relevantes: Fontanería, Electricidad, etc."],
  "recommended_products": ["3-4 productos específicos de ferretería"],
  "urgency_level": "Low/Medium/High",
  "difficulty_level": "Easy/Medium/Hard"
}

Proporciona 3-4 soluciones (DIY fácil, DIY medio, profesional). Sé conciso y práctico.'''
          },
          {'role': 'user', 'content': userPrompt}
        ],
        'temperature': 0.6,
        'stream': true,
      });

      final streamedResponse = await request.send();

      if (streamedResponse.statusCode != 200) {
        print('❌ Error: ${streamedResponse.statusCode}');
        yield {
          'error': 'Error en la API',
          'status_code': streamedResponse.statusCode
        };
        return;
      }

      // Emit loading state first
      yield {'status': 'processing', 'progress': 0.0};

      String accumulatedContent = '';
      int chunkCount = 0;

      await for (var chunk in streamedResponse.stream.transform(utf8.decoder)) {
        chunkCount++;
        final lines = chunk.split('\n').where((line) => line.trim().isNotEmpty);

        for (var line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();
            if (data == '[DONE]') continue;

            try {
              final jsonData = jsonDecode(data);
              if (jsonData['choices'] != null &&
                  jsonData['choices'].isNotEmpty) {
                final delta = jsonData['choices'][0]['delta'];
                if (delta['content'] != null) {
                  accumulatedContent += delta['content'];

                  // Emit progress updates
                  final progress =
                      (accumulatedContent.length / 800).clamp(0.0, 0.95);
                  yield {
                    'status': 'streaming',
                    'progress': progress,
                    'partial_content': accumulatedContent.length > 100
                        ? accumulatedContent.substring(0, 100) + '...'
                        : accumulatedContent
                  };
                }
              }
            } catch (e) {
              // Skip malformed chunks
              continue;
            }
          }
        }
      }

      print('✅ Stream completado, procesando respuesta final...');

      // Process final accumulated content
      String content = accumulatedContent.trim();

      // Remove markdown code blocks if present
      if (content.startsWith('```json')) {
        content = content.substring(7);
      }
      if (content.startsWith('```')) {
        content = content.substring(3);
      }
      if (content.endsWith('```')) {
        content = content.substring(0, content.length - 3);
      }
      content = content.trim();

      final analysis = jsonDecode(content);

      // Save to Supabase
      await _saveAnalysisToSupabase(userPrompt, analysis);

      yield {'status': 'done', 'data': analysis, 'progress': 1.0};
    } catch (e, stackTrace) {
      print('💥 Exception: $e');
      print('Stack trace: $stackTrace');
      yield {'status': 'error', 'error': e.toString()};
    }
  }

  // Legacy non-streaming method for backward compatibility
  Future<Map<String, dynamic>> analyzeHouseholdProblem(String userPrompt,
      {List<Map<String, dynamic>>? availableProviders}) async {
    try {
      print('🚀 Llamando a DeepSeek API (modo no-streaming)...');
      print('📝 Prompt: $userPrompt');

      // Build provider context
      String providerContext = '';
      if (availableProviders != null && availableProviders.isNotEmpty) {
        providerContext = '\n\nProveedores disponibles: ';
        providerContext += availableProviders
            .take(3)
            .map((p) => p['business_name'])
            .join(', ');
      }

      final response = await http.post(
        Uri.parse(_deepseekApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_deepseekApiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'system',
              'content':
                  '''Eres un asistente de servicios del hogar en Perú. Responde SOLO con JSON válido (sin markdown).$providerContext

Estructura JSON:
{
  "problem_title": "Título corto (máx 50 caracteres)",
  "analysis": "Análisis del problema: causas, síntomas, riesgos (60-80 palabras)",
  "solutions": [
    {
      "title": "Nombre de la solución",
      "description": "Descripción con pasos específicos y materiales (40-60 palabras)",
      "is_diy": boolean,
      "estimated_cost": "Rango en soles (ej: 'S/20-50')",
      "required_time": "Tiempo estimado (ej: '30 min')"
    }
  ],
  "service_categories": ["Categorías relevantes: Fontanería, Electricidad, etc."],
  "recommended_products": ["3-4 productos específicos de ferretería"],
  "urgency_level": "Low/Medium/High",
  "difficulty_level": "Easy/Medium/Hard"
}

Proporciona 3-4 soluciones (DIY fácil, DIY medio, profesional). Sé conciso y práctico.'''
            },
            {'role': 'user', 'content': userPrompt}
          ],
          'temperature': 0.6,
        }),
      );

      print('📡 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['choices'] != null && data['choices'].isNotEmpty) {
          String content = data['choices'][0]['message']['content'].trim();

          // Remove markdown code blocks if present
          if (content.startsWith('```json')) {
            content = content.substring(7);
          }
          if (content.startsWith('```')) {
            content = content.substring(3);
          }
          if (content.endsWith('```')) {
            content = content.substring(0, content.length - 3);
          }
          content = content.trim();

          final analysis = jsonDecode(content);
          print('✅ Análisis recibido de DeepSeek');

          // Save to Supabase if user is authenticated
          await _saveAnalysisToSupabase(userPrompt, analysis);

          return analysis;
        }

        return {'error': 'No response from AI'};
      } else {
        print('❌ Error: ${response.statusCode} - ${response.body}');
        return {
          'error': 'Failed to get response from DeepSeek',
          'status_code': response.statusCode,
          'response': response.body
        };
      }
    } catch (e, stackTrace) {
      print('💥 Exception: $e');
      print('Stack trace: $stackTrace');
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> analyzeHouseholdProblemWithImage(
      String userPrompt, String imageBase64) async {
    try {
      print('📸 Llamando a DeepSeek API con imagen...');

      // Note: DeepSeek doesn't support vision yet, so we'll analyze text only
      print('⚠️ Análisis de imagen no disponible, procesando solo texto');
      return await analyzeHouseholdProblem(userPrompt);
    } catch (e, stackTrace) {
      print('💥 Exception: $e');
      print('Stack trace: $stackTrace');
      return {'error': e.toString()};
    }
  }

  // Save analysis to Supabase database
  Future<void> _saveAnalysisToSupabase(
      String userPrompt, Map<String, dynamic> analysis) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        print('⚠️ Usuario no autenticado, no se guardará el análisis');
        return;
      }

      // Check if table exists by trying to insert
      await supabase.from('ai_analysis_history').insert({
        'user_id': user.id,
        'user_prompt': userPrompt,
        'problem_title': analysis['problem_title'],
        'analysis': analysis['analysis'],
        'solutions': analysis['solutions'],
        'service_categories': analysis['service_categories'],
        'urgency_level': analysis['urgency_level'],
        'difficulty_level': analysis['difficulty_level'],
      });

      print('✅ Análisis guardado en Supabase');
    } catch (e) {
      print('⚠️ No se pudo guardar en Supabase (tabla no existe aún): $e');
      // Don't fail if table doesn't exist
    }
  }

  // Mock response for testing without an OpenAI API key
  Map<String, dynamic> getMockResponse() {
    return {
      "problem_title": "Fregadero obstruido con drenaje lento",
      "analysis":
          "El problema parece ser una obstrucción en las tuberías del fregadero, lo que está causando que el agua drene lentamente. Esto normalmente ocurre por acumulación de residuos de comida, grasa, cabello u otros materiales que se van adhiriendo a las paredes internas de la tubería.",
      "solutions": [
        {
          "title": "Usar un desatascador manual",
          "description":
              "Utiliza un desatascador de goma (émbolo) para crear succión y presión que puede desalojar la obstrucción.",
          "is_diy": true,
          "estimated_cost": "S/10-30 (si necesitas comprar un desatascador)",
          "required_time": "15-30 minutos"
        },
        {
          "title": "Limpieza con soda cáustica o bicarbonato y vinagre",
          "description":
              "Vierte agua hirviendo, seguida de una mezcla de bicarbonato y vinagre, o utiliza soda cáustica siguiendo las instrucciones del producto.",
          "is_diy": true,
          "estimated_cost": "S/5-20",
          "required_time": "30-60 minutos"
        },
        {
          "title": "Desmontar y limpiar el sifón",
          "description":
              "Coloca un cubo debajo del sifón, desenrósca las conexiones, retira y limpia el sifón donde suelen acumularse residuos.",
          "is_diy": true,
          "estimated_cost": "S/0 (si ya tienes herramientas básicas)",
          "required_time": "30-45 minutos"
        },
        {
          "title": "Contratar un fontanero profesional",
          "description":
              "Si los métodos anteriores no funcionan, la obstrucción podría estar más profunda en la tubería y requerir equipo especializado como un desatascador de serpiente o hidrojet.",
          "is_diy": false,
          "estimated_cost": "S/80-200",
          "required_time": "1-2 horas"
        }
      ],
      "service_categories": [
        "Fontanería",
        "Plomería",
        "Mantenimiento del hogar"
      ],
      "urgency_level": "Medium",
      "difficulty_level": "Easy"
    };
  }
}
