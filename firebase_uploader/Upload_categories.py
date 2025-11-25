#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Nibras Quiz Game - Categories Setup Script
يضيف 6 فئات للعبة في Firestore
"""

import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore

# ============================================
# 1️⃣ Initialize Firebase
# ============================================
# ضع مسار ملف الـ Service Account Key هنا
cred = credentials.Certificate('serviceAccountKey.json')
firebase_admin.initialize_app(cred)

# الحصول على Firestore client
db = firestore.client()

# ============================================
# 2️⃣ تعريف الفئات الستة
# ============================================
categories_data = [
    {
        'id': 'general_knowledge',
        'nameAr': 'معرفة عامة',
        'nameEn': 'General Knowledge',
        'icon': 'lightbulb',
        'color': '#6366F1',  # Indigo
        'order': 1
    },
    {
        'id': 'science',
        'nameAr': 'علوم',
        'nameEn': 'Science',
        'icon': 'science',
        'color': '#10B981',  # Green
        'order': 2
    },
    {
        'id': 'geography',
        'nameAr': 'جغرافيا',
        'nameEn': 'Geography',
        'icon': 'public',
        'color': '#3B82F6',  # Blue
        'order': 3
    },
    {
        'id': 'history_religion',
        'nameAr': 'تاريخ ودين',
        'nameEn': 'History & Religion',
        'icon': 'history_edu',
        'color': '#F59E0B',  # Amber
        'order': 4
    },
    {
        'id': 'sports_tech',
        'nameAr': 'رياضة وتقنية',
        'nameEn': 'Sports & Tech',
        'icon': 'sports_soccer',
        'color': '#EF4444',  # Red
        'order': 5
    },
    {
        'id': 'culture',
        'nameAr': 'ثقافة',
        'nameEn': 'Culture',
        'icon': 'theater_comedy',
        'color': '#8B5CF6',  # Purple
        'order': 6
    },
  {
    "id": "food_cooking",
    "nameAr": "طعام ومطابخ",
    "nameEn": "Food & Cooking",
    "icon": "restaurant",
    "color": "#F97316",
    "order": 6
  },
  {
    "id": "cars_vehicles",
    "nameAr": "سيارات ومركبات",
    "nameEn": "Cars & Vehicles",
    "icon": "directions_car",
    "color": "#4B5563",
    "order": 7
  },
  {
    "id": "logos",
    "nameAr": "شعارات",
    "nameEn": "Logos",
    "icon": "star",
    "color": "#3B82F6",
    "order": 8
  },
  {
    "id": "world_flags",
    "nameAr": "أعلام دول",
    "nameEn": "World Flags",
    "icon": "flag",
    "color": "#3B82F6",
    "order": 9
  },
  {
    "id": "capitals_cities",
    "nameAr": "عواصم ومدن",
    "nameEn": "Capitals & Cities",
    "icon": "location_city",
    "color": "#CA8A04",
    "order": 10
  },
  {
    "id": "proverbs",
    "nameAr": "أمثال وحكم",
    "nameEn": "Proverbs & Sayings",
    "icon": "format_quote",
    "color": "#DB2777",
    "order": 11
  },
  {
    "id": "numbers_stats",
    "nameAr": "أرقام وإحصائيات",
    "nameEn": "Numbers & Stats",
    "icon": "calculate",
    "color": "#FBBF24",
    "order": 12
  },
  {
    "id": "foreign_movies",
    "nameAr": "أفلام أجنبية",
    "nameEn": "Foreign Movies",
    "icon": "movie",
    "color": "#D946EF",
    "order": 13
  },
  {
    "id": "foreign_series",
    "nameAr": "مسلسلات أجنبية",
    "nameEn": "Foreign TV Series",
    "icon": "live_tv",
    "color": "#D946EF",
    "order": 14
  },
  {
    "id": "anime",
    "nameAr": "أنمي",
    "nameEn": "Anime",
    "icon": "animation",
    "color": "#F9A8D4",
    "order": 15
  },
  {
    "id": "video_games",
    "nameAr": "ألعاب فيديو",
    "nameEn": "Video Games",
    "icon": "sports_esports",
    "color": "#A78BFA",
    "order": 16
  }
]

# ============================================
# 3️⃣ إضافة الفئات لـ Firestore
# ============================================
def add_categories():
    """
    يضيف جميع الفئات لـ categories collection في Firestore
    """
    print("🚀 بدء إضافة الفئات إلى Firestore...")
    print("=" * 50)
    
    categories_ref = db.collection('categories')
    success_count = 0
    
    for category in categories_data:
        category_id = category.pop('id')  # استخراج الـ ID
        
        try:
            # إضافة/تحديث الـ document
            categories_ref.document(category_id).set(category)
            print(f"✅ تم إضافة: {category['nameAr']} ({category_id})")
            success_count += 1
            
        except Exception as e:
            print(f"❌ خطأ في إضافة {category_id}: {str(e)}")
    
    print("=" * 50)
    print(f"✨ تم بنجاح! أضيفت {success_count} فئات من أصل {len(categories_data)}")
    print("\n📊 يمكنك الآن التحقق من Firebase Console")

# ============================================
# 4️⃣ التحقق من الفئات الموجودة
# ============================================
def verify_categories():
    """
    يتحقق من الفئات المضافة ويعرضها
    """
    print("\n🔍 التحقق من الفئات في Firestore...")
    print("=" * 50)
    
    categories_ref = db.collection('categories')
    docs = categories_ref.order_by('order').stream()
    
    count = 0
    for doc in docs:
        data = doc.to_dict()
        print(f"{data['order']}. {data['nameAr']} ({doc.id})")
        print(f"   Icon: {data['icon']}, Color: {data['color']}")
        count += 1
    
    print("=" * 50)
    print(f"📦 إجمالي الفئات: {count}")

# ============================================
# 5️⃣ حذف كل الفئات (للتنظيف إذا احتجت)
# ============================================
def delete_all_categories():
    """
    يحذف جميع الفئات - استخدم بحذر!
    """
    confirm = input("⚠️  هل أنت متأكد من حذف جميع الفئات؟ (yes/no): ")
    if confirm.lower() != 'yes':
        print("❌ تم الإلغاء")
        return
    
    print("🗑️  جاري حذف جميع الفئات...")
    categories_ref = db.collection('categories')
    docs = categories_ref.stream()
    
    deleted = 0
    for doc in docs:
        doc.reference.delete()
        deleted += 1
        print(f"   حُذفت: {doc.id}")
    
    print(f"✅ تم حذف {deleted} فئة")

# ============================================
# 6️⃣ تشغيل البرنامج
# ============================================
if __name__ == '__main__':
    print("=" * 50)
    print("  🎮 Nibras Quiz Game - Categories Setup  ")
    print("=" * 50)
    
    # إضافة الفئات
    add_categories()
    
    # التحقق من الإضافة
    verify_categories()
    
    print("\n✨ انتهى البرنامج بنجاح!")
    print("📱 يمكنك الآن استخدام الفئات في FlutterFlow")
