MODULE = ALPM	 PACKAGE = ALPM	PREFIX = alpm_

#define hv_store_trans_flag(hash, key, arg, flag) \
	hv_stores(hash, #key, newSViv((arg & flag) ? 1 : 0))
#define hv_fetch_trans_flag(hash, key, var, flag) do { \
	SV** val = hv_fetchs((HV*) SvRV(hash), #key, 0); \
	if(val && SvTRUE(*val)) { var |= flag; } \
} while(0)

TYPEMAP: <<TMAP

alpm_transflag_t ALPM_TRANSFLAG

INPUT
ALPM_TRANSFLAG
	$var = 0;
	hv_fetch_trans_flag($arg, alldeps, $var, ALPM_TRANS_FLAG_ALLDEPS);
	hv_fetch_trans_flag($arg, allexplicit, $var, ALPM_TRANS_FLAG_ALLEXPLICIT);
	hv_fetch_trans_flag($arg, cascade, $var, ALPM_TRANS_FLAG_CASCADE);
	hv_fetch_trans_flag($arg, dbonly, $var, ALPM_TRANS_FLAG_DBONLY);
	hv_fetch_trans_flag($arg, downloadonly, $var, ALPM_TRANS_FLAG_DOWNLOADONLY);
	hv_fetch_trans_flag($arg, force, $var, ALPM_TRANS_FLAG_FORCE);
	hv_fetch_trans_flag($arg, needed, $var, ALPM_TRANS_FLAG_NEEDED);
	hv_fetch_trans_flag($arg, noconflicts, $var, ALPM_TRANS_FLAG_NOCONFLICTS);
	hv_fetch_trans_flag($arg, nodeps, $var, ALPM_TRANS_FLAG_NODEPS);
	hv_fetch_trans_flag($arg, nodepversion, $var, ALPM_TRANS_FLAG_NODEPVERSION);
	hv_fetch_trans_flag($arg, nolock, $var, ALPM_TRANS_FLAG_NOLOCK);
	hv_fetch_trans_flag($arg, nosave, $var, ALPM_TRANS_FLAG_NOSAVE);
	hv_fetch_trans_flag($arg, noscriptlet, $var, ALPM_TRANS_FLAG_NOSCRIPTLET);
	hv_fetch_trans_flag($arg, recurse, $var, ALPM_TRANS_FLAG_RECURSE);
	hv_fetch_trans_flag($arg, recurseall, $var, ALPM_TRANS_FLAG_RECURSEALL);
	hv_fetch_trans_flag($arg, unneeded, $var, ALPM_TRANS_FLAG_UNNEEDED);

OUTPUT
ALPM_TRANSFLAG
	HV *hash = newHV();
	hv_store_trans_flag(hash, alldeps, $var, ALPM_TRANS_FLAG_ALLDEPS);
	hv_store_trans_flag(hash, allexplicit, $var, ALPM_TRANS_FLAG_ALLEXPLICIT);
	hv_store_trans_flag(hash, cascade, $var, ALPM_TRANS_FLAG_CASCADE);
	hv_store_trans_flag(hash, dbonly, $var, ALPM_TRANS_FLAG_DBONLY);
	hv_store_trans_flag(hash, downloadonly, $var, ALPM_TRANS_FLAG_DOWNLOADONLY);
	hv_store_trans_flag(hash, force, $var, ALPM_TRANS_FLAG_FORCE);
	hv_store_trans_flag(hash, needed, $var, ALPM_TRANS_FLAG_NEEDED);
	hv_store_trans_flag(hash, noconflicts, $var, ALPM_TRANS_FLAG_NOCONFLICTS);
	hv_store_trans_flag(hash, nodeps, $var, ALPM_TRANS_FLAG_NODEPS);
	hv_store_trans_flag(hash, nodepversion, $var, ALPM_TRANS_FLAG_NODEPVERSION);
	hv_store_trans_flag(hash, nolock, $var, ALPM_TRANS_FLAG_NOLOCK);
	hv_store_trans_flag(hash, nosave, $var, ALPM_TRANS_FLAG_NOSAVE);
	hv_store_trans_flag(hash, noscriptlet, $var, ALPM_TRANS_FLAG_NOSCRIPTLET);
	hv_store_trans_flag(hash, recurse, $var, ALPM_TRANS_FLAG_RECURSE);
	hv_store_trans_flag(hash, recurseall, $var, ALPM_TRANS_FLAG_RECURSEALL);
	hv_store_trans_flag(hash, unneeded, $var, ALPM_TRANS_FLAG_UNNEEDED);
	sv_setsv($arg, newRV_noinc((SV*) hash));

TMAP

alpm_transflag_t
alpm_trans_get_flags(handle)
		ALPM_Handle handle

NO_OUTPUT int
alpm_trans_init(handle, flags=0)
		ALPM_Handle handle
		alpm_transflag_t flags
	POSTCALL:
		if(RETVAL != 0) alpm_hthrow(handle);

NO_OUTPUT int
alpm_trans_interrupt(handle)
		ALPM_Handle handle
	POSTCALL:
		if(RETVAL != 0) alpm_hthrow(handle);
