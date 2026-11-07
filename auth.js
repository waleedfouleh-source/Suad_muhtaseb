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
  const message = String(error?.message || "");
  if (/already registered|user already exists/i.test(message)) return "هذا البريد مسجّل مسبقًا. جرّب تسجيل الدخول.";
  if (/invalid login credentials/i.test(message)) return "البريد الإلكتروني أو كلمة المرور غير صحيحة.";
  if (/email not confirmed/i.test(message)) return "يجب تأكيد بريدك الإلكتروني من الرسالة التي وصلتك أولًا.";
  if (/password.*(weak|short)|should be at least/i.test(message)) return "كلمة المرور لا تحقق متطلبات الأمان. استخدم كلمة مرور أطول.";
  if (/rate limit|too many requests/i.test(message)) return "تم إرسال طلبات كثيرة خلال وقت قصير. انتظر قليلًا ثم حاول مجددًا.";
  return message || "تعذر إكمال العملية. حاول مرة أخرى.";
}
