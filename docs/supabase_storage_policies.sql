-- ============================================================================
-- GearGo Supabase Storage Configuration & Role-Based Access Control (RLS)
-- Bucket: 'equipment-images'
--
-- Requirements:
--   1. Full CRUD for authorized Gear Owners, Commercial Shops, and Administrators.
--   2. Renters have READ ONLY access.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Create or Update the 'equipment-images' Public Bucket
-- ----------------------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'equipment-images',
  'equipment-images',
  true,
  5242880, -- 5 MB limit per image
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg']
)
ON CONFLICT (id) DO UPDATE SET
  public = true,
  file_size_limit = 5242880,
  allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg'];

-- ----------------------------------------------------------------------------
-- 2. Helper Functions for Role Resolution
-- ----------------------------------------------------------------------------

-- Extracts user role from Supabase Auth JWT user metadata or claims
CREATE OR REPLACE FUNCTION public.geargo_user_role()
RETURNS text
LANGUAGE sql
STABLE
AS $$
  SELECT COALESCE(
    auth.jwt() -> 'user_metadata' ->> 'role',
    auth.jwt() ->> 'role',
    'renter'
  );
$$;

-- Returns true if user is an authorized Gear Owner, Commercial Shop, or Administrator
CREATE OR REPLACE FUNCTION public.is_geargo_authorized_lender_or_admin()
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  SELECT public.geargo_user_role() IN ('owner', 'commercial_shop', 'admin');
$$;

-- ----------------------------------------------------------------------------
-- 3. Clean up Existing Policies to Prevent Duplication
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "GearGo: Anyone (including Renters) can view equipment images" ON storage.objects;
DROP POLICY IF EXISTS "GearGo: Authorized Owners, Shops, and Admins can upload images" ON storage.objects;
DROP POLICY IF EXISTS "GearGo: Authorized Owners, Shops, and Admins can update images" ON storage.objects;
DROP POLICY IF EXISTS "GearGo: Authorized Owners, Shops, and Admins can delete images" ON storage.objects;

-- ----------------------------------------------------------------------------
-- 4. RLS POLICIES FOR 'equipment-images'
-- ----------------------------------------------------------------------------

-- [READ] - Renters, Guests, and All Users can view/read equipment images
CREATE POLICY "GearGo: Anyone (including Renters) can view equipment images"
ON storage.objects
FOR SELECT
TO public, anon, authenticated
USING (
  bucket_id = 'equipment-images'
);

-- [CREATE / INSERT] - Authorized Owners, Commercial Shops, and Admins can upload
CREATE POLICY "GearGo: Authorized Owners, Shops, and Admins can upload images"
ON storage.objects
FOR INSERT
TO authenticated, anon
WITH CHECK (
  bucket_id = 'equipment-images'
  AND (
    -- Administrator has platform-wide upload authority
    public.geargo_user_role() = 'admin'
    -- Gear Owners & Commercial Shops can upload equipment images
    OR public.geargo_user_role() IN ('owner', 'commercial_shop')
    -- When using Firebase Auth with Supabase client (anon key), allow uploads into the equipments/ folder
    OR (auth.role() = 'anon' AND (storage.foldername(name))[1] = 'equipments')
  )
);

-- [UPDATE] - Owners, Commercial Shops, and Admins can modify/replace equipment images
CREATE POLICY "GearGo: Authorized Owners, Shops, and Admins can update images"
ON storage.objects
FOR UPDATE
TO authenticated, anon
USING (
  bucket_id = 'equipment-images'
  AND (
    -- Administrator can update any listing image
    public.geargo_user_role() = 'admin'
    -- Owners & Shops can update images in their authorized folder
    OR (
      public.geargo_user_role() IN ('owner', 'commercial_shop')
      AND (
        (storage.foldername(name))[2] = auth.uid()::text
        OR auth.uid() IS NULL
      )
    )
    -- When using Firebase Auth via client, allow updates within equipments/ folder
    OR (auth.role() = 'anon' AND (storage.foldername(name))[1] = 'equipments')
  )
)
WITH CHECK (
  bucket_id = 'equipment-images'
);

-- [DELETE] - Owners, Commercial Shops, and Admins can remove equipment images
CREATE POLICY "GearGo: Authorized Owners, Shops, and Admins can delete images"
ON storage.objects
FOR DELETE
TO authenticated, anon
USING (
  bucket_id = 'equipment-images'
  AND (
    -- Administrator can remove any listing image
    public.geargo_user_role() = 'admin'
    -- Owners & Shops can delete images belonging to their folder
    OR (
      public.geargo_user_role() IN ('owner', 'commercial_shop')
      AND (
        (storage.foldername(name))[2] = auth.uid()::text
        OR auth.uid() IS NULL
      )
    )
    -- When using Firebase Auth via client, allow deletion within equipments/ folder
    OR (auth.role() = 'anon' AND (storage.foldername(name))[1] = 'equipments')
  )
);
