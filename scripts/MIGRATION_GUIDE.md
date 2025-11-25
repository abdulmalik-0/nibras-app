# تحديث الأسئلة الموجودة - إضافة حقل ID

## الطريقة الأولى: من Firebase Console (الأسهل)

1. افتح [Firebase Console](https://console.firebase.google.com)
2. اختر مشروعك
3. اذهب إلى **Firestore Database**
4. افتح collection `questions`
5. لكل سؤال:
   - افتح الوثيقة
   - اضغط **Add field**
   - Field name: `id`
   - Field value: انسخ الـ Document ID والصقه
   - Save

## الطريقة الثانية: باستخدام Cloud Functions (للأسئلة الكثيرة)

إذا عندك أسئلة كثيرة، استخدم هذا الكود في Firebase Console > Firestore > Rules (مؤقتاً):

```javascript
// في Firebase Console > Functions
// أو في Cloud Shell

const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

async function migrateQuestionIds() {
  const questionsRef = db.collection('questions');
  const snapshot = await questionsRef.get();
  
  console.log(`Found ${snapshot.size} questions`);
  
  const batch = db.batch();
  let count = 0;
  
  snapshot.forEach(doc => {
    const data = doc.data();
    
    // Skip if already has id
    if (data.id === doc.id) {
      return;
    }
    
    // Add id field
    batch.update(doc.ref, { id: doc.id });
    count++;
    
    // Firestore batch limit is 500
    if (count === 500) {
      console.log('Batch limit reached, committing...');
      batch.commit();
      count = 0;
    }
  });
  
  if (count > 0) {
    await batch.commit();
  }
  
  console.log('✅ Migration complete!');
}

migrateQuestionIds();
```

## الطريقة الثالثة: من التطبيق نفسه (One-time admin function)

يمكنك إضافة زر مؤقت في صفحة الـ Admin لتشغيل هذا الكود:

```dart
Future<void> migrateQuestionIds() async {
  final firestore = FirebaseFirestore.instance;
  
  try {
    final snapshot = await firestore.collection('questions').get();
    
    print('Found ${snapshot.docs.length} questions');
    
    WriteBatch batch = firestore.batch();
    int count = 0;
    
    for (var doc in snapshot.docs) {
      final data = doc.data();
      
      // Skip if already has id
      if (data['id'] == doc.id) continue;
      
      batch.update(doc.reference, {'id': doc.id});
      count++;
      
      // Commit every 500 (Firestore limit)
      if (count == 500) {
        await batch.commit();
        batch = firestore.batch();
        count = 0;
      }
    }
    
    if (count > 0) {
      await batch.commit();
    }
    
    print('✅ Migration complete!');
  } catch (e) {
    print('Error: $e');
  }
}
```

## ملاحظات مهمة

- ✅ الكود الآن يدعم القراءة من حقل `id` في الوثيقة
- ✅ إذا ما كان موجود، يستخدم `doc.id` (backwards compatible)
- ✅ الأسئلة الجديدة تلقائياً تحفظ الـ `id`
- ⚠️ بعد التحديث، تأكد إن كل الأسئلة فيها حقل `id`

## التحقق من النجاح

بعد التحديث، تحقق من أي سؤال في Firestore:
- يجب أن يحتوي على حقل `id`
- قيمة الـ `id` = Document ID
