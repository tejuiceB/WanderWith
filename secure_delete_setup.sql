-- 1. Secure Posts Deletion Policy
-- First drop old delete policies if any
DROP POLICY IF EXISTS posts_delete ON public.posts;
DROP POLICY IF EXISTS posts_delete_owner ON public.posts;
DROP POLICY IF EXISTS "Users can delete own posts" ON public.posts;
DROP POLICY IF EXISTS "Delete own posts (soft)" ON public.posts;

-- Now create strict one: Only the post owner can delete
CREATE POLICY posts_delete_owner
ON public.posts
FOR DELETE
USING (
  user_id = auth.uid()
);

-- 2. Ensure Likes Cascade Delete
ALTER TABLE public.likes
DROP CONSTRAINT IF EXISTS likes_post_id_fkey;

ALTER TABLE public.likes
ADD CONSTRAINT likes_post_id_fkey
FOREIGN KEY (post_id)
REFERENCES public.posts(id)
ON DELETE CASCADE;

-- 3. Ensure Comments Cascade Delete
ALTER TABLE public.comments
DROP CONSTRAINT IF EXISTS comments_post_id_fkey;

ALTER TABLE public.comments
ADD CONSTRAINT comments_post_id_fkey
FOREIGN KEY (post_id)
REFERENCES public.posts(id)
ON DELETE CASCADE;
