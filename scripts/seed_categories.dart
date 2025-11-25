import 'dart:io';
import 'package:supabase/supabase.dart';

// NOTE: Run this script from the project root using:
// dart scripts/seed_categories.dart

Future<void> main() async {
  print('🚀 Starting Category Seeding...');

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

  // 2. Initialize Supabase
  final supabase = SupabaseClient(supabaseUrl, supabaseKey);

  // 3. Define Categories Data
  final List<Map<String, dynamic>> categoriesData = [
    {
        'id': 'general_knowledge',
        'name_ar': 'معرفة عامة',
        'name_en': 'General Knowledge',
        'icon_name': 'lightbulb',
        'color': '#6366F1',  // Indigo
        'order': 1
    },
    {
        'id': 'science',
        'name_ar': 'علوم',
        'name_en': 'Science',
        'icon_name': 'science',
        'color': '#10B981',  // Green
        'order': 2
    },
    {
        'id': 'geography',
        'name_ar': 'جغرافيا',
        'name_en': 'Geography',
        'icon_name': 'public',
        'color': '#3B82F6',  // Blue
        'order': 3
    },
    {
        'id': 'history_religion',
        'name_ar': 'تاريخ ودين',
        'name_en': 'History & Religion',
        'icon_name': 'history_edu',
        'color': '#F59E0B',  // Amber
        'order': 4
    },
    {
        'id': 'tech',
        'name_ar': 'تقنية',
        'name_en': 'Tech',
        'icon_name': 'computer',
        'color': '#EF4444',  // Red
        'order': 5
    },
    {
        'id': 'culture',
        'name_ar': 'ثقافة',
        'name_en': 'Culture',
        'icon_name': 'theater_comedy',
        'color': '#8B5CF6',  // Purple
        'order': 6
    },
    {
        'id': 'food_cooking',
        'name_ar': 'طعام ومطابخ',
        'name_en': 'Food & Cooking',
        'icon_name': 'restaurant',
        'color': '#F97316',
        'order': 7
    },
    {
        'id': 'cars_vehicles',
        'name_ar': 'سيارات ومركبات',
        'name_en': 'Cars & Vehicles',
        'icon_name': 'directions_car',
        'color': '#4B5563',
        'order': 8
    },
    {
        'id': 'logos',
        'name_ar': 'شعارات',
        'name_en': 'Logos',
        'icon_name': 'verified',
        'color': '#3B82F6',
        'order': 9
    },
    {
        'id': 'world_flags',
        'name_ar': 'أعلام دول',
        'name_en': 'World Flags',
        'icon_name': 'flag',
        'color': '#3B82F6',
        'order': 10
    },
    {
        'id': 'capitals_cities',
        'name_ar': 'عواصم ومدن',
        'name_en': 'Capitals & Cities',
        'icon_name': 'location_city',
        'color': '#CA8A04',
        'order': 11
    },
    {
        'id': 'proverbs',
        'name_ar': 'أمثال وحكم',
        'name_en': 'Proverbs & Sayings',
        'icon_name': 'format_quote',
        'color': '#DB2777',
        'order': 12
    },
    {
        'id': 'numbers_stats',
        'name_ar': 'أرقام وإحصائيات',
        'name_en': 'Numbers & Stats',
        'icon_name': 'calculate',
        'color': '#FBBF24',
        'order': 13
    },
    {
        'id': 'foreign_movies',
        'name_ar': 'أفلام أجنبية',
        'name_en': 'Foreign Movies',
        'icon_name': 'movie',
        'color': '#D946EF',
        'order': 14
    },
    {
        'id': 'foreign_series',
        'name_ar': 'مسلسلات أجنبية',
        'name_en': 'Foreign TV Series',
        'icon_name': 'live_tv',
        'color': '#D946EF',
        'order': 15
    },
    {
        'id': 'anime',
        'name_ar': 'أنمي',
        'name_en': 'Anime',
        'icon_name': 'animation',
        'color': '#F9A8D4',
        'order': 16
    },
    {
        'id': 'video_games',
        'name_ar': 'ألعاب فيديو',
        'name_en': 'Video Games',
        'icon_name': 'sports_esports',
        'color': '#A78BFA',
        'order': 17
    },
    {
        'id': 'sports',
        'name_ar': 'رياضة',
        'name_en': 'Sports',
        'icon_name': 'sports_soccer',
        'color': '#10B981', // Adjusted color to be distinct
        'order': 18
    }
  ];

  print('📦 Seeding ${categoriesData.length} categories...');

  for (var category in categoriesData) {
    try {
      await supabase.from('categories').upsert(category);
      print('   ✅ Upserted: ${category['id']}');
    } catch (e) {
      print('   ❌ Error upserting ${category['id']}: $e');
    }
  }

  print('\n🎉 Category Seeding Complete!');
}
