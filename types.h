#ifndef _ALPMXS_TYPES
#define _ALPMXS_TYPES

/* DATA TYPES */

typedef SV* (*scalarmap)(void*)
typedef void* (*listmap)(SV*)
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
	alpm_list_free(L)

#endif /*_ALPMXS_TYPES */
