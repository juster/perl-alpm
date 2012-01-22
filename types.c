#include <stdlib.h>
#include <alpm.h>
#include "alpm_xs.h"

/* SCALAR CONVERSIONS */

SV*
c2p_pkg(void *p)
{
	SV *rv = sv_newmortal();
	return sv_setref_pv(rv, "ALPM::Package", p);
}

#define p2c_pkg(P) SvPV(P)

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

/* converts siglevel bitflags into a string */
SV*
c2p_siglevel(alpm_siglevel_t sig)
{
	char *type, *lvl;
	HV *hv;
	hv = newHV();

	if(sig & ALPM_SIG_USE_DEFAULT){
		type = "default";
	}else if(sig & ALPM_SIG_PACKAGE_OPTIONAL){
		type = "package";
		lvl = "optional";
	}else if(sig & ALPM_SIG_PACKAGE_MARGINAL_OK){
		type = "package";
		lvl ="marginal";
	}else if(sig & ALPM_SIG_PACKAGE_UNKNOWN_OK){
		type = "package";
		lvl = "unknown";
	}else if(sig & ALPM_SIG_DATABASE_OPTIONAL){
		type = "database";
		lvl = "optional";
	}else if(sig & ALPM_SIG_DATABASE_MARGINAL_OK){
		type = "database";
		lvl ="marginal";
	}else if(sig & ALPM_SIG_DATABASE_UNKNOWN_OK){
		type = "database";
		lvl = "unknown";
	}

	hv_store(hv, "type", 4, newSVpv(type, 0), 0);
	if(lvl){
		hv_store(hv, "level", 5, newSVpv(lvl, 0), 0);
	}
	return newRV_noinc((SV*)hv);
}

/* converts a siglevel hashref into bitflags */
alpm_siglevel_t
p2c_siglevel(SV *href)
{
	HV *hv;
	SV **val;
	char *str;
	STRLEN len;
	int db;
	alpm_siglevel_t ret;

	hv = (HV*)SvRV(href);

	val = hv_fetch(hv, "type", 4, 0);
	if(!SvPOK(*val)){
		goto error;
	}
	str = SvPV(*val, len);
	if(strncmp(str, "default", len) == 0){
		return ALPM_SIG_USE_DEFAULT;
	}else if(strncmp(str, "package") == 0){
		db = 0;
	}else if(strncmp(str, "database") == 0){
		db = 1;
	}else{
		goto error;
	}

	val = hv_fetch(hv, "level", 5, 0);
	if(!SvPOK(*val)){
		goto error;
	}
	str = SvPV(*val, len);
	if(strncmp(str, "optional", len) == 0){
		ret = (db ? ALPM_SIG_DATABASE_OPTIONAL
		  : ALPM_SIG_PACKAGE_OPTIONAL);
	}else if(strncmp(str, "marginal") == 0){
		ret = (db ? ALPM_SIG_DATABASE_MARGINAL
		  : ALPM_SIG_PACKAGE_MARGINAL);
	}else if(strncmp(str, "unknown") == 0){
		ret = (db ? ALPM_SIG_DATABASE_UNKNOWN
		  : ALPM_SIG_PACKAGE_UNKNOWN);
	}else{
		goto error;
	}

	return ret;
	
error:
	croak("ALPM Error: Invalid siglevel hashref");
	return 0; /* unreachable */
}

void freedepend(void *p)
{
	free((alpm_depend_t*)p);
}

void freeconflict(void *p)
{
	alpm_conflict_t *c;
	c = p;
	freedepend(c->reason);
	free(c);
}

/* LIST CONVERSIONS */

AV *
list2av(alpm_list_t *L, scalarmap F)
{
	AV av;
	av = newAV();
	while(L){
		av_push(av, F(L->data);
		L = alpm_list_next(L);
	}
	return av;
}

alpm_list_t *
av2list(AV *A, listmap F)
{
	alpm_list_t *L;
	int i;
	for(i = 0; i < av_len(A); i++){
		L = alpm_list_add(L, F(av_fetch(A, i, 0)));
	}
	return L;
}

#undef c2p_str
