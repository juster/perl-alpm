#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <alpm.h>
#include "types.h"
/* #include "alpm_xs.h" */

MODULE = ALPM	PACKAGE = ALPM

PROTOTYPES: DISABLE

# Make ALPM::PackageFree a subclass of ALPM::Package
BOOT:
	av_push(get_av("ALPM::PackageFree::ISA", GV_ADD),
	  newSVpvn("ALPM::Package", 13));

MODULE = ALPM	PACKAGE = ALPM::PackageFree

negative_is_error
DESTROY(self)
	ALPM_PackageFree self;
 CODE:
#   fprintf(stderr, "DEBUG Freeing memory for ALPM::PackageFree object\n");
	RETVAL = alpm_pkg_free(self);
 OUTPUT:
	RETVAL

#---------------------
# PUBLIC ALPM METHODS
#---------------------

MODULE = ALPM	PACKAGE = ALPM

ALPM_Handle
new(class, root, dbpath)
	SV * class
	char * root
	char * dbpath
 PREINIT:
	enum _alpm_errno_t err;
	ALPM_Handle h;
 CODE:
	h = alpm_initialize(root, dbpath, &err);
	if(h == NULL){
		croak("ALPM Error: %s", alpm_strerror(err));
	}
	RETVAL = h;
 OUTPUT:
	RETVAL

void
DESTROY(self)
	ALPM_Handle self;
 PREINIT:
	int ret;
 CODE:
	ret = alpm_release(self);
	if(ret == -1){
		croak("ALPM Error: failed to release ALPM handle");
	}
	# errno is only inside a handle, which was just released...

MODULE = ALPM    PACKAGE = ALPM    PREFIX=alpm_

const char *
alpm_version(class)
	SV * class
 CODE:
	RETVAL = alpm_version();
 OUTPUT:
	RETVAL

ALPM_PackageOrNull
alpm_find_satisfier(self, depstr, ...)
	SV * self
	const char * depstr
 PREINIT:
	alpm_list_t *pkgs;
	int i;
 CODE:
	i = 0;
	STACK2LIST(i, pkgs, p2c_pkg);
	RETVAL = alpm_find_satisfier(pkgs, depstr);
	FREELIST(pkgs);
 OUTPUT:
	RETVAL

ALPM_PackageOrNull
alpm_find_dbs_satisfier(self, depstr, ...)
	ALPM_Handle self
	const char * depstr
 PREINIT:
	alpm_list_t *dbs;
	int i;
 CODE:
	i = 0;
	STACK2LIST(i, dbs, p2c_db);
	RETVAL = alpm_find_dbs_satisfier(self, dbs, depstr);
	FREELIST(dbs);
 OUTPUT:
	RETVAL

void
alpm_check_conflicts(self, ...)
	ALPM_Handle self
 PREINIT:
	alpm_list_t *L, *clist;
	int i;
 PPCODE:
	i = 1;
	STACK2LIST(i, L, p2c_pkg);
	L = clist = alpm_checkconflicts(self, L);
	LIST2STACK(clist, c2p_conflict);
	ZAPLIST(L, freeconflict);

char *
alpm_fetch_pkgurl(self, url)
	ALPM_Handle self
	const char * url
 CODE:
	RETVAL = alpm_fetch_pkgurl(self, url);
	if(RETVAL == NULL){
		croakalpm("ALPM");
	}
 OUTPUT:
	RETVAL

MODULE = ALPM	PACKAGE = ALPM	PREFIX = alpm_db_

negative_is_error
alpm_db_unregister_all(self)
	ALPM_Handle self

MODULE = ALPM	PACKAGE = ALPM

ALPM_Package
load_pkgfile(self, filename, full, siglevel)
	ALPM_Handle self
	const char *filename
	int full
	ALPM_SigLevel siglevel
 PREINIT:
	ALPM_PackageFree pkg;
 CODE:
	if(alpm_pkg_load(self, filename, full, siglevel, &RETVAL) < 0){
		croakalpm("ALPM");
	}
 OUTPUT:
	RETVAL

int
vercmp(unused, a, b)
	SV * unused
	const char *a
	const char *b
 CODE:
	RETVAL = alpm_pkg_vercmp(a, b);
 OUTPUT:
	RETVAL

negative_is_error
set_pkg_reason(self, pkg, rsn)
	ALPM_Handle self
	ALPM_Package pkg
	alpm_pkgreason_t rsn
 CODE:
	RETVAL = alpm_db_set_pkgreason(self, pkg, rsn);
 OUTPUT:
	RETVAL

#---------------------
# PRIVATE ALPM METHODS
#---------------------

MODULE = ALPM    PACKAGE = ALPM    PREFIX=alpm

# This is used inside ALPM.pm, so it keeps its _db prefix.
ALPM_SyncDB
alpm_db_register_sync(self, sync_name, siglvl)
	ALPM_Handle self
	const char * sync_name
	ALPM_SigLevel siglvl

INCLUDE: xs/Options.xs

INCLUDE: xs/Package.xs

INCLUDE: xs/DB.xs

# INCLUDE: xs/Transaction.xs

# EOF
