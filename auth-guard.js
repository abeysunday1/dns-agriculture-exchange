(function(){
  const URL="https://zwvtxybqvxtnjrhfcptt.supabase.co", KEY="sb_publishable_-UriFEnpHEPASlRYfIrZgA_6GD6diPF";
  const required=document.documentElement.dataset.requiredRole;
  const login=new URL("./login.html",location.href); login.searchParams.set("returnTo",location.pathname);
  function block(msg){document.documentElement.innerHTML=`<head><meta name="viewport" content="width=device-width,initial-scale=1"><title>DNS access required</title><style>body{font:16px system-ui;background:#f5f7f8;color:#172a3b;display:grid;place-items:center;min-height:100vh;margin:0}.card{max-width:430px;background:white;padding:28px;border:1px solid #dce4e9;border-radius:14px;margin:20px}a{color:#176b4a;font-weight:700}</style></head><body><main class="card"><h2>DNS Agriculture Exchange</h2><p>${msg}</p><a href="${login.href}">Continue to secure login</a></main></body>`;}
  if(!window.supabase||!required){block("Secure access could not be verified.");return;}
  const client=window.supabase.createClient(URL,KEY,{auth:{persistSession:true,autoRefreshToken:true,detectSessionInUrl:true}});
  client.auth.getSession().then(async({data,error})=>{
    if(error||!data.session){location.replace(login.href);return;}
    if(required==="admin"){
      const {data:staff,error:staffError}=await client.schema("dns_support").from("support_agents").select("role,active").eq("user_id",data.session.user.id).maybeSingle();
      if(staffError||!staff||!staff.active||staff.role!=="admin"){block("This account is not provisioned as an active DNS administrator.");return;}
    }else{
      const {data:profile,error:profileError}=await client.from("exchange_profiles").select("account_type,account_status").eq("user_id",data.session.user.id).maybeSingle();
      if(profileError||!profile){await client.auth.signOut();block("Your account profile could not be verified.");return;}
      if(["suspended","rejected","disabled"].includes(profile.account_status)){block("This account is restricted. Contact DNS support.");return;}
      if(profile.account_type!==required){block("This account does not have permission to open this workspace.");return;}
    }
    document.documentElement.style.visibility="visible";
  }).catch(()=>block("We could not verify your session. Please sign in again."));
  client.auth.onAuthStateChange((event,session)=>{if(event==="SIGNED_OUT"||!session)location.replace(login.href);});
})();