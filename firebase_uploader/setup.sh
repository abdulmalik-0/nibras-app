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
           service_account_path: مسار ملف Se#!/bin/bash
# setup.sh - سكريبت للإعداد السريع لمشروع Nibras Firebase Uploader

echo "✨ بدء إعداد مشروع Nibras Firebase Uploader..."
echo ""

# 1. إنشاء بيئة افتراضية
echo "1️⃣  إنشاء بيئة افتراضية Python..."
python3 -m venv venv

if [ $? -eq 0 ]; then
   echo "   ✅ تم إنشاء البيئة الافتراضية بنجاح"
else
   echo "   ❌ فشل إنشاء البيئة الافتراضية"
   exit 1
fi

echo ""

# 2. تفعيل البيئة الافتراضية
echo "2️⃣  تفعيل البيئة الافتراضية..."
source venv/bin/activate
echo "   ✅ تم تفعيل البيئة"
echo ""

# 3. تحديث pip
echo "3️⃣  تحديث pip..."
pip install --upgrade pip
echo ""

# 4. تثبيت المكتبات
echo "4️⃣  تثبيت المكتبات المطلوبة..."
pip install -r requirements.txt

if [ $? -eq 0 ]; then
   echo "   ✅ تم تثبيت جميع المكتبات بنجاح"
else
   echo "   ❌ فشل تثبيت المكتبات"
   exit 1
fi

echo ""
echo "✅ تم الإعداد بنجاح!"
echo ""
echo "📝 الخطوات المتبقية:"
echo "1. ضع ملف serviceAccountKey.json في نفس المجلد"
echo "2. عدّل ملف questions.json بأسئلتك"
echo "3. شغّل السكريبت: python upload_to_firebase.py"
echo ""
echo "🔒 لا تنسى إضافة serviceAccountKey.json إلى .gitignore!"
echo ""# requirements.txt
# المكتبات المطلوبة لمشروع Nibras Quiz - Firebase Uploader

# Firebase Admin SDK
firebase-admin>=6.5.0

# تأتي تلقائياً مع Python
# json (built-in)
# datetime (built-in)rvice Account JSON
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