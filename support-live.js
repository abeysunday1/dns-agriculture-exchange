/* DNS Agriculture private customer-care chat. Uses only the public publishable key. */
(() => {
  const SUPABASE_URL = 'https://zwvtxybqvxtnjrhfcptt.supabase.co';
  const SUPABASE_PUBLISHABLE_KEY = 'sb_publishable_-UriFEnpHEPASlRYfIrZgA_6GD6diPF';
  const db = window.supabase.createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, {
    db: { schema: 'dns_support' },
    auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true }
  });
  const $ = (id) => document.getElementById(id);
  const esc = (s) => String(s ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
  let currentUser = null, activeConversation = null, channel = null;
  const role = location.pathname.includes('buyer.html') ? 'buyer' : 'supplier';

  function status(message, bad=false) {
    const el = $('chatStatus');
    if (el) { el.textContent = message; el.style.color = bad ? '#b42318' : ''; }
  }
  function addMessage(m) {
    const host = $('chatMessages'); if (!host) return;
    if (host.querySelector('[data-empty]')) host.innerHTML = '';
    const mine = m.sender_user_id === currentUser?.id;
    const wrap = document.createElement('div');
    wrap.className = 'bubble' + (mine ? ' mine' : '');
    const body = document.createElement('div'); body.textContent = m.body;
    const meta = document.createElement('small');
    meta.textContent = (mine ? 'You' : 'DNS Customer Care') + ' · ' + new Date(m.created_at).toLocaleString();
    wrap.append(body, meta); host.appendChild(wrap); host.scrollTop = host.scrollHeight;
  }
  async function loadMessages() {
    const { data, error } = await db.from('messages').select('id,conversation_id,sender_user_id,sender_role,body,created_at,internal_note').eq('conversation_id', activeConversation.id).eq('internal_note', false).order('created_at');
    if (error) throw error;
    $('chatMessages').innerHTML = '';
    (data || []).forEach(addMessage);
  }
  function subscribe() {
    if (channel) db.removeChannel(channel);
    channel = db.channel('dns-support-' + activeConversation.id)
      .on('postgres_changes', { event: 'INSERT', schema: 'dns_support', table: 'messages', filter: 'conversation_id=eq.' + activeConversation.id }, payload => {
        if (!payload.new.internal_note) addMessage(payload.new);
      }).subscribe();
  }
  async function openConversation() {
    const { data, error } = await db.from('conversations').select('id,ticket_ref,status,subject').eq('participant_user_id', currentUser.id).order('last_message_at', {ascending:false}).limit(1);
    if (error) throw error;
    if (data?.length) {
      activeConversation = data[0];
    } else {
      const subject = prompt('What do you need help with? (e.g. Account access, produce verification, delivery)');
      if (!subject || subject.trim().length < 3) return;
      const { data: created, error: createError } = await db.from('conversations').insert({
        participant_user_id: currentUser.id, participant_type: role, subject: subject.trim(), category: 'general'
      }).select('id,ticket_ref,status,subject').single();
      if (createError) throw createError;
      activeConversation = created;
    }
    if ($('chatRef')) $('chatRef').textContent = activeConversation.ticket_ref;
    status('Secure support conversation connected. Your ticket is ' + activeConversation.ticket_ref + '.');
    await loadMessages(); subscribe();
    const send = $('chatSend'); if (send) send.disabled = false;
  }
  async function sendMessage() {
    const input = $('chatInput'), body = input?.value.trim();
    if (!body || !currentUser) return;
    try {
      if (!activeConversation) await openConversation();
      if (!activeConversation) return;
      const { error } = await db.from('messages').insert({
        conversation_id: activeConversation.id, sender_user_id: currentUser.id,
        sender_role: role, body, internal_note: false
      });
      if (error) throw error;
      input.value = ''; status('Message sent securely. Replies from DNS Customer Care will appear here.');
    } catch (e) { status('Message not sent: ' + (e.message || 'Please try again.'), true); }
  }
  function authPanel() {
    const box = document.querySelector('.chatbox'); if (!box || $('dnsChatAuth')) return;
    const panel = document.createElement('div'); panel.id = 'dnsChatAuth';
    panel.style.cssText = 'padding:16px;border:1px solid #d9e2e8;border-radius:12px;margin:12px 0;background:#fff';
    panel.innerHTML = '<strong>Sign in to private customer care</strong><p style="font-size:12px;color:#667085">Use your registered email address and password. Your support conversation is visible only to you and authorised DNS staff.</p><form id="dnsChatAuthForm" style="display:grid;gap:8px"><input id="dnsChatEmail" type="email" required autocomplete="email" placeholder="Email address" style="padding:11px;border:1px solid #cfd8df;border-radius:8px"><input id="dnsChatPassword" type="password" required minlength="6" autocomplete="current-password" placeholder="Password" style="padding:11px;border:1px solid #cfd8df;border-radius:8px"><div style="display:flex;gap:8px;flex-wrap:wrap"><button type="submit" id="dnsChatSignIn" style="padding:10px 15px;border:0;border-radius:8px;background:#164b35;color:white">Sign in</button><button type="button" id="dnsChatSignUp" style="padding:10px 15px;border:1px solid #164b35;border-radius:8px;background:white;color:#164b35">Create account</button></div></form><small id="dnsChatAuthStatus" style="display:block;margin-top:8px;color:#667085">Email verification may be required before your first sign-in.</small>';
    box.insertBefore(panel, box.querySelector('.chatmessages'));
    $('dnsChatAuthForm').addEventListener('submit', async e => {
      e.preventDefault(); const email=$('dnsChatEmail').value.trim(), password=$('dnsChatPassword').value;
      const {error}=await db.auth.signInWithPassword({email,password});
      $('dnsChatAuthStatus').textContent=error ? error.message : 'Signed in. Loading your private conversation…';
    });
    $('dnsChatSignUp').addEventListener('click', async () => {
      const email=$('dnsChatEmail').value.trim(), password=$('dnsChatPassword').value;
      if (!email || password.length<6) { $('dnsChatAuthStatus').textContent='Enter a valid email and a password of at least 6 characters.'; return; }
      const {data,error}=await db.auth.signUp({email,password,options:{emailRedirectTo:location.href.split('#')[0]}});
      $('dnsChatAuthStatus').textContent=error ? error.message : (data.session ? 'Account created. Loading chat…' : 'Account created. Check your email for the verification link, then return here to sign in.');
    });
  }
  async function boot() {
    if (!$('chatMessages')) return;
    authPanel();
    const {data:{session}} = await db.auth.getSession();
    if (session) { currentUser=session.user; $('dnsChatAuth').hidden=true; try { await openConversation(); } catch(e) { status('Could not open support: '+e.message,true); } }
    db.auth.onAuthStateChange(async (_event, sessionNow) => {
      currentUser=sessionNow?.user || null;
      if (currentUser) {
        $('dnsChatAuth').hidden=true;
        try { await openConversation(); } catch(e) { status('Could not open support: '+e.message,true); }
      } else { $('dnsChatAuth').hidden=false; activeConversation=null; status('Sign in to access private customer care.'); }
    });
    const send=$('chatSend') || document.querySelector('button[onclick="sendChatPreview()"]');
    if (send) { send.id='chatSend'; send.disabled=!currentUser; send.onclick=sendMessage; send.removeAttribute('onclick'); }
    const input=$('chatInput');
    if (input) input.addEventListener('keydown',e=>{if(e.key==='Enter'&&!e.shiftKey){e.preventDefault();sendMessage();}});
    window.sendChatPreview=sendMessage;
    window.chatQuick=(value)=>{ if(input){input.value=value;input.focus();} };
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded',boot); else boot();
})();
