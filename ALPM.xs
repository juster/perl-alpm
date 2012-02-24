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

#------------------------
# PUBLIC DATABASE METHODS
#------------------------

MODULE = ALPM	PACKAGE = ALPM::DB

void
pkgs(db)
	ALPM_DB db
 PREINIT:
	alpm_list_t *L, *pkgs;
 PPCODE:
	L = pkgs = alpm_db_get_pkgcache(db);
	# If pkgs is NULL, we can't report the error because errno is in the handle object.
	LIST2STACK(pkgs, c2p_pkg);
	FREELIST(L);

# groups returns a list of pairs. Each pair is a group name followed by
# an array ref of packages belonging to the group.

void
groups(db)
	ALPM_DB db
 PREINIT:
	alpm_list_t *L, *grps, *pkglst;
	alpm_group_t *grp;
	AV *pkgarr;
 PPCODE:
	L = grps = alpm_db_get_groupcache(db);
	while(grps){
		grp = grps->data;
		XPUSHs(newSVpv(grp->name, 0));
		pkgarr = list2av(grp->packages, c2p_pkg);
		XPUSHs(newRV_noinc((SV*)pkgarr));
	}
	FREELIST(L);

const char *
name(db)
	ALPM_DB db
 CODE:
	RETVAL = alpm_db_get_name(db);
 OUTPUT:
	RETVAL

SV *
find(db, name)
	ALPM_DB db
	const char *name
 PREINIT:
	ALPM_Package pkg;
 CODE:
	pkg = alpm_db_get_pkg(db, name);
	RETVAL = (pkg == NULL ? &PL_sv_undef
		: c2p_pkg(pkg));
 OUTPUT:
	RETVAL

void
find_group(db, name)
	ALPM_DB db
	const char * name
 PREINIT:
	alpm_group_t *grp;
	alpm_list_t *pkgs;
 PPCODE:
	grp = alpm_db_readgroup(db, name);
	if(grp){
		pkgs = grp->packages;
		LIST2STACK(pkgs, c2p_pkg);
	}

void
search(db, ...)
	ALPM_DB db
 PREINIT:
	alpm_list_t *L, *terms, *fnd;
	int i;
 PPCODE:
	i = 1;
	STACK2LIST(i, terms, p2c_str);
	L = fnd = alpm_db_search(db, terms);
	ZAPLIST(terms, free);
	LIST2STACK(fnd, c2p_pkg);
	FREELIST(L);

#------------------------------
# PRIVATE SYNC DATABASE METHODS
#------------------------------

MODULE = ALPM   PACKAGE = ALPM::DB::Sync    PREFIX = alpm_db

# Wrapper for this checks if a transaction is active.
# We have to reverse the arguments because it is a method.
negative_is_error
alpm_db_update(db, force)
	ALPM_DB db
	int force
 C_ARGS:
	force, db

#-----------------------------
# PUBLIC SYNC DATABASE METHODS
#-----------------------------

MODULE = ALPM   PACKAGE = ALPM::DB::Sync    PREFIX = alpm_db_

negative_is_error
alpm_db_unregister(self)
	ALPM_DB self

negative_is_error
alpm_db_add_server(self, url)
	ALPM_DB self
	const char * url

negative_is_error
alpm_db_remove_server(self, url)
	ALPM_DB self
	const char * url

void alpm_db_get_servers(self)
	ALPM_DB self
 PREINIT:
	alpm_list_t *L, *i;
 PPCODE:
	L = i = alpm_db_get_servers(self);
	LIST2STACK(i, c2p_str);
	FREELIST(L);

negative_is_error
alpm_db_set_servers(self, ...)
	ALPM_DB self
 PREINIT:
	alpm_list_t *L;
	int i;
 CODE:
	i = 1;
	STACK2LIST(i, L, p2c_str);
	RETVAL = alpm_option_set_servers(self, L);
 OUTPUT:
	RETVAL

MODULE = ALPM	PACKAGE = ALPM::DB::Sync	PREFIX = alpm_db_get_

int
alpm_db_get_valid(db)
	ALPM_DB db

ALPM_SigLevel
alpm_db_get_siglevel(db)
	ALPM_DB db

INCLUDE: xs/Options.xs

INCLUDE: xs/Package.xs

# INCLUDE: xs/Transaction.xs

# EOF
