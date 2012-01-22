#include <stdlib.h>
#include <alpm.h>
#include "alpm_xs.h"

/* SCALAR CONVERSIONS */

#define c2p_str(S) newSVpv(S, 0)

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
c2p_conflict(void *p);
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
