import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/firebase_options.dart';

/// Migration script to add 'id' field to all existing questions in Firestore
/// Run this once to update existing questions
Future<void> main() async {
  print('Starting question ID migration...');
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;
  
  try {
    // Get all questions
    final questionsSnapshot = await firestore.collection('questions').get();
    
    print('Found ${questionsSnapshot.docs.length} questions to update');
    
    int updated = 0;
    int skipped = 0;
    
    // Update each question with its document ID
    for (var doc in questionsSnapshot.docs) {
      final data = doc.data();
      
      // Check if 'id' field already exists
      if (data.containsKey('id')) {
        print('Skipping ${doc.id} - already has id field');
        skipped++;
        continue;
      }
      
      // Add the 'id' field
      await doc.reference.update({
        'id': doc.id,
      });
      
      updated++;
      print('Updated ${doc.id} (${updated}/${questionsSnapshot.docs.length - skipped})');
    }
    
    print('\n✅ Migration complete!');
    print('Updated: $updated questions');
    print('Skipped: $skipped questions (already had id)');
    
  } catch (e) {
    print('❌ Error during migration: $e');
  }
}
