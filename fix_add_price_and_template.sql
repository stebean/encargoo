-- ============================================================
-- Add price column to order_photos + message template to workspaces
-- Run in Supabase Dashboard → SQL Editor
-- ============================================================

-- 1. Add price per photo item
ALTER TABLE order_photos
  ADD COLUMN IF NOT EXISTS price numeric(10, 2) DEFAULT 0;

-- 2. (Optional) Add default message template column to workspaces
--    so each workspace can have their own template
ALTER TABLE workspaces
  ADD COLUMN IF NOT EXISTS message_template text DEFAULT 'Hola {nombre}, su encargo está listo 🎉 El total es ${total}. ¡Gracias por su preferencia!';
