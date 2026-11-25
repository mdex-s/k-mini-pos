KoOo Mini POS Cloud 3.0 — Setup လမ်းညွှန် (မြန်မာ)

အရေးကြီး: ဒီ ZIP က Cloud ချိတ်ဆက်ဖို့ အဆင်သင့်ပြင်ထားတဲ့ Source Package ဖြစ်ပါတယ်။ ကိုဦးရဲ့ Supabase Project ကို ဖန်တီးပြီး config.js မှာ URL နဲ့ Publishable/anon key ထည့်မှ အလုပ်လုပ်ပါမယ်။ Cloud service ကို ကိုယ်စားဖန်တီးပေးထားခြင်း မဟုတ်ပါ။

အပိုင်း (၁) Supabase Free Project ဖန်တီးရန်
1. Browser မှ https://supabase.com ကိုဖွင့်ပြီး အကောင့်ဖွင့်ပါ။
2. New project ကိုရွေးပြီး Organization, Project name, Database password, Region ရွေးပါ။
3. Project ဖန်တီးပြီး Dashboard > Project Settings > API Keys (သို့မဟုတ် Connect) ကိုဖွင့်ပါ။
4. Project URL နဲ့ Publishable key (သို့မဟုတ် legacy anon public key) ကိုကူးပါ။
5. service_role / secret key ကို ဘယ်သူ့ကိုမှ မပေးပါနှင့်။ Browser ထဲ မထည့်ပါနှင့်။

အပိုင်း (၂) Database တည်ဆောက်ရန်
1. Supabase Dashboard > SQL Editor > New query ကိုဖွင့်ပါ။
2. ZIP ထဲက sql/schema.sql ကိုဖွင့်ပြီး အားလုံး Copy လုပ်ပါ။
3. SQL Editor ထဲ Paste လုပ်ပြီး Run ကိုနှိပ်ပါ။
4. Run အောင်မြင်ကြောင်း စစ်ပါ။ Error ရှိလျှင် error စာသားကို မျှဝေပါ (password/key မပါစေပါနှင့်)။

အပိုင်း (၃) VSCodroid မှာ Cloud ချိတ်ရန်
1. ZIP ကို Android File Manager မှ Extract လုပ်ပါ။
2. VSCodroid > Open Folder > KoOo_Mini_POS_Cloud_V3 ကိုရွေးပါ။
3. js/config.js ကိုဖွင့်ပါ။
4. YOUR-PROJECT နေရာမှာ Project URL ထည့်ပါ။
5. YOUR_SUPABASE_PUBLISHABLE_OR_ANON_KEY နေရာမှာ Publishable/anon public key ထည့်ပါ။
6. Save လုပ်ပါ။
7. index.html ကို file:// နဲ့ မဖွင့်ပါနှင့်။ PWA/Service Worker အတွက် HTTPS သို့မဟုတ် localhost လိုပါတယ်။ Static hosting (ဥပမာ GitHub Pages/Netlify) မှာ HTTPS ဖြင့်တင်ပါ။ Public repository ထဲ key ထည့်မည်ဆို RLS policy ကို အရင်စစ်ပါ။

အပိုင်း (၄) ပထမ Login
1. Hosted HTTPS URL ကိုဖွင့်ပါ။
2. Create account tab ကိုနှိပ်ပါ။
3. Email, password (အနည်းဆုံး ၆ လုံး), Store name ဖြည့်ပါ။
4. Supabase Email confirmation ဖွင့်ထားလျှင် Email ကိုအတည်ပြုပြီး Sign in ပြန်လုပ်ပါ။
5. Products ထဲမှာ ပစ္စည်းထည့်ပြီး စမ်းသပ်အရောင်းလုပ်ပါ။

Multi-device
- အခြားဖုန်းမှာ တူညီတဲ့ HTTPS URL ကိုဖွင့်ပြီး တူညီတဲ့ account နဲ့ Login လုပ်ပါ။
- လက်ရှိ starter version က user တစ်ဦးတည်းအတွက် cross-device sync ကို အဓိကထောက်ပံ့ထားသည်။
- Team invitation ကို browser ထဲမှ မဖွင့်ထားပါ။ Staff ဖိတ်ရန် လုံခြုံသော server-side/Edge Function ထပ်တည်ဆောက်ရမည်။

Offline / Sync
- အရင်ဆုံး Online ဖြစ်စဉ် App ကိုဖွင့်ပြီး Supabase SDK နဲ့ App shell load ဖြစ်စေပါ။
- အရောင်းလုပ်စဉ် offline ဖြစ်ပါက sale ကို IndexedDB outbox ထဲတွင် queue လုပ်သည်။
- Internet ပြန်ရသောအခါ sync ပြန်လုပ်ရန် ကြိုးစားသည်။
- Sale စာရင်း၏ ဈေးနှုန်း/ကုန်ကျစရိတ်ကို Database က Product စာရင်းအပေါ်မူတည်၍ ပြန်တွက်သည်။\n- Offline queue ရှိနေစဉ် browser data clear မလုပ်ပါနှင့်၊ app data မဖျက်ပါနှင့်၊ အဲဒီစက်ကို မပြောင်းပါနှင့်။ အခြား device မှာ offline queue ကို မမြင်ရသေးပါ။
- Product/customer/expense write များသည် local optimistic cache + outbox ဖြစ်သည်။ Sync conflict ဖြစ်လျှင် Cloud နောက်ဆုံးအချက်အလက်က အနိုင်ရနိုင်သည်။ Offline multi-user concurrent edits ကို အပြည့်အဝ conflict merge မလုပ်နိုင်သေးပါ။

Backup
- Cloud & Backup မှ JSON export ကို ပုံမှန်လုပ်ပါ။
- Supabase Dashboard မှ Database backups/exports ကိုလည်း စီမံပါ။ Free tier backup policy/retention ကို Dashboard မှ စစ်ပါ။

လက်ရှိ Version ကန့်သတ်ချက်
- Cloud sync အတွက် Supabase Project လိုသည်။ Free plan limits/pausing/egress/storage/auth limits ပြောင်းလဲနိုင်သည်။
- Staff invitation, detailed permission matrix, supplier/purchase, returns/refunds, payment settlement, robust conflict resolution, scheduled cloud backups မပါသေးပါ။
- App ကို production accounting system ဟု မယူဆပါနှင့်။ အမှန်တကယ်ရောင်းချမှုမစခင် test data ဖြင့် စမ်းပါ။
- Public anon/publishable key ကို browser ထဲသုံးနိုင်သော်လည်း RLS က အဓိကလုံခြုံရေးဖြစ်သည်။ SQL schema ကို အတိအကျ run လုပ်ပါ။
