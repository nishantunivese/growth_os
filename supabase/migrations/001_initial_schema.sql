-- =====================================================================
-- GROWTH OS: PRODUCTION POSTGRESQL SCHEMA (SUPABASE)
-- Fully Normalized Schema with Row Level Security (RLS) & Triggers
-- =====================================================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. PROFILES TABLE (Extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL DEFAULT '',
    business_name TEXT DEFAULT '',
    avatar_url TEXT DEFAULT '',
    youtube_channel TEXT DEFAULT '',
    instagram_username TEXT DEFAULT '',
    telegram_channel TEXT DEFAULT '',
    monthly_earning_target NUMERIC(12, 2) DEFAULT 100000.00,
    annual_earning_target NUMERIC(14, 2) DEFAULT 1200000.00,
    primary_category TEXT DEFAULT 'Digital Creator',
    preferred_currency TEXT DEFAULT '₹',
    time_zone TEXT DEFAULT 'Asia/Kolkata',
    is_admin BOOLEAN DEFAULT FALSE,
    streak_count INTEGER DEFAULT 1,
    last_active_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. PROJECTS TABLE
CREATE TABLE IF NOT EXISTS public.projects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    category TEXT NOT NULL DEFAULT 'General',
    description TEXT DEFAULT '',
    start_date DATE DEFAULT CURRENT_DATE,
    deadline DATE,
    priority TEXT CHECK (priority IN ('low', 'medium', 'high', 'urgent')) DEFAULT 'medium',
    status TEXT CHECK (status IN ('active', 'paused', 'completed', 'cancelled')) DEFAULT 'active',
    expected_result TEXT DEFAULT '',
    progress_percentage INTEGER CHECK (progress_percentage BETWEEN 0 AND 100) DEFAULT 0,
    reminder_enabled BOOLEAN DEFAULT TRUE,
    reminder_interval_hours INTEGER DEFAULT 2,
    last_updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. PROJECT STAGES (Process Level System)
CREATE TABLE IF NOT EXISTS public.project_stages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    stage_order INTEGER NOT NULL DEFAULT 1,
    title TEXT NOT NULL,
    description TEXT DEFAULT '',
    is_completed BOOLEAN DEFAULT FALSE,
    weight INTEGER DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. PROJECT UPDATES (Chronological Journey & Timeline)
CREATE TABLE IF NOT EXISTS public.project_updates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    stage_id UUID REFERENCES public.project_stages(id) ON DELETE SET NULL,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    update_text TEXT NOT NULL,
    result_achieved TEXT DEFAULT '',
    problem_loss TEXT DEFAULT '',
    learning_notes TEXT DEFAULT '',
    earnings_recorded NUMERIC(12, 2) DEFAULT 0.00,
    losses_recorded NUMERIC(12, 2) DEFAULT 0.00,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. ATTACHMENTS (Multiple Screenshots per Update)
CREATE TABLE IF NOT EXISTS public.attachments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    update_id UUID REFERENCES public.project_updates(id) ON DELETE CASCADE,
    project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE,
    file_url TEXT NOT NULL,
    file_type TEXT DEFAULT 'image/png',
    file_size_bytes BIGINT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. VOICE NOTES
CREATE TABLE IF NOT EXISTS public.voice_notes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    update_id UUID REFERENCES public.project_updates(id) ON DELETE CASCADE,
    audio_url TEXT NOT NULL,
    duration_seconds INTEGER DEFAULT 0,
    transcription TEXT DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. FINANCIAL GOALS
CREATE TABLE IF NOT EXISTS public.financial_goals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    goal_type TEXT CHECK (goal_type IN ('daily', 'weekly', 'monthly', 'yearly', 'custom')) DEFAULT 'monthly',
    target_amount NUMERIC(12, 2) NOT NULL,
    current_amount NUMERIC(12, 2) DEFAULT 0.00,
    title TEXT NOT NULL,
    start_date DATE DEFAULT CURRENT_DATE,
    end_date DATE,
    is_completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. INCOME ENTRIES (Gross Revenue)
CREATE TABLE IF NOT EXISTS public.income_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    project_id UUID REFERENCES public.projects(id) ON DELETE SET NULL,
    amount NUMERIC(12, 2) NOT NULL,
    platform_source TEXT NOT NULL,
    category TEXT DEFAULT 'Sales',
    description TEXT DEFAULT '',
    payment_status TEXT CHECK (payment_status IN ('received', 'pending', 'held')) DEFAULT 'received',
    screenshot_url TEXT DEFAULT '',
    notes TEXT DEFAULT '',
    entry_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. EXPENSE ENTRIES (Expenses & Losses)
CREATE TABLE IF NOT EXISTS public.expense_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    project_id UUID REFERENCES public.projects(id) ON DELETE SET NULL,
    amount NUMERIC(12, 2) NOT NULL,
    category TEXT DEFAULT 'Software/Tools',
    description TEXT DEFAULT '',
    is_loss BOOLEAN DEFAULT FALSE,
    entry_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 10. CLIENTS & BRANDS (Mini CRM)
CREATE TABLE IF NOT EXISTS public.clients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    contact_person TEXT DEFAULT '',
    phone TEXT DEFAULT '',
    whatsapp_number TEXT DEFAULT '',
    email TEXT DEFAULT '',
    instagram_handle TEXT DEFAULT '',
    company_name TEXT DEFAULT '',
    deal_amount NUMERIC(12, 2) DEFAULT 0.00,
    lead_status TEXT CHECK (lead_status IN ('new', 'contacted', 'negotiation', 'confirmed', 'in_progress', 'completed', 'payment_pending', 'closed')) DEFAULT 'new',
    work_deadline DATE,
    follow_up_date DATE,
    notes TEXT DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 11. CLIENT INTERACTIONS
CREATE TABLE IF NOT EXISTS public.client_interactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID NOT NULL REFERENCES public.clients(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    interaction_type TEXT CHECK (interaction_type IN ('call', 'whatsapp', 'email', 'meeting', 'note')) DEFAULT 'note',
    summary TEXT NOT NULL,
    next_step TEXT DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 12. CONTENT CALENDAR (Creator Growth Feature 1)
CREATE TABLE IF NOT EXISTS public.content_calendar (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    platform TEXT CHECK (platform IN ('youtube', 'youtube_shorts', 'instagram_reels', 'instagram_post', 'telegram', 'stories', 'live')) DEFAULT 'youtube',
    category TEXT DEFAULT 'Education',
    publishing_date DATE,
    publishing_status TEXT CHECK (publishing_status IN ('idea', 'script_ready', 'editing', 'ready_to_publish', 'published')) DEFAULT 'idea',
    video_script_link TEXT DEFAULT '',
    thumbnail_url TEXT DEFAULT '',
    notes TEXT DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 13. AUDIENCE METRICS (Creator Growth Feature 2)
CREATE TABLE IF NOT EXISTS public.audience_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    platform TEXT CHECK (platform IN ('youtube', 'instagram', 'telegram')) NOT NULL,
    subscribers_count BIGINT DEFAULT 0,
    views_count BIGINT DEFAULT 0,
    watch_hours NUMERIC(10, 2) DEFAULT 0.00,
    reach_count BIGINT DEFAULT 0,
    engagement_rate NUMERIC(5, 2) DEFAULT 0.00,
    recorded_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 14. PRODUCTS (Creator Growth Feature 3: Courses & Services)
CREATE TABLE IF NOT EXISTS public.products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    price NUMERIC(10, 2) NOT NULL,
    description TEXT DEFAULT '',
    category TEXT DEFAULT 'Digital Course',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 15. COURSE SALES (Funnel Tracker)
CREATE TABLE IF NOT EXISTS public.course_sales (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    buyer_name TEXT DEFAULT '',
    buyer_email TEXT DEFAULT '',
    buyer_phone TEXT DEFAULT '',
    amount NUMERIC(10, 2) NOT NULL,
    funnel_stage TEXT CHECK (funnel_stage IN ('audience', 'lead', 'interested', 'payment_pending', 'purchased', 'refunded')) DEFAULT 'purchased',
    sale_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 16. LEADS (Creator Growth Feature 4)
CREATE TABLE IF NOT EXISTS public.leads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    phone_whatsapp TEXT DEFAULT '',
    source_platform TEXT CHECK (source_platform IN ('instagram', 'youtube', 'telegram', 'whatsapp', 'website', 'referral')) DEFAULT 'instagram',
    lead_status TEXT CHECK (lead_status IN ('new', 'contacted', 'interested', 'follow_up', 'converted', 'lost')) DEFAULT 'new',
    follow_up_date DATE,
    notes TEXT DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 17. CAMPAIGNS (Creator Growth Feature 5)
CREATE TABLE IF NOT EXISTS public.campaigns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    platform TEXT NOT NULL,
    video_url TEXT DEFAULT '',
    published_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 18. CAMPAIGN METRICS
CREATE TABLE IF NOT EXISTS public.campaign_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    campaign_id UUID NOT NULL REFERENCES public.campaigns(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    views BIGINT DEFAULT 0,
    likes BIGINT DEFAULT 0,
    comments BIGINT DEFAULT 0,
    shares BIGINT DEFAULT 0,
    leads_generated INTEGER DEFAULT 0,
    course_sales_count INTEGER DEFAULT 0,
    revenue_generated NUMERIC(12, 2) DEFAULT 0.00,
    recorded_at TIMESTAMPTZ DEFAULT NOW()
);

-- 19. REMINDERS (Smart Notification System)
CREATE TABLE IF NOT EXISTS public.reminders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    interval_hours INTEGER DEFAULT 2,
    is_active BOOLEAN DEFAULT TRUE,
    quiet_hours_start TIME DEFAULT '22:00:00',
    quiet_hours_end TIME DEFAULT '08:00:00',
    last_triggered_at TIMESTAMPTZ,
    next_trigger_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 20. NOTIFICATIONS LOG
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    notification_type TEXT DEFAULT 'reminder',
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 21. ACHIEVEMENTS & STREAKS
CREATE TABLE IF NOT EXISTS public.achievements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    badge_key TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    unlocked_at TIMESTAMPTZ DEFAULT NOW()
);

-- 22. GLOBAL ANNOUNCEMENTS (Admin Only)
CREATE TABLE IF NOT EXISTS public.announcements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 23. ADMIN AUDIT LOGS (Security & Privacy Requirement)
CREATE TABLE IF NOT EXISTS public.admin_audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    admin_id UUID NOT NULL REFERENCES public.profiles(id),
    action TEXT NOT NULL,
    details JSONB DEFAULT '{}'::jsonb,
    ip_address TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_stages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_updates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.voice_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.financial_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.income_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expense_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.client_interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_calendar ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audience_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.course_sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.campaign_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_audit_logs ENABLE ROW LEVEL SECURITY;

-- Helper function to check admin role safely
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND is_admin = TRUE
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Individual Users can only access their own records
DO $$
DECLARE
    tbl text;
    tables text[] := ARRAY[
        'projects', 'project_stages', 'project_updates', 'attachments', 
        'voice_notes', 'financial_goals', 'income_entries', 'expense_entries', 
        'clients', 'client_interactions', 'content_calendar', 'audience_metrics', 
        'products', 'course_sales', 'leads', 'campaigns', 'campaign_metrics', 
        'reminders', 'notifications', 'achievements'
    ];
BEGIN
    FOREACH tbl IN ARRAY tables LOOP
        EXECUTE format('
            CREATE POLICY %I_user_policy ON public.%I
            FOR ALL USING (auth.uid() = user_id)
            WITH CHECK (auth.uid() = user_id);
        ', tbl, tbl);
    END LOOP;
END $$;

-- Profiles: Users can view and update their own profile; Admins can view counts/stats only
CREATE POLICY profiles_user_policy ON public.profiles
FOR ALL USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Announcements: Everyone can read active announcements; Only Admins can create/edit
CREATE POLICY announcements_read_policy ON public.announcements
FOR SELECT USING (is_active = TRUE);

CREATE POLICY announcements_admin_policy ON public.announcements
FOR ALL USING (public.is_admin());

-- Admin Audit Logs: Only Super Admins can insert and read audit logs
CREATE POLICY audit_logs_admin_policy ON public.admin_audit_logs
FOR ALL USING (public.is_admin());

-- =====================================================================
-- TRIGGER FOR AUTOMATIC PROFILE CREATION ON AUTH.USERS INSERT
-- =====================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, avatar_url)
    VALUES (
        new.id,
        COALESCE(new.raw_user_meta_data->>'full_name', 'Creator'),
        COALESCE(new.raw_user_meta_data->>'avatar_url', '')
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Indexes for lightning performance
CREATE INDEX IF NOT EXISTS idx_projects_user_id ON public.projects(user_id);
CREATE INDEX IF NOT EXISTS idx_project_updates_project_id ON public.project_updates(project_id);
CREATE INDEX IF NOT EXISTS idx_income_entries_user_date ON public.income_entries(user_id, entry_date);
CREATE INDEX IF NOT EXISTS idx_expense_entries_user_date ON public.expense_entries(user_id, entry_date);
CREATE INDEX IF NOT EXISTS idx_clients_user_id ON public.clients(user_id);
CREATE INDEX IF NOT EXISTS idx_content_calendar_user_date ON public.content_calendar(user_id, publishing_date);

