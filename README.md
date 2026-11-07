# Suad Muhtaseb | مساحة دعم

موقع عربي RTL تجريبي مبني كواجهة ثابتة متوافقة مع GitHub Pages، مع مصادقة مستخدمين عبر Supabase Auth.

## النشر
- المستودع: `waleedfouleh-source/Suad_muhtaseb`
- الموقع: https://waleedfouleh-source.github.io/Suad_muhtaseb/
- تسجيل حساب: `register.html`
- تسجيل الدخول: `login.html`
- صفحة الحساب: `account.html`
- ملفات المصادقة: `auth.js` و`auth-callback.html` و`reset-password.html`
- يوجد GitHub Actions workflow في `.github/workflows/pages.yml` للنشر التلقائي على فرع `main`.

## إعداد Supabase المطلوب
في Supabase Dashboard → Authentication → URL Configuration:
- Site URL: `https://waleedfouleh-source.github.io/Suad_muhtaseb/`
- أضف Redirect URL: `https://waleedfouleh-source.github.io/Suad_muhtaseb/auth-callback.html`
- أضف Redirect URL: `https://waleedfouleh-source.github.io/Suad_muhtaseb/reset-password.html`
- تأكد من تفعيل Email provider وتأكيد البريد الإلكتروني.
- لا تضع Service Role Key أو Secret Key في ملفات الموقع. يستخدم المتصفح Publishable Key فقط.

## الصلاحيات
- ينشئ trigger في قاعدة البيانات ملف profile ودور `registered_user` تلقائيًا للمستخدم الجديد.
- لا يمكن للزائر اختيار دور مهني أو إداري من نموذج التسجيل.
- يُمنح دور `professional` لسعاد يدويًا بعد إنشاء حسابها والتحقق من هويتها.
- دور `technical_owner` منفصل عن صلاحيات قراءة ملفات الحالات المهنية.
- بيانات الحالات والتقييمات تبقى في مخطط قاعدة بيانات خاص، ولا تُعرض في ملفات HTML العامة.

## ملاحظات قبل الإطلاق
- نموذج التسجيل يستخدم Supabase Auth ويعتمد على تأكيد البريد.
- نموذج التواصل في الصفحة الرئيسية ما زال محليًا ولا يرسل بيانات.
- التقييم الأولي الحالي لا يحفظ الإجابات في قاعدة البيانات.
- لا تُدخل بيانات حالات حقيقية أو معلومات نفسية حساسة قبل اكتمال ربط التقييم وتخزينه الآمن ومراجعة سياسة الخصوصية وشروط الاستخدام من سعاد.
- بعد إضافة حساب سعاد، يجب منحها دور `professional` من قاعدة البيانات وعدم استخدام بيانات المستخدم الوصفية لتحديد الصلاحيات.
