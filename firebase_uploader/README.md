# سكريبت Python لرفع الأسئلة إلى Firebase Firestore
# upload_to_firebase.py

import firebase_admin
from firebase_admin import credentials, firestore
import json
from datetime import datetime

class FirestoreUploader:
   def __init__(self, service_account_path, collection_name):
       """
       تهيئة الاتصال بـ Firebase
       
       Args:
           service_account_path: مسار ملف Se# QUICKSTART.md
# دليل البدء السريع - Nibras Firebase Uploader

## تثبيت سريع (5 دقائق)

### للمستخدمين Linux/Mac:

```bash
# 1. تنفيذ سكريبت الإعداد
chmod +x setup.sh
./setup.sh
```

### للمستخدمين Windows:

```bash
# 1. إنشاء بيئة افتراضية
python -m venv venv

# 2. تفعيل البيئة
venv\Scripts\activate

# 3. تثبيت المكتبات
pip install -r requirements.txt
```

## الحصول على Service Account Key

1. افتح Firebase Console: https://console.firebase.google.com/project/nibras-y65gfc
2. اضغط على أيقونة الإعدادات ⛙️ > **Project settings**
3. اذهب لتبويب **Service accounts**
4. اضغط **Generate new private key** > **Generate Key**
5. احفظ الملف باسم `serviceAccountKey.json` في مجلد المشروع

## الاستخدام

```bash
# تفعيل البيئة الافتراضية
source venv/bin/activate  # Linux/Mac
venv\Scripts\activate     # Windows

# رفع الأسئلة
upload_questionspy

# رفع الفئات
python Upload_categories.py
```

## هيكل الملفات

```
firebase_uploader/
├── upload_to_firebase.py    # السكريبت الرئيسي
├── simple_upload.py         # نسخة مبسطة
├── questions.json            # ملف الأسئلة
├── serviceAccountKey.json   # مفتاح Firebase (لا ترفعه على GitHub!)
├── requirements.txt         # المكتبات المطلوبة
├── .gitignore               # حماية الملفات الحساسة
├── setup.sh                 # سكريبت الإعداد (Linux/Mac)
├── README.md                # دليل كامل
└── QUICKSTART.md            # هذا الملف
```

## مثال على questions.json

```json
[
 {
   "category": "general_knowledge",
   "correctAnswer": "باريس",
   "language": "ar",
   "options": ["باريس", "لندن", "برلين", "مدريد"],
   "question": "ما هي عاصمة فرنسا؟"
 }
]
```

## الأخطاء الشائعة

### خطأ: ملف serviceAccountKey.json غير موجود
تأكد من وضع الملف في نفس مجلد السكريبت

### خطأ: firebase-admin غير مثبت
```bash
pip install firebase-admin
```

### خطأ: JSON decode error
تأكد من صحة صيغة JSON في questions.json

## دعم

للمزيد من التفاصيل، ارجع إلى README.md# .gitignore
# ملف لحماية البيانات الحساسة في مشروع Nibras

# Firebase Service Account Key - مهم جداً!
serviceAccountKey.json
*-firebase-adminsdk-*.json
firebase-credentials.json

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# Virtual Environment
venv/
ENV/
env/
.venv

# IDE
.vscode/
.idea/
*.swp
*.swo
*~
.DS_Store

# Logs
*.log
logs/

# Testing
.pytest_cache/
.coverage
htmlcov/

# Environment Variables
.env
.env.local

# Backup files
*.bak
*.backuprvice Account JSON
           collection_name: اسم الـ Collection في Firestore
       """
       # تهيئة Firebase Admin SDK
       cred = credentials.Certificate(service_account_path)
       firebase_admin.initialize_app(cred)
       
       # الحصول على مرجع Firestore
       self.db = firestore.client()
       self.collection_name = collection_name
   
   def upload_questions(self, json_file_path, batch_size=500):
       """
       رفع الأسئلة من ملف JSON إلى Firestore
       
       Args:
           json_file_path: مسار ملف JSON
           batch_size: عدد المستندات في كل دفعة (أقصى حد 500)
       """
       try:
           # قراءة ملف JSON
           with open(json_file_path, 'r', encoding='utf-8') as f:
               questions = json.load(f)
           
           print(f"تم قراءة {len(questions)} سؤال من الملف")
           
           # رفع الأسئلة على دفعات
           total_uploaded = 0
           batch = self.db.batch()
           batch_count = 0
           
           for index, question in enumerate(questions):
               # إنشاء مرجع للمستند (يمكنك استخدام ID محدد أو تلقائي)
               if 'id' in question:
                   doc_ref = self.db.collection(self.collection_name).document(question['id'])
                   del question['id']  # حذف الـ ID من البيانات
               else:
                   doc_ref = self.db.collection(self.collection_name).document()
               
               # إضافة المستند إلى الدفعة
               batch.set(doc_ref, question)
               batch_count += 1
               
               # إذا وصلنا لحد الدفعة، نرفعها
               if batch_count >= batch_size:
                   batch.commit()
                   total_uploaded += batch_count
                   print(f"تم رفع {total_uploaded} سؤال...")
                   
                   # بدء دفعة جديدة
                   batch = self.db.batch()
                   batch_count = 0
           
           # رفع الدفعة الأخيرة
           if batch_count > 0:
               batch.commit()
               total_uploaded += batch_count
           
           print(f"\n✅ تم رفع {total_uploaded} سؤال بنجاح إلى {self.collection_name}")
           return True
           
       except FileNotFoundError:
           print(f"❌ خطأ: لم يتم العثور على الملف {json_file_path}")
           return False
       except json.JSONDecodeError:
           print(f"❌ خطأ: الملف ليس بصيغة JSON صحيحة")
           return False
       except Exception as e:
           print(f"❌ خطأ: {str(e)}")
           return False
   
   def upload_single_question(self, question_data):
       """
       رفع سؤال واحد إلى Firestore
       
       Args:
           question_data: بيانات السؤال (dict)
       """
       try:
           doc_ref = self.db.collection(self.collection_name).document()
           doc_ref.set(question_data)
           print(f"✅ تم رفع السؤال بنجاح: {doc_ref.id}")
           return doc_ref.id
       except Exception as e:
           print(f"❌ خطأ في رفع السؤال: {str(e)}")
           return None


if __name__ == "__main__":
   # إعدادات المشروع
   SERVICE_ACCOUNT_PATH = "serviceAccountKey.json"  # ضع مسار ملف Service Account
   COLLECTION_NAME = "questions"
   JSON_FILE_PATH = "questions.json"
   
   # إنشاء مثيل من الرافع
   uploader = FirestoreUploader(SERVICE_ACCOUNT_PATH, COLLECTION_NAME)
   
   # رفع الأسئلة
   uploader.upload_questions(JSON_FILE_PATH)