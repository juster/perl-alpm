#ifndef _ALPMXS_TYPES
#define _ALPMXS_TYPES

/* TYPEDEFS */

typedef int negative_is_error;
typedef alpm_handle_t * ALPM_Handle;
typedef alpm_db_t * ALPM_DB;
typedef alpm_db_t * ALPM_LocalDB;
typedef alpm_db_t * ALPM_SyncDB;
typedef alpm_pkg_t * ALPM_Package;
typedef alpm_pkg_t * ALPM_PackageFree;
typedef alpm_pkg_t * ALPM_PackageOrNull;
typedef alpm_grp_t * ALPM_Group;

typedef alpm_depend_t * DependHash;
typedef alpm_conflict_t * ConflictArray;

typedef alpm_list_t * StringListFree;
typedef alpm_list_t * StringListNoFree;
typedef alpm_list_t * PackageListFree;
typedef alpm_list_t * PackageListNoFree;
typedef alpm_list_t * GroupList;
typedef alpm_list_t * DatabaseList;
typedef alpm_list_t * DependList;
typedef alpm_list_t * ListAutoFree;

/* these are for list converter functions */
typedef SV* (*scalarmap)(void*)
typedef void* (*listmap)(SV*)

/* CONVERTER FUNC PROTOS */

SV* c2p_pkg(void*);
ALPM_Package p2c_pkg(SV*);

SV* c2p_depmod(alpm_depmod_t);
SV* c2p_depend(void *);
SV* c2p_conflict(void *);

SV* c2p_siglevel(alpm_siglevel_t);
alpm_siglevel_t p2c_siglevel(SV*);

SV* c2p_pkgreason(alpm_pkgreason_t);
alpm_pkgreason_t p2c_pkgreason(SV*);

/* LIST CONVERTER FUNC PROTOS */

AV* list2av(alpm_list_t*, scalarmap);
alpm_list_t* av2list(AV*, listmap);

#define LIST2STACK(L, F)\
	while(L){\
		XPUSHs(F(L->data));\
		L = alpm_list_next(L);\
	}

#define STACK2LIST(C, L, F)\
	while(C < items){\
		L = alpm_list_add(L, (void*)F(ST(C++));\
	}

#define ZAPLIST(L, F)\
	alpm_list_free_inner(L, F);\
	alpm_list_free(L);\
	L = NULL

#define c2p_str(S) newSVpv(S, 0)

/* MEMORY DEALLOCATION */

void freedepend(void *);
void freeconflict(void *);


#endif /*_ALPMXS_TYPES */
