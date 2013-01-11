#include <stdlib.h>
#include <alpm.h>

/* Perl API headers. */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "types.h"

/* SCALAR CONVERSIONS */

SV*
c2p_str(void *str)
{
	return newSVpv(str, 0);
}

const char*
p2c_str(SV *sv)
{
	char *pstr, *cstr;
	STRLEN len;

	/* pstr is not guaranteed to be NULL terminated so make a copy */
	pstr = SvPV(sv, len);
	cstr = calloc(len + 1, sizeof(char));
	memcpy(cstr, pstr, len);
	return cstr;
}

SV*
c2p_pkg(void *p)
{
	SV *rv = newSV(0);
	return sv_setref_pv(rv, "ALPM::Package", p);
}

ALPM_Package
p2c_pkg(SV *pkgobj)
{
	return INT2PTR(ALPM_Package, SvIV((SV*)SvRV(pkgobj)));
}

ALPM_DB
p2c_db(SV *db)
{
	return INT2PTR(ALPM_DB, SvIV((SV*)SvRV(db)));
}

SV*
c2p_db(void *db)
{
	SV *rv = newSV(0);
	sv_setref_pv(rv, "ALPM::DB", db);
	return rv;
}

SV*
c2p_localdb(void *db)
{
	SV *rv = newSV(0);
	sv_setref_pv(rv, "ALPM::DB::Local", db);
	return rv;
}

SV*
c2p_syncdb(void *db)
{
	SV *rv = newSV(0);
	sv_setref_pv(rv, "ALPM::DB::Sync", db);
	return rv;
}

SV*
c2p_depmod(alpm_depmod_t mod)
{
	SV *sv;
	char *cmp;
	switch(mod){
	case ALPM_DEP_MOD_ANY: cmp = ""; break; /* ? */
	case ALPM_DEP_MOD_EQ: cmp = "="; break;
	case ALPM_DEP_MOD_GE: cmp = ">="; break;
	case ALPM_DEP_MOD_LE: cmp = "<="; break;
	case ALPM_DEP_MOD_GT: cmp = ">"; break;
	case ALPM_DEP_MOD_LT: cmp = "<"; break;
	default: cmp = "?";
	}

	return newSVpv(cmp, 0);
}

SV*
c2p_depend(void *p)
{
	alpm_depend_t *dep;
	HV *hv;
	hv = newHV();
	dep = p;

	hv_store(hv, "name", 4, newSVpv(dep->name, 0), 0);
	hv_store(hv, "version", 7, newSVpv(dep->version, 0), 0);
	hv_store(hv, "mod", 3, c2p_depmod(dep->mod), 0);
	return newRV_noinc((SV*)hv);
}

SV*
c2p_conflict(void *p)
{
	alpm_conflict_t *c;
	HV *hv;
	hv = newHV();
	c = p;

	hv_store(hv, "package1", 8, newSVpv(c->package1, 0), 0);
	hv_store(hv, "package2", 8, newSVpv(c->package2, 0), 0);
	hv_store(hv, "reason", 6, c2p_depend(c->reason), 0);
	return newRV_noinc((SV*)hv);
}

static SV*
c2p_file(alpm_file_t *file){
	HV *hv;
	hv = newHV();
	hv_store(hv, "name", 4, newSVpv(file->name, 0), 0);
	hv_store(hv, "size", 4, newSViv(file->size), 0);
	hv_store(hv, "mode", 4, newSViv(file->mode), 0);
	return newRV_noinc((SV*)hv);
}

SV*
c2p_filelist(void *flistPtr){
	alpm_filelist_t *flist;
	AV *av;
	int i;

	flist = flistPtr;
	av = newAV();
	for(i = 0; i < flist->count; i++){
		av_push(av, c2p_file(flist->files + i));
	}
	return newRV_noinc((SV*)av);
}

/* converts siglevel bitflags into a string (default/never) or hashref */
SV*
c2p_siglevel(alpm_siglevel_t sig)
{
	HV *hv;
	AV *flags;

	if(sig & ALPM_SIG_USE_DEFAULT){
		return newSVpv("default", 7);
	}else if(!sig){
		return newSVpv("never", 5);
	}

	hv = newHV();

#define PUSHFLAG(F) av_push(flags, newSVpv(F, 0))

	flags = newAV();
	if(sig & ALPM_SIG_PACKAGE){
		if(sig & ALPM_SIG_PACKAGE_OPTIONAL){
			PUSHFLAG("optional");
		}else{
			PUSHFLAG("required");
		}
		if(sig & ALPM_SIG_PACKAGE_MARGINAL_OK & ALPM_SIG_PACKAGE_UNKNOWN_OK){
			PUSHFLAG("trustall");
		}
	}else{
		PUSHFLAG("never");
	}
	hv_store(hv, "pkg", 3, newRV_noinc((SV*)flags), 0);

	flags = newAV();
	if(sig & ALPM_SIG_DATABASE){
		if(sig & ALPM_SIG_DATABASE_OPTIONAL){
			PUSHFLAG("optional");
		}else{
			PUSHFLAG("required");
		}
		if(sig & ALPM_SIG_DATABASE_MARGINAL_OK & ALPM_SIG_DATABASE_UNKNOWN_OK){
			PUSHFLAG("trustall");
		}
	}else{
		PUSHFLAG("never");
	}
	hv_store(hv, "db", 2, newRV_noinc((SV*)flags), 0);

#undef PUSHFLAG

	return newRV_noinc((SV*)hv);
}

#define TRUST_NEVER 1
#define TRUST_REQ 2
#define TRUST_OPT 4
#define TRUST_ALL 8

static int
trustmask(HV *lvlhash, char *lvl, int len)
{
	SV **ref, **flag;
	AV *flags;
	I32 i, x;
	char *str;
	STRLEN svlen;
	int mask;

	ref = hv_fetch(lvlhash, lvl, len, 0);
	if(ref == NULL || !SvROK(*ref) || SvTYPE(SvRV(*ref)) != SVt_PVAV){
		croak("SigLevel hashref must contain array refs as values");
	}

	flags = (AV*)SvRV(*ref);
	x = av_len(flags);
	if(x == -1){
		croak("Bad %s SigLevel value: array is empty");
	}

	mask = 0;
	for(i = 0; i <= x; i++){
		flag = av_fetch(flags, i, 0);
		if(!SvPOK(*flag)) goto averr;

		str = SvPV(*flag, svlen);
		if(strncmp("never", str, svlen) == 0){
			if(mask & ~TRUST_NEVER) goto neverr;
			mask |= TRUST_NEVER;
		}else if(mask & TRUST_NEVER){
			goto neverr;
		}else if(strncmp("optional", str, svlen) == 0){
			if(mask & TRUST_REQ) goto opterr;
			mask |= TRUST_OPT;
		}else if(strncmp("required", str, svlen) == 0){
			if(mask & TRUST_OPT) goto opterr;
			mask |= TRUST_REQ;
		}else if(strncmp("trustall", str, svlen) == 0){
			/* trustall may be combined with optional or required */
			mask |= TRUST_ALL;
		}
	}
	return mask;

neverr:
	croak("Bad %s SigLevel: the never trust level cannot be combined.", lvl);

opterr:
	croak("Bad %s SigLevel: trust cannot be both required and optional", lvl);

averr:
	croak("Bad %s SigLevel: valid elements are never, required, optional, or trustall", lvl);
}

/* converts a siglevel string or hashref into bitflags */
alpm_siglevel_t
p2c_siglevel(SV *sig)
{
	HV *hv;
	char *str;
	STRLEN len;
	int mask;
	alpm_siglevel_t ret;

	if(SvPOK(sig)){
		str = SvPV(sig, len);
		if(strncmp(str, "default", len) == 0){
			return ALPM_SIG_USE_DEFAULT;
		}else if(strncmp(str, "never", len) == 0){
			return 0;
		}else {
			/* XXX: might not be null terminated? */
			croak("Unrecognized SigLevel string: %s", str);
		}
	}

	if(!SvROK(sig) || SvTYPE(SvRV(sig)) != SVt_PVHV){
		croak("SigLevel must be a string or hash reference");
	}

	hv = (HV*)SvRV(sig);

#define MERGEMASK(SYM) \
	if(mask != TRUST_NEVER){ \
		ret |= ALPM_SIG_ ## SYM; \
		if(mask & TRUST_OPT){ \
			ret |= ALPM_SIG_ ## SYM ## _OPTIONAL; \
		} \
		if(mask & TRUST_ALL){ \
			ret |= ALPM_SIG_## SYM ## _MARGINAL_OK | ALPM_SIG_ ## SYM ## _UNKNOWN_OK; \
		} \
	}

	ret = 0;
	mask = trustmask(hv, "pkg", 3);
	MERGEMASK(PACKAGE)
	mask = trustmask(hv, "db", 2);
	MERGEMASK(DATABASE)

#undef MERGEMASK

	return ret;
}

#undef TRUST_NEVER
#undef TRUST_REQ
#undef TRUST_OPT
#undef TRUST_ALL

SV*
c2p_pkgreason(alpm_pkgreason_t rsn)
{
	switch(rsn){
	case ALPM_PKG_REASON_EXPLICIT:
		return newSVpv("explicit", 0);
	case ALPM_PKG_REASON_DEPEND:
		return newSVpv("implicit", 0);
	}

	croak("unrecognized pkgreason enum");
}

alpm_pkgreason_t
p2c_pkgreason(SV *sv)
{
	alpm_pkgreason_t rsn;
	STRLEN len;
	char *rstr;

	if(SvIOK(sv)){
		switch(SvIV(sv)){
		case 0: return ALPM_PKG_REASON_EXPLICIT;
		case 1: return ALPM_PKG_REASON_DEPEND;
		}
		croak("integer reasons must be 0 or 1");
	}else if(SvPOK(sv)){
		rstr = SvPV(sv, len);
		if(strncmp(rstr, "explicit", len) == 0){
			return ALPM_PKG_REASON_EXPLICIT;
		}else if(strncmp(rstr, "implicit", len) == 0
			|| strncmp(rstr, "depend", len) == 0){
			return ALPM_PKG_REASON_DEPEND;
		}else{
			croak("string reasons can only be explicit or implicit/depend");
		}
	}else{
		croak("reasons can only be integers or strings");
	}
}

/* LIST CONVERSIONS */

AV *
list2av(alpm_list_t *L, scalarmap F)
{
	AV *av;
	av = newAV();
	while(L){
		av_push(av, F(L->data));
		L = alpm_list_next(L);
	}
	return av;
}

alpm_list_t *
av2list(AV *A, listmap F)
{
	alpm_list_t *L;
	int i;
	SV **sv;

	for(i = 0; i < av_len(A); i++){
		sv = av_fetch(A, i, 0);
		L = alpm_list_add(L, F(*sv));
	}
	return L;
}

void
freedepend(void *p)
{
	free((alpm_depend_t*)p);
}

void
freeconflict(void *p)
{
	alpm_conflict_t *c;
	c = p;
	freedepend(c->reason);
	free(c);
}
