import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:edu_att/supabase/clean_http_client.dart';

class SupabaseConfig {
  static Future<void> init() async {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      httpClient: CleanHttpClient(),
    );
    print("супик инициилизируется");
  }
}
