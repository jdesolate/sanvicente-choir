-- Migration: Finance Proofs — optional receipt/proof uploads
-- Adds a nullable proof_path column to the ledger and sinking fund tables,
-- and a private storage bucket that only finance staff can read or write.
-- Run this in the Supabase SQL Editor.

-- ── Columns ──────────────────────────────────────────────────────────────────

alter table ledger
  add column if not exists proof_path text;

alter table sinking_fund_contributions
  add column if not exists proof_path text;

-- ── Storage bucket (private) ─────────────────────────────────────────────────

insert into storage.buckets (id, name, public)
values ('finance-proofs', 'finance-proofs', false)
on conflict (id) do nothing;

-- ── Storage policies ─────────────────────────────────────────────────────────
-- Proof paths are only discoverable through the ledger / sinking fund rows,
-- which are themselves gated by role, so a single staff-wide policy is enough.

create policy "finance-proofs: staff read" on storage.objects for select
  using (bucket_id = 'finance-proofs'
         and auth_role() in ('secretary','treasurer','admin','super_admin'));

create policy "finance-proofs: staff insert" on storage.objects for insert
  with check (bucket_id = 'finance-proofs'
              and auth_role() in ('secretary','treasurer','admin','super_admin'));

create policy "finance-proofs: staff update" on storage.objects for update
  using (bucket_id = 'finance-proofs'
         and auth_role() in ('secretary','treasurer','admin','super_admin'));

create policy "finance-proofs: staff delete" on storage.objects for delete
  using (bucket_id = 'finance-proofs'
         and auth_role() in ('secretary','treasurer','admin','super_admin'));
