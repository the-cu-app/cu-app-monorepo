import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class ChatService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Get chat messages
  Future<List<Map<String, dynamic>>> getChatMessages({
    int limit = 50,
    int offset = 0,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final response = await _supabase
        .from(SupabaseConfig.chatMessagesTable)
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(response);
  }

  // Send message
  Future<Map<String, dynamic>> sendMessage({
    required String message,
    String? messageType = 'user', // 'user' or 'support'
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final chatMessage = {
      'user_id': user.id,
      'message': message,
      'message_type': messageType,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response = await _supabase
        .from(SupabaseConfig.chatMessagesTable)
        .insert(chatMessage)
        .select()
        .single();

    return response;
  }

  // Get real-time chat stream
  Stream<List<Map<String, dynamic>>> getChatStream() {
    final user = _supabase.auth.currentUser;
    if (user == null) return Stream.value([]);

    return _supabase
        .from(SupabaseConfig.chatMessagesTable)
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('created_at', ascending: true)
        .map((event) => event.map((row) => row).toList());
  }

  // Mark message as read
  Future<void> markMessageAsRead(String messageId) async {
    await _supabase.from(SupabaseConfig.chatMessagesTable).update({
      'read_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', messageId);
  }

  // Get unread message count
  Future<int> getUnreadMessageCount() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return 0;

    final response = await _supabase
        .from(SupabaseConfig.chatMessagesTable)
        .select('id')
        .eq('user_id', user.id)
        .eq('message_type', 'support');

    // Filter for unread messages (where read_at is null)
    final unreadMessages =
        response.where((row) => row['read_at'] == null).toList();
    return unreadMessages.length;
  }

  // Start new chat session
  Future<Map<String, dynamic>> startChatSession({
    String? initialMessage,
    String? category,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final session = {
      'user_id': user.id,
      'status': 'active',
      'category': category,
      'started_at': DateTime.now().toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response =
        await _supabase.from('chat_sessions').insert(session).select().single();

    // Send initial message if provided
    if (initialMessage != null) {
      await sendMessage(message: initialMessage);
    }

    return response;
  }

  // End chat session
  Future<void> endChatSession(String sessionId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase
        .from('chat_sessions')
        .update({
          'status': 'ended',
          'ended_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', sessionId)
        .eq('user_id', user.id);
  }

  // Get chat session history
  Future<List<Map<String, dynamic>>> getChatSessions() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final response = await _supabase
        .from('chat_sessions')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // Get active chat session
  Future<Map<String, dynamic>?> getActiveChatSession() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('chat_sessions')
        .select()
        .eq('user_id', user.id)
        .eq('status', 'active')
        .maybeSingle();

    return response;
  }

  // Send support request
  Future<void> sendSupportRequest({
    required String subject,
    required String message,
    String? priority = 'normal', // 'low', 'normal', 'high', 'urgent'
    String? category,
    List<String>? attachments,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final supportRequest = {
      'user_id': user.id,
      'subject': subject,
      'message': message,
      'priority': priority,
      'category': category,
      'attachments': attachments,
      'status': 'open',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _supabase.from('support_requests').insert(supportRequest);
  }

  // Get support request status
  Future<Map<String, dynamic>?> getSupportRequestStatus(
      String requestId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('support_requests')
        .select()
        .eq('id', requestId)
        .eq('user_id', user.id)
        .maybeSingle();

    return response;
  }

  // Get FAQ categories
  Future<List<String>> getFAQCategories() async {
    final response =
        await _supabase.from('faq_categories').select('name').order('name');

    return response.map((row) => row['name'] as String).toList();
  }

  // Search FAQ
  Future<List<Map<String, dynamic>>> searchFAQ(String query) async {
    if (query.isEmpty) return [];

    final response = await _supabase
        .from('faqs')
        .select()
        .or('question.ilike.%$query%,answer.ilike.%$query%')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // Get FAQ by category
  Future<List<Map<String, dynamic>>> getFAQByCategory(String category) async {
    final response = await _supabase
        .from('faqs')
        .select()
        .eq('category', category)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // Rate chat session
  Future<void> rateChatSession({
    required String sessionId,
    required int rating, // 1-5 stars
    String? feedback,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase.from('chat_ratings').insert({
      'user_id': user.id,
      'session_id': sessionId,
      'rating': rating,
      'feedback': feedback,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Get chat analytics
  Future<Map<String, dynamic>> getChatAnalytics() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return {};

    final sessions = await getChatSessions();
    final messages = await getChatMessages(limit: 1000);

    int totalSessions = sessions.length;
    int totalMessages = messages.length;
    int supportMessages =
        messages.where((m) => m['message_type'] == 'support').length;
    int userMessages =
        messages.where((m) => m['message_type'] == 'user').length;

    // Calculate average response time
    double totalResponseTime = 0;
    int responseCount = 0;

    for (int i = 0; i < messages.length - 1; i++) {
      if (messages[i]['message_type'] == 'user' &&
          messages[i + 1]['message_type'] == 'support') {
        final userTime = DateTime.parse(messages[i]['created_at']);
        final supportTime = DateTime.parse(messages[i + 1]['created_at']);
        totalResponseTime +=
            supportTime.difference(userTime).inSeconds.toDouble();
        responseCount++;
      }
    }

    final avgResponseTime =
        responseCount > 0 ? totalResponseTime / responseCount : 0;

    return {
      'total_sessions': totalSessions,
      'total_messages': totalMessages,
      'support_messages': supportMessages,
      'user_messages': userMessages,
      'average_response_time_seconds': avgResponseTime,
      'response_count': responseCount,
    };
  }
}
