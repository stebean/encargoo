import 'dart:io';
import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient('YOUR_SUPABASE_URL', 'YOUR_SUPABASE_ANON_KEY');
  
  // We don't have user password so we can't easily query with auth.
  // Wait, without auth we will hit RLS and get 0 rows!
  
  print("done");
}
