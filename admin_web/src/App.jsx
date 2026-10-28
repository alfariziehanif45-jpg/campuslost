import { useEffect, useMemo, useState } from 'react';
import {
  Activity, AlertCircle, ArrowDownRight, ArrowRight, ArrowUpRight, Bell,
  Check, CheckCheck, ChevronDown, CircleHelp, Clock3, Command, FileCheck2,
  FileSearch, Filter, LayoutDashboard, LogOut, MapPin, Menu, MoreHorizontal,
  Search, Settings2, ShieldCheck, SlidersHorizontal, Sparkles, TrendingUp,
  Users, X, XCircle, PackageCheck, Inbox, RefreshCw,
} from 'lucide-react';
import {
  collection, doc, getDoc, getDocFromServer, onSnapshot, query, serverTimestamp, updateDoc,
} from 'firebase/firestore';
import { onAuthStateChanged, signInWithEmailAndPassword, signOut } from 'firebase/auth';
import { auth, db } from './firebase';

const sections = [
  { id: 'overview', label: 'Overview', icon: LayoutDashboard },
  { id: 'claims', label: 'Claims', icon: FileCheck2, badge: true },
  { id: 'news', label: 'News', icon: Activity },
  { id: 'modal', label: 'Modal', icon: SlidersHorizontal },
  { id: 'settings', label: 'Settings', icon: Settings2 },
];

const asDate = (value) => {
  if (!value) return null;
  if (typeof value.toDate === 'function') return value.toDate();
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date;
};

function useCampusData(user) {
  const [data, setData] = useState({ items: [], claims: [], users: [] });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    if (!user) return undefined;
    let items = [];
    let claims = [];
    let users = [];
    let ready = 0;
    const receive = (key, value) => {
      if (key === 'items') items = value;
      if (key === 'claims') claims = value;
      if (key === 'users') users = value;
      ready += 1;
      setData({ items, claims, users });
      if (ready >= 3) setLoading(false);
    };
    const fail = (reason) => {
      setError(reason?.message || 'Tidak bisa memuat data dari Firebase.');
      setLoading(false);
    };
    const stops = [
      onSnapshot(query(collection(db, 'items')), (snap) => receive('items', snap.docs.map((d) => ({ id: d.id, ...d.data() }))), fail),
      onSnapshot(query(collection(db, 'claims')), (snap) => receive('claims', snap.docs.map((d) => ({ id: d.id, ...d.data() }))), fail),
      onSnapshot(query(collection(db, 'users')), (snap) => receive('users', snap.docs.map((d) => ({ id: d.id, ...d.data() }))), fail),
    ];
    return () => stops.forEach((stop) => stop());
  }, [user]);

  return { ...data, loading, error };
}

function App() {
  const [user, setUser] = useState(undefined);
  const [profile, setProfile] = useState(null);
  const [authError, setAuthError] = useState('');
  const [section, setSection] = useState('overview');
  const [mobileMenu, setMobileMenu] = useState(false);
  const [toast, setToast] = useState('');
  const data = useCampusData(user || null);

  useEffect(() => onAuthStateChanged(auth, async (nextUser) => {
    setUser(nextUser || null);
    setProfile(null);
    setAuthError('');
    if (nextUser) {
      try {
        const snap = await getDoc(doc(db, 'users', nextUser.uid));
        setProfile(snap.exists() ? snap.data() : {});
      } catch (error) {
        setAuthError(error.message || 'Gagal membaca profil admin.');
      }
    }
  }), []);

  useEffect(() => {
    if (!toast) return undefined;
    const timer = window.setTimeout(() => setToast(''), 3000);
    return () => window.clearTimeout(timer);
  }, [toast]);

  const pendingClaims = data.claims.filter((claim) => (claim.status || claim.claim_status || 'PENDING').toUpperCase() === 'PENDING');
  const isAdmin = (profile?.role || '').trim().toLowerCase() === 'admin';

  const refreshAdminProfile = async () => {
    setAuthError('');
    try {
      const snap = await getDocFromServer(doc(db, 'users', user.uid));
      setProfile(snap.exists() ? snap.data() : {});
    } catch (error) {
      setAuthError(error.message || 'Gagal memeriksa role langsung dari Firestore.');
    }
  };

  if (user === undefined || (user && profile === null && !authError)) return <div className="boot"><div className="brand-mark"><Command size={23} /></div><span>Menyiapkan ruang kerja...</span></div>;
  if (!user) return <Login onLogin={async (email, password) => {
    setAuthError('');
    try { await signInWithEmailAndPassword(auth, email, password); }
    catch (error) { setAuthError(error.code === 'auth/invalid-credential' ? 'Email atau kata sandi tidak sesuai.' : error.message); }
  }} error={authError} />;
  if (user && profile === null) return <ProfileLoadError error={authError} onLogout={() => signOut(auth)} />;
  if (profile && !isAdmin) return <AccessDenied email={user.email} uid={user.uid} role={profile.role} error={authError} onRefresh={refreshAdminProfile} onLogout={() => signOut(auth)} />;

  const setPage = (id) => { setSection(id); setMobileMenu(false); };
  const notify = (message) => setToast(message);
  return (
    <div className="app-shell">
      <aside className={`sidebar ${mobileMenu ? 'sidebar-open' : ''}`}>
        <div className="brand"><div className="brand-mark"><Command size={21} strokeWidth={2.6} /></div><div><b>CampusLost</b><span>ADMIN CONSOLE</span></div><button className="mobile-close icon-button" onClick={() => setMobileMenu(false)} aria-label="Tutup menu"><X size={18} /></button></div>
        <div className="campus-switch"><div className="campus-avatar">CL</div><div className="campus-name"><b>Campus workspace</b><span>Universitas · Main</span></div><ChevronDown size={15} /></div>
        <div className="nav-caption">WORKSPACE</div>
        <nav className="side-nav" aria-label="Navigasi utama">
          {sections.map(({ id, label, icon: Icon, badge }) => <button key={id} className={`nav-item ${section === id ? 'active' : ''}`} onClick={() => setPage(id)}><Icon size={18} strokeWidth={1.9} /><span>{label}</span>{badge && pendingClaims.length > 0 && <em>{pendingClaims.length}</em>}</button>)}
        </nav>
        <div className="sidebar-bottom"><div className="support-card"><div className="support-icon"><CircleHelp size={17} /></div><b>Butuh bantuan?</b><p>Hubungi tim dukungan CampusLost.</p><a href="mailto:support@campuslost.id">Hubungi support <ArrowRight size={13} /></a></div><div className="profile-mini"><div className="profile-avatar">{(profile?.name || user.email || 'A').slice(0, 1).toUpperCase()}</div><div className="profile-text"><b>{profile?.name || 'Admin CampusLost'}</b><span>{user.email}</span></div><button className="icon-button" title="Keluar" onClick={() => signOut(auth)}><LogOut size={16} /></button></div></div>
      </aside>
      {mobileMenu && <button className="scrim" onClick={() => setMobileMenu(false)} aria-label="Tutup navigasi" />}
      <main className="main-area">
        <header className="topbar"><div className="topbar-left"><button className="icon-button menu-toggle" onClick={() => setMobileMenu(true)} aria-label="Buka navigasi"><Menu size={20} /></button><div className="breadcrumb">Workspace <span>/</span> <b>{sections.find((item) => item.id === section)?.label}</b></div></div><div className="topbar-actions"><div className="live-status"><span className="live-dot" /> Live data</div><button className="icon-button top-icon" aria-label="Notifikasi" onClick={() => notify(`${pendingClaims.length} klaim menunggu ditinjau.`)}><Bell size={18} />{pendingClaims.length > 0 && <i />}</button><div className="top-divider" /><div className="top-user"><div className="profile-avatar small">{(profile?.name || user.email || 'A').slice(0, 1).toUpperCase()}</div><ChevronDown size={14} /></div></div></header>
        <div className="page-wrap">
          {data.error && <div className="error-banner"><AlertCircle size={17} /><span>{data.error} Pastikan akun memiliki akses Firestore.</span><button onClick={() => window.location.reload()}>Coba lagi</button></div>}
          {section === 'overview' && <Overview data={data} pendingClaims={pendingClaims} onNavigate={setPage} />}
          {section === 'claims' && <ClaimsPage claims={data.claims} items={data.items} users={data.users} onNotify={notify} />}
          {section === 'news' && <NewsPage items={data.items} loading={data.loading} onNotify={notify} />}
          {section === 'modal' && <SystemPage users={data.users} items={data.items} claims={data.claims} />}
          {section === 'settings' && <SettingsPage profile={profile} email={user.email} onLogout={() => signOut(auth)} />}
          {data.loading && <div className="loading-strip"><RefreshCw size={14} className="spin" /> Menghubungkan data CampusLost...</div>}
        </div>
      </main>
      <nav className="bottom-nav" aria-label="Navigasi mobile">{sections.map(({ id, label, icon: Icon, badge }) => <button key={id} onClick={() => setPage(id)} className={section === id ? 'active' : ''}><span className="bottom-icon"><Icon size={19} />{badge && pendingClaims.length > 0 && <i />}</span><small>{label}</small></button>)}</nav>
      {toast && <div className="toast"><Check size={16} />{toast}</div>}
    </div>
  );
}

function Login({ onLogin, error }) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [busy, setBusy] = useState(false);
  const submit = async (event) => { event.preventDefault(); setBusy(true); try { await onLogin(email.trim(), password); } finally { setBusy(false); } };
  return <div className="login-screen"><div className="login-art"><div className="login-brand"><div className="brand-mark"><Command size={22} /></div><b>CampusLost</b></div><div className="art-copy"><div className="art-pill"><ShieldCheck size={14} /> ADMIN WORKSPACE</div><h1>Temukan kembali,<br /><span>kelola lebih baik.</span></h1><p>Satu ruang untuk membantu komunitas kampus menyelesaikan setiap cerita kehilangan.</p><div className="art-stats"><div><b>01</b><span>Terhubung ke kampus</span></div><div><b>02</b><span>Data real-time</span></div><div><b>03</b><span>Akses terverifikasi</span></div></div></div><div className="art-orbit orbit-one" /><div className="art-orbit orbit-two" /><div className="art-bottom">CAMPUSLOST · ADMIN CONSOLE</div></div><div className="login-form-wrap"><form className="login-form" onSubmit={submit}><div className="login-icon"><ShieldCheck size={23} /></div><div className="eyebrow">SELAMAT DATANG KEMBALI</div><h2>Masuk ke dashboard</h2><p>Gunakan akun admin CampusLost untuk melanjutkan.</p>{error && <div className="form-error"><AlertCircle size={15} />{error}</div>}<label>Email admin</label><input type="email" placeholder="nama@kampus.ac.id" value={email} onChange={(event) => setEmail(event.target.value)} required /><label>Kata sandi</label><input type="password" placeholder="Masukkan kata sandi" value={password} onChange={(event) => setPassword(event.target.value)} required /><button className="primary-button login-button" disabled={busy}>{busy ? <><span className="button-spinner" /> Memeriksa akses...</> : <>Masuk ke dashboard <ArrowRight size={16} /></>}</button><div className="login-note"><ShieldCheck size={14} /> Akses hanya untuk administrator kampus.</div></form><div className="login-footer">© 2026 CampusLost <span>•</span> Lost & Found Kampus</div></div></div>;
}

function AccessDenied({ email, uid, role, error, onRefresh, onLogout }) {
  const [checking, setChecking] = useState(false);
  const refresh = async () => { setChecking(true); try { await onRefresh(); } finally { setChecking(false); } };
  const roleText = typeof role === 'string' && role.trim() ? role : '(kosong / tidak ditemukan)';
  return <div className="denied-screen"><div className="denied-card"><div className="denied-icon"><ShieldCheck size={27} /></div><h2>Akses admin belum tersedia</h2><p>Akun <b>{email}</b> berhasil masuk, tetapi role yang dibaca dari profil Firestore belum bernilai <code>admin</code>.</p><div style={{ margin: '18px 0', padding: 14, borderRadius: 12, background: '#f5f6fb', textAlign: 'left', overflowWrap: 'anywhere' }}><div><b>Project Firebase:</b> {db.app.options.projectId}</div><div style={{ marginTop: 8 }}><b>Dokumen:</b> <code>users/{uid}</code></div><div style={{ marginTop: 8 }}><b>Role terbaca:</b> <code>{roleText}</code></div></div><p>Pastikan role di dokumen tersebut berupa string <code>admin</code>. Setelah menyimpan perubahan di Firebase Console, tekan Cek ulang role.</p>{error && <div className="form-error" style={{ textAlign: 'left', overflowWrap: 'anywhere' }}><AlertCircle size={15} />{error}</div>}<div style={{ display: 'flex', justifyContent: 'center', gap: 10, flexWrap: 'wrap' }}><button className="primary-button" onClick={refresh} disabled={checking}>{checking ? 'Memeriksa...' : 'Cek ulang role'}</button><button className="outline-button" onClick={onLogout}>Keluar</button></div></div></div>;
}

function ProfileLoadError({ error, onLogout }) {
  return <div className="denied-screen"><div className="denied-card"><div className="denied-icon"><AlertCircle size={27} /></div><h2>Profil admin tidak dapat diverifikasi</h2><p>Dashboard dikunci sampai role akun berhasil dibaca dari Firestore.</p><p>{error || 'Periksa koneksi dan aturan akses Firebase, lalu coba kembali.'}</p><button className="primary-button" onClick={onLogout}>Keluar</button></div></div>;
}

function Overview({ data, pendingClaims, onNavigate }) {
  const totalItems = data.items.length;
  const lost = data.items.filter((item) => (item.status_type || item.type || '').toUpperCase() === 'LOST').length;
  const found = data.items.filter((item) => (item.status_type || item.type || '').toUpperCase() === 'FOUND').length;
  const closed = data.items.filter((item) => ['RECEIVED', 'CLOSED', 'SELESAI'].includes((item.status || '').toUpperCase())).length;
  const monthItems = data.items.filter((item) => { const date = asDate(item.createdAt || item.date || item.created_at); return date && date.getMonth() === new Date().getMonth() && date.getFullYear() === new Date().getFullYear(); }).length;
  const trend = buildTrend(data.items);
  const spots = buildHotspots(data.items);
  const recent = [...data.items].sort((a, b) => (asDate(b.createdAt || b.date)?.getTime() || 0) - (asDate(a.createdAt || a.date)?.getTime() || 0)).slice(0, 5);
  return <>
    <PageHeading eyebrow="RABU, 28 OKTOBER 2026" title="Overview" subtitle="Pantau aktivitas dan bantu barang kembali ke pemiliknya." actions={<button className="outline-button" onClick={() => window.location.reload()}><RefreshCw size={15} /> Refresh data</button>} />
    <section className="welcome-banner"><div className="welcome-copy"><div className="welcome-label"><Sparkles size={14} /> CAMPUSLOST PULSE</div><h2>Halo, Admin <span>👋</span></h2><p>Ada <b>{pendingClaims.length} klaim</b> yang perlu perhatianmu hari ini. Mari pastikan setiap barang menemukan jalan pulang.</p><button className="welcome-link" onClick={() => onNavigate('claims')}>Tinjau klaim <ArrowRight size={15} /></button></div><div className="welcome-graphic"><div className="graphic-ring ring-a" /><div className="graphic-ring ring-b" /><div className="graphic-center"><PackageCheck size={29} /></div><div className="graphic-chip chip-a"><CheckCheck size={15} /> Barang kembali</div><div className="graphic-chip chip-b"><MapPin size={14} /> Fasilkom</div></div></section>
    <div className="section-title-row"><div><h3>Ringkasan aktivitas</h3><p>Ikhtisar laporan di seluruh kampus</p></div><span className="period-pill"><span className="live-dot" /> Bulan ini</span></div>
    <section className="stat-grid"><StatCard icon={Inbox} label="Total laporan" value={totalItems} trend={monthItems ? `+${monthItems} bulan ini` : 'Belum ada bulan ini'} tone="indigo" /><StatCard icon={Search} label="Barang hilang" value={lost} trend={`${totalItems ? Math.round(lost / totalItems * 100) : 0}% dari laporan`} tone="orange" /><StatCard icon={MapPin} label="Barang ditemukan" value={found} trend={`${totalItems ? Math.round(found / totalItems * 100) : 0}% dari laporan`} tone="teal" /><StatCard icon={PackageCheck} label="Berhasil kembali" value={closed} trend={totalItems ? `${Math.round(closed / totalItems * 100)}% tingkat penyelesaian` : 'Menunggu laporan'} tone="green" /></section>
    <section className="analytics-grid"><div className="panel trend-panel"><div className="panel-head"><div><h3>Tren laporan</h3><p>Aktivitas laporan dalam 7 hari terakhir</p></div><button className="period-pill">7 hari <ChevronDown size={13} /></button></div><div className="chart-legend"><span><i className="legend-lost" /> Hilang</span><span><i className="legend-found" /> Temuan</span><span className="chart-total"><b>{trend.reduce((sum, day) => sum + day.lost + day.found, 0)}</b> laporan</span></div><div className="bar-chart">{trend.map((day) => { const max = Math.max(1, ...trend.map((row) => row.lost + row.found)); return <div className="bar-column" key={day.label}><div className="bars"><div className="bar lost-bar" style={{ height: `${Math.max(day.lost ? 8 : 2, day.lost / max * 100)}%` }} title={`${day.lost} hilang`} /><div className="bar found-bar" style={{ height: `${Math.max(day.found ? 8 : 2, day.found / max * 100)}%` }} title={`${day.found} ditemukan`} /></div><span>{day.label}</span></div>; })}</div><div className="chart-axis"><span>0</span><span>Aktivitas harian</span></div></div>
      <div className="panel hotspot-panel"><div className="panel-head"><div><h3>Hotspot kampus</h3><p>Lokasi paling sering dilaporkan</p></div><button className="icon-button subtle" aria-label="Lihat hotspot"><MoreHorizontal size={19} /></button></div>{spots.length ? <div className="hotspot-list">{spots.slice(0, 4).map((spot, index) => <div className="hotspot-row" key={spot.name}><div className={`spot-marker marker-${index + 1}`}><MapPin size={16} /></div><div className="spot-info"><b>{spot.name}</b><span>{spot.count} laporan · {spot.lost} hilang</span></div><div className="spot-bar"><i style={{ width: `${Math.max(9, spot.count / spots[0].count * 100)}%` }} /></div><b className="spot-count">{spot.count}</b></div>)}</div> : <EmptyInline icon={MapPin} title="Belum ada titik laporan" text="Lokasi akan muncul setelah laporan masuk." />}</div></section>
    <section className="lower-grid"><div className="panel recent-panel"><div className="panel-head"><div><h3>Laporan terbaru</h3><p>Aktivitas baru dari mahasiswa</p></div><button className="text-button" onClick={() => onNavigate('news')}>Lihat semua <ArrowRight size={14} /></button></div>{recent.length ? <div className="table-wrap"><table><thead><tr><th>Barang</th><th>Jenis</th><th>Lokasi</th><th>Status</th><th>Waktu</th></tr></thead><tbody>{recent.map((item) => <ItemRow key={item.id} item={item} />)}</tbody></table></div> : <EmptyInline icon={Inbox} title="Belum ada laporan" text="Laporan dari aplikasi akan muncul di sini." />}</div><div className="panel priority-panel"><div className="panel-head"><div><h3>Perlu perhatian</h3><p>Antrean yang perlu ditinjau</p></div><span className="priority-count">{pendingClaims.length}</span></div><div className="priority-callout"><div className="priority-icon"><Clock3 size={18} /></div><div><b>{pendingClaims.length} klaim menunggu</b><span>Prioritaskan klaim yang paling lama.</span></div></div><button className="priority-link" onClick={() => onNavigate('claims')}>Buka antrean klaim <ArrowRight size={15} /></button><div className="priority-footer"><ShieldCheck size={14} /> Semua aktivitas admin tercatat.</div></div></section>
    <footer className="page-footer"><span>CampusLost Admin <b>·</b> Data diperbarui secara langsung</span><span><i className="live-dot" /> Sistem aktif</span></footer>
  </>;
}

function StatCard({ icon: Icon, label, value, trend, tone }) {
  return <article className="stat-card"><div className={`stat-icon ${tone}`}><Icon size={18} /></div><div className="stat-trend"><ArrowUpRight size={13} /> Live</div><span className="stat-label">{label}</span><strong>{value.toLocaleString('id-ID')}</strong><span className="stat-foot">{trend}</span></article>;
}

function PageHeading({ eyebrow, title, subtitle, actions }) {
  return <div className="page-heading"><div><div className="eyebrow">{eyebrow}</div><h1>{title}</h1><p>{subtitle}</p></div>{actions && <div className="heading-actions">{actions}</div>}</div>;
}

function ClaimsPage({ claims, items, users, onNotify }) {
  const [filter, setFilter] = useState('PENDING');
  const [search, setSearch] = useState('');
  const [busyId, setBusyId] = useState('');
  const [selected, setSelected] = useState(null);
  const enriched = useMemo(() => claims.map((claim) => ({ ...claim, item: items.find((item) => item.id === (claim.itemId || claim.item_id)), claimant: users.find((user) => user.id === (claim.userId || claim.claimant_user_id)) })), [claims, items, users]);
  const rows = enriched.filter((claim) => {
    const status = (claim.status || claim.claim_status || 'PENDING').toUpperCase();
    const term = search.toLowerCase();
    const searchable = `${claim.item?.title || ''} ${claim.claimant?.name || claim.claimant?.full_name || ''} ${claim.claimant?.nim || ''}`.toLowerCase();
    return (filter === 'ALL' || status === filter) && (!term || searchable.includes(term));
  }).sort((a, b) => (asDate(a.createdAt || a.created_at)?.getTime() || 0) - (asDate(b.createdAt || b.created_at)?.getTime() || 0));
  const decide = async (claim, status) => {
    setBusyId(claim.id);
    try {
      const patch = { status, claim_status: status, resolvedAt: serverTimestamp(), resolved_at: serverTimestamp(), verifiedByOfficerId: auth.currentUser.uid, verified_by_officer_id: auth.currentUser.uid };
      await updateDoc(doc(db, 'claims', claim.id), patch);
      if (status === 'APPROVED' && claim.item) await updateDoc(doc(db, 'items', claim.item.id), { status: 'CLAIMED' });
      onNotify(status === 'APPROVED' ? 'Klaim disetujui. Status barang diperbarui.' : 'Klaim ditolak.');
      setSelected(null);
    } catch (error) { onNotify(`Gagal memperbarui klaim: ${error.message}`); }
    finally { setBusyId(''); }
  };
  const counts = ['PENDING', 'APPROVED', 'REJECTED'].map((status) => ({ status, count: claims.filter((claim) => (claim.status || claim.claim_status || 'PENDING').toUpperCase() === status).length }));
  return <><PageHeading eyebrow="PENGELOLAAN KLAIM" title="Claims" subtitle="Tinjau bukti kepemilikan dan bantu klaim selesai dengan aman." actions={<div className="heading-count"><Clock3 size={15} /> {counts[0].count} menunggu</div>} /><div className="claims-kpis">{counts.map(({ status, count }) => <button className={`claim-kpi ${filter === status ? 'chosen' : ''}`} key={status} onClick={() => setFilter(status)}><span className={`status-dot ${status.toLowerCase()}`} />{statusLabel(status)}<b>{count}</b></button>)}</div><div className="panel claims-panel"><div className="list-toolbar"><div className="filter-tabs"><button className={filter === 'PENDING' ? 'selected' : ''} onClick={() => setFilter('PENDING')}>Prioritas <span>{counts[0].count}</span></button><button className={filter === 'APPROVED' ? 'selected' : ''} onClick={() => setFilter('APPROVED')}>Disetujui</button><button className={filter === 'REJECTED' ? 'selected' : ''} onClick={() => setFilter('REJECTED')}>Ditolak</button><button className={filter === 'ALL' ? 'selected' : ''} onClick={() => setFilter('ALL')}>Semua</button></div><label className="search-field"><Search size={15} /><input placeholder="Cari barang atau mahasiswa" value={search} onChange={(e) => setSearch(e.target.value)} /><Filter size={14} /></label></div>{rows.length ? <div className="table-wrap"><table className="claims-table"><thead><tr><th>BARANG & PEMOHON</th><th>BUKTI KLAIM</th><th>DIAJUKAN</th><th>STATUS</th><th></th></tr></thead><tbody>{rows.map((claim) => { const status = (claim.status || claim.claim_status || 'PENDING').toUpperCase(); return <tr key={claim.id}><td><div className="claim-item-cell"><div className="claim-thumb">{claim.item?.imageUrl ? <img src={claim.item.imageUrl} alt="" /> : <PackageCheck size={17} />}</div><div><b>{claim.item?.title || 'Barang tidak ditemukan'}</b><span>{claim.claimant?.name || claim.claimant?.full_name || 'Mahasiswa'}{claim.claimant?.nim ? ` · ${claim.claimant.nim}` : ''}</span></div></div></td><td><span className="proof-snippet">{claim.answer || claim.proof_answer || 'Tidak ada jawaban verifikasi'}</span></td><td>{formatRelative(claim.createdAt || claim.created_at)}</td><td><StatusPill status={status} /></td><td><button className="row-action" onClick={() => setSelected(claim)}>{status === 'PENDING' ? 'Tinjau' : 'Detail'} <ArrowRight size={13} /></button></td></tr>; })}</tbody></table></div> : <EmptyInline icon={FileCheck2} title="Tidak ada klaim di sini" text={search ? 'Coba kata kunci lain.' : 'Klaim yang sesuai filter akan muncul di sini.'} />}</div>{selected && <ClaimModal claim={selected} onClose={() => setSelected(null)} onDecide={decide} busy={busyId === selected.id} />}</>;
}

function ClaimModal({ claim, onClose, onDecide, busy }) {
  const status = (claim.status || claim.claim_status || 'PENDING').toUpperCase();
  return <div className="modal-backdrop" onMouseDown={(event) => { if (event.target === event.currentTarget) onClose(); }}><div className="review-modal"><div className="modal-top"><div><div className="eyebrow">TINJAUAN KLAIM</div><h2>{claim.item?.title || 'Detail klaim'}</h2></div><button className="icon-button" onClick={onClose}><X size={18} /></button></div><div className="review-person"><div className="profile-avatar">{(claim.claimant?.name || 'M').slice(0, 1).toUpperCase()}</div><div><b>{claim.claimant?.name || claim.claimant?.full_name || 'Mahasiswa'}</b><span>{claim.claimant?.nim || 'NIM tidak tersedia'} · {claim.claimant?.email || claim.claimant?.email_campus || 'Email tidak tersedia'}</span></div></div><div className="proof-box"><div className="proof-label"><ShieldCheck size={15} /> BUKTI KEPEMILIKAN</div><p>{claim.answer || claim.proof_answer || 'Pengaju tidak menambahkan jawaban.'}</p></div><div className="review-info"><div><span>Lokasi laporan</span><b>{claim.item?.location || claim.item?.location_name || 'Tidak dicantumkan'}</b></div><div><span>Waktu pengajuan</span><b>{formatDate(claim.createdAt || claim.created_at)}</b></div></div><p className="privacy-note"><AlertCircle size={14} /> Pastikan bukti cocok dengan detail barang sebelum memberi keputusan.</p><div className="modal-actions"><button className="outline-button" onClick={onClose}>Tutup</button>{status === 'PENDING' && <><button className="reject-button" disabled={busy} onClick={() => onDecide(claim, 'REJECTED')}><XCircle size={15} /> Tolak</button><button className="primary-button" disabled={busy} onClick={() => onDecide(claim, 'APPROVED')}><CheckCheck size={15} /> {busy ? 'Menyimpan...' : 'Setujui klaim'}</button></>}</div></div></div>;
}

function NewsPage({ items, loading, onNotify }) {
  const [kind, setKind] = useState('ALL');
  const [term, setTerm] = useState('');
  const [busy, setBusy] = useState('');
  const visible = [...items].sort((a, b) => (asDate(b.createdAt || b.date || b.created_at)?.getTime() || 0) - (asDate(a.createdAt || a.date || a.created_at)?.getTime() || 0)).filter((item) => {
    const type = (item.status_type || item.type || '').toUpperCase();
    return (kind === 'ALL' || type === kind) && `${item.title || ''} ${item.location || item.location_name || ''} ${item.category || ''}`.toLowerCase().includes(term.toLowerCase());
  });
  const updateStatus = async (item, status) => { setBusy(item.id); try { await updateDoc(doc(db, 'items', item.id), { status }); onNotify(`Status laporan diubah menjadi ${statusLabel(status)}.`); } catch (error) { onNotify(`Gagal mengubah status: ${error.message}`); } finally { setBusy(''); } };
  return <><PageHeading eyebrow="LAPORAN KOMUNITAS" title="News" subtitle="Laporan terbaru dari mahasiswa di lingkungan kampus." actions={<div className="heading-count"><Activity size={15} /> {items.length} laporan</div>} /><div className="news-tools"><div className="filter-tabs"><button className={kind === 'ALL' ? 'selected' : ''} onClick={() => setKind('ALL')}>Semua</button><button className={kind === 'LOST' ? 'selected' : ''} onClick={() => setKind('LOST')}>Hilang</button><button className={kind === 'FOUND' ? 'selected' : ''} onClick={() => setKind('FOUND')}>Temuan</button></div><label className="search-field"><Search size={15} /><input placeholder="Cari laporan..." value={term} onChange={(e) => setTerm(e.target.value)} /></label></div>{loading ? <div className="panel loading-panel"><RefreshCw className="spin" /> Memuat laporan...</div> : visible.length ? <div className="news-grid">{visible.map((item) => <article className="news-card" key={item.id}><div className="news-image">{item.imageUrl ? <img src={item.imageUrl} alt={item.title || 'Foto barang'} /> : <div className="image-placeholder"><FileSearch size={27} /></div>}<span className={`type-chip ${(item.status_type || item.type || '').toLowerCase()}`}>{typeLabel(item.status_type || item.type)}</span><button className="image-menu icon-button" title="Tutup laporan" disabled={busy === item.id} onClick={() => updateStatus(item, 'CLOSED')}><MoreHorizontal size={18} /></button></div><div className="news-content"><div className="news-category">{item.category || 'Lainnya'} <span>·</span> {formatRelative(item.createdAt || item.date || item.created_at)}</div><h3>{item.title || 'Tanpa judul'}</h3><div className="news-location"><MapPin size={14} /> {item.location || item.location_name || 'Lokasi tidak dicantumkan'}</div><p>{item.description || 'Tidak ada deskripsi tambahan.'}</p><div className="news-card-footer"><StatusPill status={(item.status || 'OPEN').toUpperCase()} /><button className="text-button" disabled={busy === item.id} onClick={() => updateStatus(item, item.status === 'CLOSED' ? 'OPEN' : 'CLOSED')}>{busy === item.id ? 'Menyimpan...' : item.status === 'CLOSED' ? 'Aktifkan' : 'Tutup laporan'} <ArrowRight size={13} /></button></div></div></article>)}</div> : <div className="panel"><EmptyInline icon={Inbox} title="Belum ada laporan" text="Laporan terbaru akan tampil di sini." /></div>}</>;
}

function SystemPage({ users, items, claims }) {
  const [userSearch, setUserSearch] = useState('');
  const pending = claims.filter((claim) => (claim.status || claim.claim_status || 'PENDING').toUpperCase() === 'PENDING').length;
  const visibleUsers = users.filter((user) => `${user.name || user.full_name || ''} ${user.email || user.email_campus || ''} ${user.nim || ''}`.toLowerCase().includes(userSearch.toLowerCase())).slice(0, 8);

  return <><PageHeading eyebrow="PENGELOLAAN SISTEM" title="Modal" subtitle="Kontrol operasional untuk menjaga layanan CampusLost tetap rapi." /><div className="system-banner"><div className="system-banner-icon"><SlidersHorizontal size={22} /></div><div><span>STATUS SISTEM</span><h2>Semua aktivitas dalam satu kendali.</h2><p>Ringkasan akses dan koleksi data yang terhubung ke Firebase CampusLost.</p></div><div className="system-online"><i className="live-dot" /> Terhubung</div></div><div className="system-grid"><div className="panel system-panel"><div className="panel-head"><div><h3>Pengguna kampus</h3><p>Akun yang terdaftar di CampusLost</p></div><div className="system-panel-icon"><Users size={17} /></div></div><div className="system-number">{users.length}<span>pengguna</span></div><div className="system-separator" /><div className="system-meta"><span><i className="role-dot student" /> Mahasiswa</span><b>{users.filter((u) => (u.role || 'mahasiswa') === 'mahasiswa').length}</b></div><div className="system-meta"><span><i className="role-dot admin" /> Admin</span><b>{users.filter((u) => u.role === 'admin').length}</b></div><div className="module-note"><ShieldCheck size={15} /> Role dikelola pada profil pengguna di Firestore.</div></div><div className="panel system-panel"><div className="panel-head"><div><h3>Kondisi antrean</h3><p>Status data operasional saat ini</p></div><div className="system-panel-icon amber"><Clock3 size={17} /></div></div><div className="system-number">{pending}<span>klaim tertunda</span></div><div className="system-separator" /><div className="system-meta"><span><i className="role-dot student" /> Total laporan</span><b>{items.length}</b></div><div className="system-meta"><span><i className="role-dot admin" /> Klaim selesai</span><b>{claims.length - pending}</b></div><div className="module-note"><Activity size={15} /> Data berubah otomatis mengikuti Firestore.</div></div><div className="panel system-panel policy-panel"><div className="panel-head"><div><h3>Prinsip pengelolaan</h3><p>Pengingat untuk keputusan admin</p></div><div className="system-panel-icon green"><FileCheck2 size={17} /></div></div><div className="policy-row"><div className="policy-check"><Check size={13} /></div><div><b>Periksa bukti klaim</b><span>Bandingkan jawaban dengan detail barang.</span></div></div><div className="policy-row"><div className="policy-check"><Check size={13} /></div><div><b>Catat perubahan status</b><span>Setiap keputusan dicatat pada dokumen klaim.</span></div></div><div className="policy-row"><div className="policy-check"><Check size={13} /></div><div><b>Jaga informasi pribadi</b><span>Gunakan data hanya untuk penyelesaian kasus.</span></div></div></div><div className="panel user-directory"><div className="panel-head"><div><h3>Direktori pengguna</h3><p>Telusuri akun dan identitas mahasiswa terdaftar</p></div><label className="search-field"><Search size={15} /><input placeholder="Nama, email, atau NIM" value={userSearch} onChange={(e) => setUserSearch(e.target.value)} /></label></div><div className="table-wrap"><table><thead><tr><th>NAMA PENGGUNA</th><th>NIM</th><th>EMAIL KAMPUS</th><th>ROLE</th></tr></thead><tbody>{visibleUsers.map((person) => <tr key={person.id}><td><div className="directory-person"><div className="profile-avatar directory-avatar">{(person.name || person.full_name || 'M').slice(0, 1).toUpperCase()}</div><b>{person.name || person.full_name || 'Mahasiswa'}</b></div></td><td>{person.nim || '—'}</td><td>{person.email || person.email_campus || '—'}</td><td><span className={`role-badge ${person.role === 'admin' ? 'is-admin' : ''}`}>{person.role || 'mahasiswa'}</span></td></tr>)}</tbody></table>{visibleUsers.length === 0 && <EmptyInline icon={Users} title="Pengguna tidak ditemukan" text="Coba kata kunci nama, email, atau NIM yang berbeda." />}</div></div></div><div className="security-callout"><AlertCircle size={17} /><div><b>Keamanan Firestore perlu dikonfigurasi</b><span>Role check pada halaman web membantu alur admin, tetapi aturan Firestore harus membatasi akses admin di sisi server juga.</span></div></div></>;
}

function SettingsPage({ profile, email, onLogout }) {
  return <><PageHeading eyebrow="PREFERENSI AKUN" title="Settings" subtitle="Informasi akses dan preferensi ruang kerja admin." /><div className="settings-grid"><section className="panel settings-panel"><div className="settings-heading"><div className="settings-icon"><Users size={18} /></div><div><h3>Profil administrator</h3><p>Identitas yang digunakan untuk aktivitas dashboard.</p></div></div><div className="settings-profile"><div className="profile-avatar large">{(profile?.name || email || 'A').slice(0, 1).toUpperCase()}</div><div><b>{profile?.name || 'Admin CampusLost'}</b><span>{email}</span><em><ShieldCheck size={12} /> Admin terverifikasi</em></div></div><div className="settings-fields"><div><span>Nama tampilan</span><b>{profile?.name || profile?.full_name || 'Admin CampusLost'}</b></div><div><span>Email akun</span><b>{email}</b></div><div><span>Peran akses</span><b className="role-badge">{profile?.role || 'admin'}</b></div></div></section><section className="panel settings-panel"><div className="settings-heading"><div className="settings-icon purple"><Bell size={18} /></div><div><h3>Preferensi sistem</h3><p>Informasi koneksi dan tampilan aplikasi.</p></div></div><div className="preference-row"><div><b>Sinkronisasi data</b><span>Data diperbarui langsung dari Firestore.</span></div><span className="setting-state"><i className="live-dot" /> Aktif</span></div><div className="preference-row"><div><b>Zona waktu</b><span>Waktu aktivitas laporan dan klaim.</span></div><strong>WIB · UTC+7</strong></div><div className="preference-row"><div><b>Versi dashboard</b><span>CampusLost Admin Console</span></div><strong>0.1.0</strong></div></section></div><section className="panel danger-panel"><div><h3>Keluar dari dashboard</h3><p>Sesi admin akan ditutup pada perangkat ini.</p></div><button className="reject-button" onClick={onLogout}><LogOut size={15} /> Keluar</button></section><footer className="page-footer"><span>CampusLost Admin <b>·</b> Ruang kerja administrator</span><span>Versi 0.1.0</span></footer></>;
}

function ItemRow({ item }) {
  const type = item.status_type || item.type || 'LOST';
  return <tr><td><div className="table-item"><div className="table-thumb">{item.imageUrl ? <img src={item.imageUrl} alt="" /> : <PackageCheck size={15} />}</div><b>{item.title || 'Tanpa judul'}</b></div></td><td><span className={`type-text ${type.toLowerCase()}`}><i />{typeLabel(type)}</span></td><td><span className="table-location"><MapPin size={13} />{item.location || item.location_name || '—'}</span></td><td><StatusPill status={(item.status || 'OPEN').toUpperCase()} /></td><td className="muted-cell">{formatRelative(item.createdAt || item.date || item.created_at)}</td></tr>;
}

function StatusPill({ status }) {
  const normalized = (status || 'OPEN').toUpperCase();
  const tone = ['APPROVED', 'RECEIVED', 'CLOSED', 'SELESAI'].includes(normalized) ? 'green' : ['REJECTED'].includes(normalized) ? 'red' : ['CLAIMED'].includes(normalized) ? 'purple' : 'amber';
  return <span className={`status-pill ${tone}`}><i />{statusLabel(normalized)}</span>;
}

function EmptyInline({ icon: Icon, title, text }) { return <div className="empty-inline"><div className="empty-icon"><Icon size={20} /></div><b>{title}</b><span>{text}</span></div>; }

function buildTrend(items) {
  const days = [];
  const today = new Date();
  for (let offset = 6; offset >= 0; offset -= 1) {
    const date = new Date(today.getFullYear(), today.getMonth(), today.getDate() - offset);
    const key = `${date.getFullYear()}-${date.getMonth()}-${date.getDate()}`;
    const matching = items.filter((item) => { const d = asDate(item.createdAt || item.date || item.created_at); return d && `${d.getFullYear()}-${d.getMonth()}-${d.getDate()}` === key; });
    days.push({ label: new Intl.DateTimeFormat('id-ID', { weekday: 'short' }).format(date), lost: matching.filter((i) => (i.status_type || i.type || '').toUpperCase() === 'LOST').length, found: matching.filter((i) => (i.status_type || i.type || '').toUpperCase() === 'FOUND').length });
  }
  return days;
}

function buildHotspots(items) {
  const map = new Map();
  items.forEach((item) => { const name = (item.location || item.location_name || '').trim(); if (!name) return; const entry = map.get(name) || { name, count: 0, lost: 0 }; entry.count += 1; if ((item.status_type || item.type || '').toUpperCase() === 'LOST') entry.lost += 1; map.set(name, entry); });
  return [...map.values()].sort((a, b) => b.count - a.count);
}

function formatRelative(value) {
  const date = asDate(value);
  if (!date) return '—';
  const days = Math.floor((Date.now() - date.getTime()) / 86400000);
  if (days <= 0) return `Hari ini, ${date.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' })}`;
  if (days === 1) return 'Kemarin';
  if (days < 7) return `${days} hari lalu`;
  return date.toLocaleDateString('id-ID', { day: 'numeric', month: 'short' });
}

function formatDate(value) { const date = asDate(value); return date ? date.toLocaleString('id-ID', { dateStyle: 'medium', timeStyle: 'short' }) : 'Waktu belum tersedia'; }
function typeLabel(value) { return (value || '').toUpperCase() === 'FOUND' ? 'Temuan' : 'Hilang'; }
function statusLabel(value) { return ({ PENDING: 'Menunggu', APPROVED: 'Disetujui', REJECTED: 'Ditolak', OPEN: 'Aktif', RECEIVED: 'Kembali', CLOSED: 'Ditutup', CLAIMED: 'Diklaim', SELESAI: 'Selesai' })[value] || value; }

export default App;
