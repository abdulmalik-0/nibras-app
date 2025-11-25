import 'dart:convert';
import 'dart:io';
import 'package:supabase/supabase.dart';

// NOTE: Run this script from the project root using:
// dart scripts/migrate_from_json.dart

Future<void> main() async {
  print('🚀 Starting migration from JSON...');

  // 1. Load Environment Variables
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    print('❌ Error: .env file not found in project root.');
    return;
  }
  
  final envLines = await envFile.readAsLines();
  final envVars = <String, String>{};
  for (var line in envLines) {
    if (line.contains('=')) {
      final parts = line.split('=');
      envVars[parts[0].trim()] = parts[1].trim();
    }
  }

  final supabaseUrl = envVars['SUPABASE_URL'];
  final supabaseKey = envVars['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseKey == null) {
    print('❌ Error: SUPABASE_URL or SUPABASE_ANON_KEY not found in .env');
    return;
  }

  // 2. Initialize Supabase (Pure Dart Client)
  final supabase = SupabaseClient(supabaseUrl, supabaseKey);

  // 3. Read JSON File
  final jsonFile = File('assets/data/questions.json');
  if (!jsonFile.existsSync()) {
    print('❌ Error: assets/data/questions.json not found.');
    return;
  }

  final jsonString = await jsonFile.readAsString();
  final List<dynamic> questionsData = json.decode(jsonString);

  print('📦 Found ${questionsData.length} questions in JSON.');

  // 4. Process Categories
  // Extract unique categories from the JSON, handling the sports_tech split
  final Set<String> categories = {};
  
  // Pre-process questions to update categories
  for (var q in questionsData) {
    String category = q['category'];
    
    // Handle split of sports_tech - REMOVED per user request
    // if (category == 'sports_tech') {
    //   category = _classifySportsTech(q['question']);
    //   q['category'] = category; 
    // }
    
    if (category != null) {
      categories.add(category);
    }
  }

  print('📂 Found ${categories.length} unique categories: $categories');

  // Insert categories if they don't exist
  for (var categoryId in categories) {
    try {
      // Check if category exists
      final existing = await supabase
          .from('categories')
          .select()
          .eq('id', categoryId)
          .maybeSingle();

      if (existing == null) {
        print('   ➕ Creating category: $categoryId');
        // Map category ID to a readable name (Arabic)
        String nameAr = _getCategoryNameAr(categoryId);
        
        await supabase.from('categories').insert({
          'id': categoryId,
          'name_ar': nameAr,
          'name_en': categoryId.replaceAll('_', ' '), // Simple fallback
          'icon_name': _getCategoryIcon(categoryId),
        });
      } else {
        print('   ✅ Category $categoryId already exists.');
      }
    } catch (e) {
      print('   ❌ Error processing category $categoryId: $e');
    }
  }

  // 5. Insert Questions
  // print('\n🧹 Clearing existing questions...');
  // Skipped because user manually truncated table
  
  int successCount = 0;
  int errorCount = 0;
  int skippedCount = 0;

  print('\n📝 Inserting questions...');

  // Process in batches to avoid rate limits or timeouts
  final int batchSize = 50;
  for (var i = 0; i < questionsData.length; i += batchSize) {
    final end = (i + batchSize < questionsData.length) ? i + batchSize : questionsData.length;
    final batch = questionsData.sublist(i, end);
    
    print('   Processing batch ${i ~/ batchSize + 1} (${i + 1} to $end)...');

    for (var q in batch) {
      try {
        // Check if question already exists (by question text to avoid duplicates)
        final existing = await supabase
            .from('questions')
            .select('id')
            .eq('question', q['question'])
            .maybeSingle();

        if (existing != null) {
          skippedCount++;
          continue;
        }

        // Prepare question data
        final questionData = {
          'category_id': q['category'], // This is now updated (e.g. 'tech' or 'sports')
          'difficulty': q['difficulty'] ?? 'medium',
          'question': q['question'],
          'correct_answer': q['correctAnswer'],
          'options': q['options'], // Supabase handles List<String> as JSONB/Array
          'language': q['language'] ?? 'ar',
          'created_at': DateTime.now().toIso8601String(),
        };

        await supabase.from('questions').insert(questionData);
        successCount++;
      } catch (e) {
        print('   ❌ Error inserting question: "${q['question'].toString().substring(0, 20)}...": $e');
        errorCount++;
      }
    }
    
    // Small delay between batches
    await Future.delayed(const Duration(milliseconds: 500));
  }

  print('\n🎉 Migration Complete!');
  print('   ✅ Imported: $successCount');
  print('   ⏭️ Skipped (Duplicate): $skippedCount');
  print('   ❌ Failed: $errorCount');
}

// Helper to get Arabic names for categories
String _getCategoryNameAr(String id) {
  const names = {
    'general_knowledge': 'ثقافة عامة',
    'science': 'علوم',
    'geography': 'جغرافيا',
    'history_religion': 'تاريخ وديانات',
    'sports_tech': 'رياضة وتقنية', // Kept just in case
    'tech': 'تقنية',
    'sports': 'رياضة',
    'culture': 'ثقافة',
    'food_cooking': 'طعام ومطابخ',
    'cars_vehicles': 'سيارات ومركبات',
    'logos': 'شعارات',
    'world_flags': 'أعلام دول',
    'capitals_cities': 'عواصم ومدن',
    'proverbs': 'أمثال وحكم',
    'numbers_stats': 'أرقام وإحصائيات',
    'foreign_movies': 'أفلام أجنبية',
    'foreign_series': 'مسلسلات أجنبية',
    'anime': 'أنمي',
    'video_games': 'ألعاب فيديو',
  };
  return names[id] ?? id;
}

// Helper to get icons for categories
String _getCategoryIcon(String id) {
  const icons = {
    'general_knowledge': 'school',
    'science': 'science',
    'geography': 'public',
    'history_religion': 'history_edu',
    'sports_tech': 'sports_esports',
    'tech': 'computer',
    'sports': 'sports_soccer',
    'culture': 'palette',
    'food_cooking': 'restaurant',
    'cars_vehicles': 'directions_car',
    'logos': 'verified',
    'world_flags': 'flag',
    'capitals_cities': 'location_city',
    'proverbs': 'format_quote',
    'numbers_stats': 'analytics',
    'foreign_movies': 'movie',
    'foreign_series': 'tv',
    'anime': 'animation',
    'video_games': 'sports_esports',
  };
  return icons[id] ?? 'category';
}
