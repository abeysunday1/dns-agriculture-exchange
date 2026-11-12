(() => {
const SUPABASE_URL = 'https://lvpgasxdmzpsjprohcji.supabase.co';
const SUPABASE_KEY = 'sb_publishable_m_HEhwzD-_lGBV_TDTht0Q_fqWjpfcv';
const db = window.supabase.createClient(SUPABASE_URL, SUPABASE_KEY);
const $ = (id) => document.getElementById(id);
const stages = ['new','business_verified','contact_identified','contacted','responded','qualified','specifications_received','quotation_sent','sample_requested','sample_paid','sample_sent','trial_order_negotiation','paid_trial_buyer','repeat_buyer','lost','disqualified'];
let prospects = [];
const esc = (v) => String(v == null ? '' : v).replace(/[&<>"']/g, (c) => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const pretty = (v) => String(v || '').replace(/_/g,' ').replace(/\b\w/g, c => c.toUpperCase());
const showError = (message) => { $('authError').textContent = message; $('authError').classList.remove('hidden'); };
async function checkSession() {
  const {data,error} = await db.auth.getSession();
  if (error || !data.session) { $('authPanel').classList.remove('hidden'); $('crmPanel').classList.add('hidden'); return; }
  const {data:isAdmin,error:adminError} = await db.rpc('is_exchange_admin');
  if (adminError || isAdmin !== true) { showError('This account is not the active staging administrator. No CRM data has been exposed.'); $('authPanel').classList.remove('hidden'); $('crmPanel').classList.add('hidden'); return; }
  $('authPanel').classList.add('hidden'); $('crmPanel').classList.remove('hidden'); $('signOut').classList.remove('hidden');
  await loadAll();
}
async function loadStats() {
  const [all,qualified,orders,due] = await Promise.all([
    db.from('buyer_prospects').select('id',{count:'exact',head:true}),
    db.from('buyer_prospects').select('id',{count:'exact',head:true}).in('stage',['qualified','specifications_received','quotation_sent','sample_requested','sample_paid','sample_sent','trial_order_negotiation']),
    db.from('buyer_orders').select('prospect_id').eq('payment_status','paid'),
    db.from('buyer_prospects').select('id',{count:'exact',head:true}).eq('do_not_contact',false).lte('next_follow_up_at',new Date().toISOString())
  ]);
  if ([all,qualified,orders,due].some(x => x.error)) throw new Error('Unable to load CRM metrics. Check admin access and staging schema.');
  const counts = {};
  (orders.data || []).forEach(x => counts[x.prospect_id] = (counts[x.prospect_id] || 0) + 1);
  const trial = Object.keys(counts).length;
  const stats = [all.count || 0,qualified.count || 0,trial,due.count || 0];
  const labels = ['Prospects','Qualified opportunities','Paid trial buyers','Follow-ups due'];
  $('stats').innerHTML = stats.map((n,i) => '<div class="stat"><b>'+n+'</b><span>'+labels[i]+'</span></div>').join('');
}
function renderRows() {
  const q = $('search').value.trim().toLowerCase();
  const stage = $('stageFilter').value;
  const list = prospects.filter(p => (!stage || p.stage === stage) && (!q || [p.business_name,p.country,p.city,p.email,p.contact_name,p.phone].join(' ').toLowerCase().includes(q)));
  if (!list.length) { $('prospectRows').innerHTML = '<tr><td colspan="7">No matching prospects yet. Add the first verified business above.</td></tr>'; return; }
  $('prospectRows').innerHTML = list.map(p => {
    const options = stages.map(s => '<option value="'+s+'" '+(p.stage===s?'selected':'')+'>'+pretty(s)+'</option>').join('');
    const follow = p.next_follow_up_at ? new Date(p.next_follow_up_at).toLocaleString() : 'Not scheduled';
    const blocked = p.do_not_contact ? ' · Do not contact' : (!p.contact_allowed ? ' · Contact basis not recorded' : '');
    return '<tr><td><b>'+esc(p.business_name)+'</b><div class="muted">'+esc(p.contact_name || 'No contact name')+' · '+esc(p.email || p.phone || 'No contact details')+'</div><div class="muted">'+esc(p.buyer_type)+esc(blocked)+'</div></td><td>'+esc([p.city,p.country].filter(Boolean).join(', ') || '—')+'</td><td>'+esc(pretty(p.source_channel))+'</td><td>'+esc(p.assigned_to)+'</td><td><select data-stage="'+p.id+'">'+options+'</select></td><td>'+esc(follow)+'</td><td><div class="rowactions"><button data-save="'+p.id+'">Save stage</button><button data-log="'+p.id+'">Log contact</button><button data-requirement="'+p.id+'">Requirement</button><button data-order="'+p.id+'">Record order</button></div></td></tr>';
  }).join('');
}
async function loadAll() {
  $('prospectRows').innerHTML = '<tr><td colspan="7">Loading…</td></tr>';
  const {data,error} = await db.from('buyer_prospects').select('id,business_name,buyer_type,country,city,website,contact_name,contact_role,email,phone,source_channel,product_interests,verification_status,stage,contact_allowed,contact_basis,do_not_contact,assigned_to,next_follow_up_at,created_at').order('created_at',{ascending:false}).limit(500);
  if (error) throw error;
  prospects = data || [];
  await loadStats(); renderRows();
}
async function saveProspect(e) {
  e.preventDefault(); const f = new FormData(e.currentTarget); const allowed = f.get('contact_allowed') === 'on'; const basis = String(f.get('contact_basis') || '').trim();
  if (allowed && basis.length < 5) { $('formMessage').textContent = 'Record the permission or lawful basis before enabling contact.'; return; }
  const rawFollow = f.get('next_follow_up_at');
  const payload = {
    business_name:String(f.get('business_name')).trim(), buyer_type:f.get('buyer_type'), country:String(f.get('country')||'').trim()||null,
    city:String(f.get('city')||'').trim()||null, website:String(f.get('website')||'').trim()||null,
    contact_name:String(f.get('contact_name')||'').trim()||null, contact_role:String(f.get('contact_role')||'').trim()||null,
    email:String(f.get('email')||'').trim().toLowerCase()||null, phone:String(f.get('phone')||'').trim()||null,
    source_channel:f.get('source_channel'), source_url:String(f.get('source_url')||'').trim()||null,
    product_interests:String(f.get('product_interests')||'').split(',').map(x=>x.trim()).filter(Boolean),
    assigned_to:f.get('assigned_to'), notes:String(f.get('notes')||'').trim()||null,
    contact_allowed:allowed, contact_basis:basis||null, next_follow_up_at:rawFollow?new Date(rawFollow).toISOString():null
  };
  $('formMessage').textContent = 'Saving…';
  const {error} = await db.from('buyer_prospects').insert(payload);
  if (error) { $('formMessage').textContent = error.code === '23505' ? 'This email is already in the buyer CRM.' : error.message; return; }
  e.currentTarget.reset(); $('formMessage').textContent = 'Prospect saved.'; await loadAll();
}
async function saveStage(id) {
  const select = document.querySelector('[data-stage="'+id+'"]'); if (!select) return;
  const {error} = await db.from('buyer_prospects').update({stage:select.value}).eq('id',id);
  if (error) { alert('Stage was not saved: '+error.message); return; }
  await loadAll();
}
async function logContact(id) {
  const p = prospects.find(x=>x.id===id); if (!p) return;
  const channel = prompt('Contact channel: linkedin, email, whatsapp, telegram, facebook, instagram, phone, meeting, trade_platform, other','email'); if (!channel) return;
  const direction = prompt('Direction: outbound, inbound, or internal','outbound'); if (!direction) return;
  if (direction === 'outbound' && (!p.contact_allowed || p.do_not_contact)) { alert('Outbound contact is blocked until permission/lawful basis is recorded and Do Not Contact is off.'); return; }
  const summary = prompt('What happened? Record the actual message, call, or response.'); if (!summary || summary.trim().length < 2) return;
  const follow = prompt('Next follow-up date/time (optional, ISO format e.g. 2026-11-16T10:00:00+01:00)','');
  const next = follow ? new Date(follow).toISOString() : null;
  const {error} = await db.from('buyer_interactions').insert({prospect_id:id,channel:channel.toLowerCase(),direction:direction.toLowerCase(),activity_type:'follow_up',summary:summary.trim(),next_follow_up_at:next});
  if (error) { alert('Could not log interaction: '+error.message); return; }
  await db.from('buyer_prospects').update({last_contacted_at:new Date().toISOString(),next_follow_up_at:next}).eq('id',id);
  await loadAll();
}
async function createRequirement(id) {
  const product = prompt('Product required (e.g. dried ginger, sesame seed, cashew):'); if (!product) return;
  const quantity = Number(prompt('Required quantity (number):','100')); if (!Number.isFinite(quantity) || quantity <= 0) return alert('Enter a valid quantity.');
  const unit = prompt('Unit: kg, tonne, litre, piece, carton, other','kg'); if (!unit) return;
  const grade = prompt('Buyer grade/specification (record exact requirement):','') || null;
  const destination = prompt('Delivery destination (city, country):','') || null;
  const packaging = prompt('Packaging requirement (optional):','') || null;
  const {error} = await db.from('buyer_opportunities').insert({prospect_id:id,product_name:product.trim(),required_quantity:quantity,quantity_unit:unit.toLowerCase(),grade_specification:grade,destination,packaging_requirement:packaging});
  if (error) { alert('Requirement was not saved: '+error.message); return; }
  alert('Buyer requirement saved. Match it against inspected supplier submissions before quoting.');
}
async function recordOrder(id) {
  const p = prospects.find(x=>x.id===id); if (!p) return;
  const orderNo = prompt('Unique order reference:'); if (!orderNo) return;
  const product = prompt('Product on this order:'); if (!product) return;
  const quantity = Number(prompt('Order quantity:','20')); if (!Number.isFinite(quantity) || quantity <= 0) return alert('Enter a valid quantity.');
  const unit = prompt('Quantity unit:','kg') || 'kg';
  const currency = (prompt('Currency code (USD, GBP, EUR, NGN):','USD') || 'USD').toUpperCase();
  const unitPrice = Number(prompt('Unit price:','0')); const total = Number(prompt('Total order value:','0'));
  if (!Number.isFinite(unitPrice) || unitPrice < 0 || !Number.isFinite(total) || total < 0) return alert('Enter valid prices.');
  const payment = prompt('Payment status: pending, partial, paid, failed. Only enter PAID after funds are received and verified.','pending');
  if (!['pending','partial','paid','failed'].includes((payment||'').toLowerCase())) return alert('Invalid payment status.');
  const isPaid = payment.toLowerCase() === 'paid';
  if (isPaid && !confirm('Confirm that the buyer’s funds have been received and verified in the company account?')) return;
  const {data:existing} = await db.from('buyer_orders').select('id').eq('prospect_id',id).eq('payment_status','paid');
  const {error} = await db.from('buyer_orders').insert({order_number:orderNo.trim(),prospect_id:id,product_name:product.trim(),quantity,quantity_unit:unit.toLowerCase(),currency,unit_price:unitPrice,total_value:total,payment_status:payment.toLowerCase(),paid_at:isPaid?new Date().toISOString():null});
  if (error) { alert('Order was not saved: '+error.message); return; }
  if (isPaid) await db.from('buyer_prospects').update({stage:(existing||[]).length ? 'repeat_buyer' : 'paid_trial_buyer'}).eq('id',id);
  alert(isPaid ? 'Paid order recorded. This buyer now counts toward the paid trial-buyer target.' : 'Order recorded, but it does not count as a trial buyer until payment is verified.');
  await loadAll();
}
document.addEventListener('click', async e => {
  const save = e.target.closest('[data-save]'); const log = e.target.closest('[data-log]'); const req = e.target.closest('[data-requirement]'); const order = e.target.closest('[data-order]');
  try { if (save) await saveStage(save.dataset.save); if (log) await logContact(log.dataset.log); if (req) await createRequirement(req.dataset.requirement); if (order) await recordOrder(order.dataset.order); }
  catch(err) { alert(err.message || 'Something went wrong.'); }
});
$('loginForm').addEventListener('submit', async e => { e.preventDefault(); $('authError').classList.add('hidden'); const {error} = await db.auth.signInWithPassword({email:$('loginEmail').value.trim(),password:$('loginPassword').value}); if (error) return showError(error.message); await checkSession(); });
$('googleLogin').addEventListener('click', async () => { const {error} = await db.auth.signInWithOAuth({provider:'google',options:{redirectTo:location.href}}); if (error) showError(error.message); });
$('signOut').addEventListener('click', async () => { await db.auth.signOut(); location.reload(); });
$('prospectForm').addEventListener('submit', e => saveProspect(e).catch(err => $('formMessage').textContent = err.message));
$('refresh').addEventListener('click', () => loadAll().catch(err => alert(err.message)));
$('search').addEventListener('input', renderRows); $('stageFilter').addEventListener('change', renderRows);
checkSession().catch(err => showError(err.message || 'Unable to connect to staging.'));
})();