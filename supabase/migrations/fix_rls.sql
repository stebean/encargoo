-- Fix: Allow authenticated users to create workspaces
CREATE POLICY "Users can create workspaces"
  ON workspaces FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Fix: Allow users to search workspaces to join them by access code
-- Since they don't know the workspace_id yet, they need to be able to read workspaces
DROP POLICY IF EXISTS "Users can read their workspace" ON workspaces;

CREATE POLICY "Users can read workspaces"
  ON workspaces FOR SELECT USING (auth.uid() IS NOT NULL);
