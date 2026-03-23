-- Create the storage bucket for order photos
insert into storage.buckets (id, name, public) values ('order-photos', 'order-photos', true)
on conflict (id) do nothing;

-- Set up policies for the bucket
-- Allow authenticated users to upload files
create policy "Authenticated users can upload photos"
on storage.objects for insert
with check ( bucket_id = 'order-photos' and auth.uid() is not null );

-- Allow public read access (since bucket is public, this might be redundant but safe)
create policy "Public read access to photos"
on storage.objects for select
using ( bucket_id = 'order-photos' );

-- Allow users to delete their photos
create policy "Users can delete photos"
on storage.objects for delete
using ( bucket_id = 'order-photos' and auth.uid() is not null );
