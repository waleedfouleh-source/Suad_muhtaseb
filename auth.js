import { createClient } from "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.119.0/+esm";

const SUPABASE_URL = "https://iysfchkxoyasllixnpdn.supabase.co";
const SUPABASE_PUBLISHABLE_KEY = "sb_publishable_BB9EpLpZ2xmYBRsmQh7zTg_6OIm0yZe";

export const supabase = createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
    flowType: "implicit"
  }
});

export function siteUrl(page) {
  return new URL(page, document.baseURI).toString();
}

export function showNotice(element, message, type = "info") {
  element.textContent = message;
  element.className = "notice" + (type === "error" ? " error" : type === "success" ? " success" : "");
  element.style.display = "block";
}

export function friendlyAuthError(error) {
  const message = String(error?.message || error?.error_description || "");
  const code = String(error?.code || error?.name || "");
  if (/already registered|user already exists/i.test(message)) return "هذا البريد مسجّل مسبقًا. جرّب تسجيل الدخول.";
  if (/invalid login credentials|invalid_credentials/i.test(message) || code === "invalid_credentials") return "البريد الإلكتروني أو كلمة المرور غير صحيحة. تأكد من كتابتهما، أو استخدم خيار استعادة كلمة المرور.";
  if (/email not confirmed/i.test(message)) return "يجب تأكيد بريدك الإلكتروني من الرسالة التي وصلتك أولًا.";
  if (/password.*(weak|short)|should be at least/i.test(message)) return "كلمة المرور لا تحقق متطلبات الأمان. استخدم كلمة مرور أطول.";
  if (/rate limit|too many requests/i.test(message)) return "تم إرسال طلبات كثيرة خلال وقت قصير. انتظر قليلًا ثم حاول مجددًا.";
  if (/failed to fetch|networkerror|network request failed|load failed|timeout|timed out|aborterror/i.test(message) || /network|fetch/i.test(code)) return "تعذر الاتصال بخادم المنصة. تحقق من اتصال الإنترنت ثم حاول مجددًا.";
  if (/request_timeout|gateway timeout|504/i.test(message)) return "استغرق خادم المصادقة وقتًا أطول من المعتاد. انتظر قليلًا ثم حاول مجددًا.";
  return "تعذر إكمال العملية حاليًا. حاول مرة أخرى بعد قليل.";
}
