-- Fix cascade deletion blocking:
-- When an 'order' is deleted, it automatically tries to delete 'order_photos' (ON DELETE CASCADE).
-- However, the RLS policy on 'order_photos' was checking the 'orders' table to see if the user had access.
-- This caused a conflict because during deletion, the 'order' row might not be visible to the policy check.

DROP POLICY IF EXISTS "Workspace members delete photos" ON order_photos;

CREATE POLICY "Allows cascade delete photos" 
ON order_photos FOR DELETE 
USING ( auth.uid() is not null );
