-- 1. Add archived column
ALTER TABLE public.posts ADD COLUMN IF NOT EXISTS is_archived boolean DEFAULT false;

-- 2. Update SELECT policy
-- Drop existing select policies to avoid conflicts
DROP POLICY IF EXISTS "View Posts based on visibility" ON public.posts;
DROP POLICY IF EXISTS posts_select_clean ON public.posts;
DROP POLICY IF EXISTS "Public posts are viewable by everyone" ON public.posts;
DROP POLICY IF EXISTS "Followers can view protected posts" ON public.posts;
DROP POLICY IF EXISTS "Trip members can view trip posts" ON public.posts;

CREATE POLICY posts_select_clean
ON public.posts
FOR SELECT
USING (
  user_id = auth.uid() -- Owner sees everything
  OR (
    is_archived = false -- Others only see non-archived
    AND (
      visibility = 'public'
      OR (
        visibility = 'followers'
        AND EXISTS (
          SELECT 1 FROM public.follows
          WHERE follower_id = auth.uid()
          AND following_id = posts.user_id
          AND status = 'accepted'
        )
      )
      OR (
        visibility = 'trip'
        AND EXISTS (
          SELECT 1 FROM public.trip_members
          WHERE user_id = auth.uid()
          AND trip_id = posts.trip_id
        )
      )
    )
  )
);

-- 3. Update Policy for Editing (Owner Only)
DROP POLICY IF EXISTS "Users can update own posts" ON public.posts;
DROP POLICY IF EXISTS posts_update_owner ON public.posts;

CREATE POLICY posts_update_owner
ON public.posts
FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());
