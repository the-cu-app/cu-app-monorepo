import 'package:supabase/supabase.dart';

void main() async {
  // Initialize Supabase client
  final supabase = SupabaseClient(
    'https://vsduehkavltenthprjwe.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZzZHVlaGthdmx0ZW50aHByandlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI5NDYwNzQsImV4cCI6MjA2ODUyMjA3NH0.AV_21124tooJrgatkjbzFFYbGQQnDSprOf7RNlv9i04',
  );

  try {
    // Create user with email and password
    final response = await supabase.auth.signUp(
      email: 'kylekusche123@gmail.com',
      password: 'TempPassword123!', // Change this password after first login
      data: {
        'first_name': 'Kyle',
        'last_name': 'Kusche',
        'phone_number': '555-0123', // Update with actual phone if needed
      },
    );

    if (response.user != null) {
      print('User created successfully!');
      print('User ID: ${response.user!.id}');
      print('Email: ${response.user!.email}');
      
      // The database trigger will automatically create the profile
      // It will be a personal (general) membership by default
      
      print('\nIMPORTANT: Please change your password after first login!');
      print('Temporary password: TempPassword123!');
    } else {
      print('Failed to create user');
    }
  } catch (e) {
    print('Error creating user: $e');
    if (e.toString().contains('User already registered')) {
      print('\nThis email is already registered. You can sign in with it.');
    }
  }
}