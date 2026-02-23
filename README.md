# GT Store (Jual/Beli) - Next.js + Supabase

## Fitur
- Customer:
  - Halaman Jual (upload bukti)
  - Halaman Beli
  - Cek status pesanan pakai ID (public_id)
  - Panduan, Pusat Bantuan (WA), Testimoni (Discord)
  - Responsive (mobile & desktop)
- Admin:
  - Login
  - Setting harga, stock, image URL
  - Riwayat pesanan + ubah status
  - Toggle Online/Offline + pesan toko tutup
  - Setting info penjual (world, owner, WA)

## Cara pakai (tanpa coding berat)
1) Buat akun Supabase (gratis) -> buat project.
2) Di Supabase:
   - SQL Editor -> run file `supabase.sql`
   - Storage -> create bucket `proofs` -> set Public
   - Authentication -> enable Email provider
   - Buat user admin (email & password)
3) Download project ini, buka folder, buat file `.env.local` dari `.env.example` lalu isi:
   - NEXT_PUBLIC_SUPABASE_URL
   - NEXT_PUBLIC_SUPABASE_ANON_KEY
   - ADMIN_EMAIL (email admin kamu)
   - NEXT_PUBLIC_ADMIN_WA (nomor WA admin)
   - NEXT_PUBLIC_DISCORD_INVITE (link discord testimoni)
4) Deploy:
   - Paling gampang: Vercel
   - Atau lokal: `npm install` lalu `npm run dev`

Catatan keamanan: template ini dibuat simpel. Kalau nanti mau lebih aman (admin write pakai server/service role, signed URL untuk bukti), bisa ditingkatkan.
