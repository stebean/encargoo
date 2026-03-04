-- ============================================================
-- Fix: Workspace join + Roles (owner / member)
-- Run in Supabase Dashboard → SQL Editor
-- ============================================================

-- 1. Add role column to profiles (owner = created the workspace, member = joined)
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS role text NOT NULL DEFAULT 'member'
  CHECK (role IN ('owner', 'member'));

-- 2. Fix: profiles needs an UPDATE policy so users can set their own workspace_id
--    (was missing, causing joinWorkspace to fail silently)
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (id = auth.uid());

-- 3. Add RLS: workspace SELECT — members must be able to see their own workspace by code
--    (needed for joinWorkspace lookup if RLS blocks the query)
DROP POLICY IF EXISTS "Users can read workspaces" ON workspaces;

CREATE POLICY "Users can read workspaces"
  ON workspaces FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- ============================================================
-- After running this SQL:
-- • New users who CREATE a workspace get role = 'owner'
-- • New users who JOIN with a code get role = 'member'
-- • Existing users keep role = 'member' (update manually if needed)
-- ============================================================
