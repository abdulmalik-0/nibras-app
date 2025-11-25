// Simple migration script to add 'id' field to all questions
// Run with: dart run scripts/simple_migrate.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  print('🚀 Starting question ID migration...\n');
  
  try {
    // Initialize Firebase with manual configuration
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'YOUR_API_KEY', // Replace from firebase_options.dart
        appId: 'YOUR_APP_ID',
        messagingSenderId: 'YOUR_SENDER_ID',
        projectId: 'YOUR_PROJECT_ID',
      ),
    );

    final firestore = FirebaseFirestore.instance;
    
    // Get all questions
    print('📥 Fetching all questions...');
    final questionsSnapshot = await firestore.collection('questions').get();
    
    print('Found ${questionsSnapshot.docs.length} questions\n');
    
    int updated = 0;
    int skipped = 0;
    int errors = 0;
    
    // Update each question
    for (var doc in questionsSnapshot.docs) {
      try {
        final data = doc.data();
        
        // Skip if already has id
        if (data.containsKey('id') && data['id'] == doc.id) {
          skipped++;
          continue;
        }
        
        // Add the id field
        await doc.reference.update({'id': doc.id});
        updated++;
        
        // Progress indicator
        if (updated % 10 == 0) {
          print('✓ Updated $updated questions...');
        }
        
      } catch (e) {
        errors++;
        print('❌ Error updating ${doc.id}: $e');
      }
    }
    
    print('\n' + '=' * 50);
    print('✅ Migration Complete!');
    print('=' * 50);
    print('Updated: $updated questions');
    print('Skipped: $skipped questions (already had id)');
    print('Errors:  $errors questions');
    print('=' * 50);
    
  } catch (e) {
    print('❌ Fatal error: $e');
    exit(1);
  }
  
  exit(0);
}
