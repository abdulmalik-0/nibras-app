import psycopg2
from psycopg2 import sql

# 🔑 معلومات اتصال قاعدة البيانات (PostgreSQL)
# يمكنك الحصول على هذه المعلومات من إعدادات مشروع Supabase الخاص بك
DB_HOST = "hfjvtwvmcjucbxdxnhptv.supabase.co" # (مثال: xxxxxxxxx.supabase.co)
DB_NAME = "postgres" # عادةً يكون اسم قاعدة البيانات هو 'postgres'
DB_USER = "abdulmalik-0's Project" # اسم المستخدم الافتراضي
DB_PASSWORD = "hS2ogfB76e5HagtQ" # كلمة مرور قاعدة البيانات (مختلفة عن مفاتيح API)
DB_PORT = "5432"

TABLE_NAME = "categories"

# البيانات المراد إدراجها
categories_data = [
    {
        'id': 'general_knowledge',
        'nameAr': 'معرفة عامة',
        'nameEn': 'General Knowledge',
        'icon': 'lightbulb',
        'color': '#6366F1', 
        'order': 1
    },
    {
        'id': 'science',
        'nameAr': 'علوم',
        'nameEn': 'Science',
        'icon': 'science',
        'color': '#10B981', 
        'order': 2
    },
    {
        'id': 'geography',
        'nameAr': 'جغرافيا',
        'nameEn': 'Geography',
        'icon': 'public',
        'color': '#3B82F6', 
        'order': 3
    },
    {
        'id': 'history_religion',
        'nameAr': 'تاريخ ودين',
        'nameEn': 'History & Religion',
        'icon': 'history_edu',
        'color': '#F59E0B', 
        'order': 4
    },
    {
        'id': 'sports_tech',
        'nameAr': 'رياضة وتقنية',
        'nameEn': 'Sports & Tech',
        'icon': 'sports_soccer',
        'color': '#EF4444', 
        'order': 5
    },
    {
        'id': 'culture',
        'nameAr': 'ثقافة',
        'nameEn': 'Culture',
        'icon': 'theater_comedy',
        'color': '#8B5CF6', 
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

# تعريف الأعمدة وأنواع البيانات المتوافقة مع البيانات أعلاه
COLUMNS_DEFINITION = [
    ("id", "VARCHAR(255)", "PRIMARY KEY"),
    ("nameAr", "TEXT", "NOT NULL"),
    ("nameEn", "TEXT", "NOT NULL"),
    ("icon", "VARCHAR(50)", "NULL"),
    ("color", "VARCHAR(10)", "NULL"),
    ("order_num", "INTEGER", "NOT NULL") # نستخدم order_num لتجنب التضارب مع كلمة 'ORDER' المحجوزة
]

def create_table_and_insert_data():
    conn = None
    try:
        # إنشاء سلسلة الاتصال
        connection_string = f"host={DB_HOST} dbname={DB_NAME} user={DB_USER} password={DB_PASSWORD} port={DB_PORT}"
        
        # 1. الاتصال بقاعدة البيانات
        conn = psycopg2.connect(connection_string)
        # لا نجعلها autocommit الآن، بل سنقوم بالتنفيذ يدوياً في النهاية
        cursor = conn.cursor()

        # --- أ. إنشاء الجدول ---
        print(f"⏳ جاري التحقق من جدول '{TABLE_NAME}' وإنشائه...")
        column_sqls = []
        for name, data_type, constraints in COLUMNS_DEFINITION:
            column_sqls.append(sql.SQL("{} {} {}").format(
                sql.Identifier(name),
                sql.SQL(data_type), 
                sql.SQL(constraints)
            ))
        
        columns_combined = sql.SQL(', ').join(column_sqls)
        create_table_command = sql.SQL(
            "CREATE TABLE IF NOT EXISTS {} ({})"
        ).format(
            sql.Identifier(TABLE_NAME),
            columns_combined
        )
        cursor.execute(create_table_command)
        print(f"✅ تم تجهيز الجدول '{TABLE_NAME}'.")
        
        # --- ب. إدراج البيانات ---
        print(f"⏳ جاري إدراج {len(categories_data)} سجل في الجدول...")

        # تجهيز البيانات للإدراج
        # يجب تعديل المفتاح 'order' ليصبح 'order_num' في البيانات ليتطابق مع اسم العمود في DB
        data_to_insert = []
        for item in categories_data:
            # ننشئ نسخة جديدة ونغير اسم المفتاح
            new_item = item.copy()
            new_item['order_num'] = new_item.pop('order')
            data_to_insert.append(new_item)

        # أسماء الأعمدة للإدراج
        columns = [col[0] for col in COLUMNS_DEFINITION]
        
        # استخدام execute_values لإدراج عدة صفوف بكفاءة عالية
        # يتم استخدام CONFLICT DO NOTHING لتجنب الأخطاء إذا كانت الـ id مكررة (Primary Key)
        insert_query = sql.SQL("""
            INSERT INTO {} ({}) VALUES %s
            ON CONFLICT (id) DO NOTHING;
        """).format(
            sql.Identifier(TABLE_NAME),
            sql.SQL(', ').join(map(sql.Identifier, columns))
        )
        
        # استخراج قيم الكائنات بترتيب الأعمدة
        values = [[item[col] for col in columns] for item in data_to_insert]
        
        extras.execute_values(cursor, insert_query, values, page_size=100)
        
        # 3. حفظ التغييرات
        conn.commit()

        print(f"🎉 تم إدراج {len(values)} سجل بنجاح في جدول '{TABLE_NAME}'.")

    except (Exception, psycopg2.Error) as error:
        print(f"❌ حدث خطأ أثناء العملية: {error}")
        if conn:
            conn.rollback() # التراجع عن أي تغييرات في حالة الخطأ

    finally:
        # 4. إغلاق الاتصال
        if conn:
            cursor.close()
            conn.close()
            print("✅ تم إغلاق الاتصال بقاعدة البيانات.")

# تنفيذ الدالة
create_table_and_insert_data()