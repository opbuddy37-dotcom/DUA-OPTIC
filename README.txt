DUA OPTICS - SHARED CLOUD / NO EMAIL LOGIN

1. Supabase Dashboard -> Authentication -> Providers -> enable Anonymous Sign-Ins.
2. Run supabase_setup_shared.sql in Supabase SQL Editor.
3. The default DUA OPTICS access code is: DUA-OPTICS-4827
4. Replace index.html and sw.js in your GitHub project with the files in this folder.
5. Rebuild/redeploy the app.
6. On every phone/computer, open the app and enter the same access code.
7. Records saved on one device will appear on the other devices and can be edited; edits sync back to the shared cloud.

IMPORTANT: This is a shared workspace. Anyone who knows the access code can access the records, so keep the code private. Customer optical records are sensitive. If you later want stronger per-user security without email, we can add a phone/PIN or other authentication method.

The app saves locally first, then syncs to Supabase. If the internet is temporarily unavailable, the local record remains and can be synced later from Backup & Data -> Sync to cloud now.
