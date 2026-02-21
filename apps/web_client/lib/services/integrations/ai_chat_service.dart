import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/sale.dart';

class AiChatService {
  final String? _apiKey;
  final String? _apiEndpoint;

  AiChatService({String? apiKey, String? apiEndpoint})
    : _apiKey = apiKey ?? dotenv.env['AI_CHAT_API_KEY'],
      _apiEndpoint = apiEndpoint ?? dotenv.env['AI_CHAT_API_ENDPOINT'];

  /// Send user message to AI and get response
  Future<String> sendMessage(String message, {String? context}) async {
    // Placeholder for actual AI service call (e.g. OpenAI, Vertex AI)
    await Future.delayed(const Duration(seconds: 1)); // Simulate network

    if (message.toLowerCase().contains('sales')) {
      return "Based on your recent sales data, you've made \$1,250 today from 15 orders.";
    } else if (message.toLowerCase().contains('stock')) {
      return "You are running low on 'Organic Milk'. Current stock: 2 units.";
    }

    return "I can help you with sales insights, inventory status, and customer trends. Ask me anything!";
  }

  /// Analyze a sale and provide insights
  Future<String> analyzeSale(Sale sale) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return "This sale includes high-margin items. Consistent sales of this product bundle could increase weekly profit by 15%.";
  }
}
