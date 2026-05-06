-- チラシ原本（JPG / PDF）を置く Storage バケット。
-- 取り込みは Edge Function（service role）経由を想定するため、public=false。
insert into storage.buckets (id, name, public, file_size_limit)
values ('flyer_sources', 'flyer_sources', false, 10485760)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit;
