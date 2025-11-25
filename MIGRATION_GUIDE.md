# Supabase Migration Guide

## Step 1: Create Supabase Project

1. Go to [https://supabase.com](https://supabase.com)
2. Sign up / Log in
3. Click "New Project"
4. Fill in:
   - **Name**: Nibras Quiz App
   - **Database Password**: (choose a strong password)
   - **Region**: Choose closest to your users
5. Click "Create new project"
6. Wait for project to be ready (~2 minutes)

## Step 2: Get Your Credentials

1. In your Supabase project, go to **Settings** → **API**
2. Copy these values:
   - **Project URL** (looks like: `https://xxxxx.supabase.co`)
   - **anon public** key (long JWT token)
3. Create `.env` file in project root:
   ```
   SUPABASE_URL=https://xxxxx.supabase.co
   SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   ```

## Step 3: Run SQL Schema

1. In Supabase dashboard, go to **SQL Editor**
2. Click "New query"
3. Copy entire content from `supabase/schema.sql`
4. Paste and click "Run"
5. Verify tables created: Go to **Table Editor**

## Step 4: Configure Authentication

1. Go to **Authentication** → **Providers**
2. Enable **Email** provider
3. Configure email templates (optional)
4. Set **Site URL** to your app URL

## Step 5: Update Flutter App

Run in terminal:
```bash
flutter pub get
```

## Step 6: Initialize Supabase in main.dart

The code will be updated to initialize Supabase instead of Firebase.

## Step 7: Test Connection

After running the app, test:
- Sign up new user
- Check if user appears in Supabase **Table Editor** → **users**

## Next Steps

After setup is complete, we'll:
1. Rewrite `SupabaseService` (replaces `FirestoreService`)
2. Update `AuthService` to use Supabase Auth
3. Migrate existing data from Firebase
4. Update all UI screens
5. Test thoroughly
6. Deploy to Vercel/Netlify

## Troubleshooting

**Error: "Invalid API key"**
- Double-check `.env` file has correct `SUPABASE_URL` and `SUPABASE_ANON_KEY`

**Error: "RLS policy violation"**
- Make sure you ran the entire `schema.sql` script
- Check RLS policies in **Authentication** → **Policies**

**Can't see tables**
- Refresh Supabase dashboard
- Check SQL Editor for any errors

## Need Help?

Let me know which step you're on and I'll guide you through!
