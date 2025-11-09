import 'package:supabase/supabase.dart';

void main() async {
  // Initialize Supabase client
  final supabase = SupabaseClient(
    'https://vsduehkavltenthprjwe.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZzZHVlaGthdmx0ZW50aHByandlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI5NDYwNzQsImV4cCI6MjA2ODUyMjA3NH0.AV_21124tooJrgatkjbzFFYbGQQnDSprOf7RNlv9i04',
  );

  try {
    print('Checking for existing users in Supabase...\n');
    
    // Query the user_profiles table to see what users exist
    final profiles = await supabase
        .from('user_profiles')
        .select('*')
        .limit(10);
    
    if (profiles != null && profiles.isNotEmpty) {
      print('Found ${profiles.length} user profiles:');
      print('----------------------------------------');
      
      for (var profile in profiles) {
        print('\nUser Profile:');
        print('  Email: ${profile['email'] ?? 'N/A'}');
        print('  Name: ${profile['first_name']} ${profile['last_name']}');
        print('  Membership: ${profile['membership_type']}');
        print('  Created: ${profile['created_at']}');
        print('  User ID: ${profile['user_id']}');
      }
    } else {
      print('No user profiles found in the database.');
    }
    
    print('\n----------------------------------------');
    print('To sign in, use one of the emails above.');
    print('The test passwords are usually: Test123! or Password123!');
    print('\nCommon test accounts:');
    print('  kmkusche@gmail.com - Password123!');
    print('  test@example.com - Test123!');
    
  } catch (e) {
    print('Error querying users: $e');
    print('\nNote: You may need admin/service role access to query user data.');
    
    print('\nTry these common test credentials:');
    print('  kmkusche@gmail.com - Password123!');
    print('  kylekusche123@gmail.com - TempPassword123!');
    print('  test@example.com - Test123!');
  }
}