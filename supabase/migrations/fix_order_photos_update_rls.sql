-- Fix: Add missing UPDATE policy for order_photos table
-- Without this, editing photo descriptions fails silently (RLS blocks it)
-- Run this in Supabase Dashboard → SQL Editor

CREATE POLICY "Workspace members update photos"
  ON order_photos FOR UPDATE
  USING (order_id IN (
    SELECT id FROM orders WHERE workspace_id = get_user_workspace_id()
  ));
