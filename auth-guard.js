(function(){
  const SUPABASE_URL = "https://zwvtxybqvxtnjrhfcptt.supabase.co";
  const SUPABASE_ANON_KEY = "sb_publishable_-UriFEnpHEPASlRYfIrZgA_6GD6diPF";
  const requiredRole = document.documentElement.dataset.requiredRole;
  const loginUrl = new URL("./login.html", window.location.href);
  loginUrl.searchParams.set("returnTo", window.location.pathname);
  function block(message){ document.documentElement.innerHTML = `<head><meta name="viewport" content="width=device-width,initial-scale=1"><title>DNS access required</title><style>body{font:16px system-ui;background:#f5f7f8;color:#172a3b;display:grid;place-items:center;min-height:100vh;margin:0}.card{max-width:420px;background:white;padding:28px;border:1px solid #dce4e9;border-radius:14px;margin:20px}a{color:#176b4a;font-weight:700}</style></head><body><main class="card"><h2>DNS Agriculture Exchange</h2><p>${message}</p><a href="${loginUrl.href}">Continue to secure login</a></main></body>`; }
  if(!window.supabase || !requiredRole){ block("Secure access could not be verified. Please sign in again."); return; }
  const client=window.supabase.createClient(SUPABASE_URL,SUPABASE_ANON_KEY,{auth:{persistSession:true,autoRefreshToken:true,detectSessionInUrl:true}});
  client.auth.getSession().then(async ({data,error})=>{
    if(error || !data.session){ window.location.replace(loginUrl.href); return; }
    const {data:profile,error:profileError}=await client.from("exchange_profiles").select("account_type,account_status").eq("user_id",data.session.user.id).maybeSingle();
    if(profileError || !profile){ await client.auth.signOut(); block("Your account profile could not be verified. Contact DNS support."); return; }
    if(["suspended","rejected","disabled"].includes(profile.account_status)){ block("This account is restricted. Contact DNS support."); return; }
    if(profile.account_type!==requiredRole){ block("This account does not have permission to open this workspace."); return; }
    document.documentElement.style.visibility="visible";
  }).catch(()=>block("We could not verify your session. Please try again."));
  client.auth.onAuthStateChange((event,session)=>{ if(event==="SIGNED_OUT" || !session) window.location.replace(loginUrl.href); });
})();
