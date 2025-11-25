import 'dart:io';
import 'package:supabase/supabase.dart';

Future<void> main() async {
  print('🔍 Verifying data in Supabase...');

  // 1. Load Environment Variables
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    print('❌ .env file not found!');
    return;
  }

  final lines = await envFile.readAsLines();
  String supabaseUrl = '';
  String supabaseKey = '';

  for (var line in lines) {
    if (line.startsWith('SUPABASE_URL=')) {
      supabaseUrl = line.split('=')[1];
    } else if (line.startsWith('SUPABASE_ANON_KEY=')) {
      supabaseKey = line.split('=')[1];
    }
  }

  if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
    print('❌ Could not load Supabase credentials from .env');
    return;
  }

  final supabase = SupabaseClient(supabaseUrl, supabaseKey);

  // 2. Check Categories
  try {
    final categories = await supabase.from('categories').select();
    print('\n📂 Categories found: ${categories.length}');
    if (categories.isNotEmpty) {
      print('   Sample: ${categories.first['id']} (${categories.first['name_ar']})');
    }
  } catch (e) {
    print('❌ Error fetching categories: $e');
  }

  // 3. Check Questions
  try {
    final count = await supabase.from('questions').count(CountOption.exact);
    print('\n❓ Total Questions: $count');

    if (count > 0) {
      final questions = await supabase.from('questions').select().limit(5);
      print('   Sample Questions:');
      for (var q in questions) {
        print('   - [${q['category_id']}] ${q['question'].toString().substring(0, 20)}...');
      }
    } else {
      print('   ⚠️ No questions found! (RLS might be blocking or table is empty)');
    }
  } catch (e) {
    print('❌ Error fetching questions: $e');
  }
}
