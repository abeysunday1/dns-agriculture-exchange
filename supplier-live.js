(() => {
  const URL='https://zwvtxybqvxtnjrhfcptt.supabase.co';
  const KEY='sb_publishable_-UriFEnpHEPASlRYfIrZgA_6GD6diPF';
  const db=window.supabase?.createClient(URL,KEY);
  const $=id=>document.getElementById(id);
  let user=null;
  const clean=v=>String(v??'').replace(/[&<>\"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;',"'":'&#39;'}[c]));
  const status=v=>({pending_review:'Pending DNS review',under_review:'Under review',approved:'Approved',rejected:'Changes requested',withdrawn:'Withdrawn'}[v]||String(v||'Pending').replaceAll('_',' '));
  function collect(){
    const names=['contact','business','produce','evidence','commercial','consent'];
    const data={};
    document.querySelectorAll('#supplierForm .formstep').forEach((step,i)=>{
      const part={};
      step.querySelectorAll('.field').forEach(field=>{
        const label=field.querySelector('label')?.textContent?.replace('*','').trim()||'Field';
        const el=field.querySelector('input,select,textarea');
        if(el)part[label]=el.type==='checkbox'?el.checked:el.value.trim();
      });
      const check=step.querySelector('input[type=checkbox]');
      if(check)part.consent=check.checked;
      data[names[i]||('section_'+i)]=part;
    });
    return data;
  }
  function draw(rows){
    const body=$('produceRows');
    if(!body)return;
    $('produceCount').textContent=rows.length+' record'+(rows.length===1?'':'s');
    $('listingCount') && ($('listingCount').textContent=rows.length);
    const overview=$('overviewProduce');if(overview){overview.innerHTML=rows.length?rows.slice(0,3).map(r=>{const d=r.submission_data||{},p=d.produce||{},b=d.business||{};return `<div class=\"listing\"><div class=\"crop\">🌾</div><div><h3>${clean(p.Commodity||'Produce submission')}</h3><p>${clean(b['Farm / business location']||b.State||'Location not provided')}</p><span class=\"tag gold\">${clean(status(r.status))}</span></div></div>`}).join(''):'<div class=\"empty\">No produce submitted yet. Select Add produce to begin.</div>';}
    if(!rows.length){body.innerHTML='<tr><td colspan="5" class="empty">No produce submitted yet. Select Add produce to begin.</td></tr>';return;}
    body.innerHTML=rows.map(r=>{
      const d=r.submission_data||{},p=d.produce||{},b=d.business||{};
      const commodity=p.Commodity||'Produce submission';
      const location=b['Farm / business location']||[b['LGA / town'],b.State].filter(Boolean).join(', ')||'Not provided';
      const quantity=[p.Quantity,p.Unit].filter(Boolean).join(' ')||'Not provided';
      return `<tr><td><strong>${clean(commodity)}</strong></td><td>${clean(location)}</td><td>${clean(quantity)}</td><td>${new Date(r.created_at).toLocaleDateString()}</td><td><span class="tag gold">${clean(status(r.status))}</span></td></tr>`;
    }).join('');
  }
  async function load(){
    const {data,error}=await db.from('exchange_submissions').select('id,submission_data,status,created_at,updated_at').eq('user_id',user.id).eq('submission_type','supplier').order('created_at',{ascending:false});
    if(error){$('accountNotice').textContent='We could not load your produce records. Refresh or contact DNS support.';console.error(error);return;}
    draw(data||[]);
  }
  async function init(){
    if(!db){location.href='login.html';return;}
    const {data:{session}}=await db.auth.getSession();
    if(!session){location.href='login.html';return;}
    user=session.user;
    const {data:profile,error}=await db.from('exchange_profiles').select('full_name,account_type,account_status').eq('user_id',user.id).maybeSingle();
    if(error||!profile){$('accountNotice').textContent='Your account profile could not be loaded. Please contact DNS support.';return;}
    if(profile.account_type!=='supplier'){location.href='buyer.html';return;}
    $('accountBadge').textContent=profile.full_name||user.email||'Supplier account';
    $('reviewStatus') && ($('reviewStatus').textContent=status(profile.account_status));
    await load();
  }
  $('signOutBtn')?.addEventListener('click',async()=>{const {error}=await db.auth.signOut();if(error){alert('Unable to sign out. Please try again.');return;}location.href='login.html';});
  $('supplierForm')?.addEventListener('submit',async e=>{
    e.preventDefault();
    if(!user){alert('Your session has expired. Please sign in again.');location.href='login.html';return;}
    const button=$('submitBtn');button.disabled=true;button.textContent='Submitting…';
    try{
      const submission=collect();
      if(!submission.consent?.consent)throw new Error('Please confirm the consent checkbox before submitting.');
      const {data,error}=await db.from('exchange_submissions').insert({user_id:user.id,submission_type:'supplier',submission_data:submission,status:'pending_review'}).select('id').single();
      if(error)throw error;
      $('supplierForm').reset();
      $('wizard').classList.remove('open');
      if(typeof showPage==='function')showPage('produce');
      await load();
      alert('Your produce details were saved. Reference: '+data.id+'. Status: Pending DNS review.');
    }catch(err){alert(err.message||'We could not save your submission. Please try again.');}
    finally{button.disabled=false;button.textContent='Submit produce for review';}
  });
  init();
})();
