#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "types.h"
#include "alpm_xs.h"

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

#-----------------------------------------------------------------
# PUBLIC ALPM METHODS
#-----------------------------------------------------------------

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
	RETVAL = h
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
alpm_find_satisfier(self, pkglist, depstr)
	SV * self
	PackageListFree pkglist
	const char * depstr
 C_ARGS:
	pkglist, depstr

ALPM_PackageOrNull
alpm_find_dbs_satisfier(self, dblist, depstr)
	ALPM_Handle self
	DatabaseList dblist
	const char * depstr

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

MODULE = ALPM	PACKAGE = ALPM	PREFIX = alpm_db_

negative_is_error
alpm_db_unregister_all(self)
	ALPM_Handle self

MODULE = ALPM	PACKAGE = ALPM	# No PREFIX!

ALPM_Package
load_pkgfile(self, filename, full, siglevel)
	ALPM_Handle self
	const char *filename
	int full
	ALPM_SigLevel siglevel
 PREINIT:
	ALPM_PackageFree pkg
 CODE:
	if(alpm_pkg_load(self, filename, full, siglevel, &pkg) < 0){
		croakalpm("ALPM");
	}
 OUTPUT:
	pkg

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
alpm_db_register_sync(self, sync_name)
	ALPM_Handle self
	const char * sync_name

#-----------------------------------------------------------------
# PRIVATE DATABASE METHODS
#-----------------------------------------------------------------

MODULE = ALPM	PACKAGE = ALPM::DB	PREFIX = alpm_db

GroupList
alpm_db_get_grpcache(db)
    ALPM_DB db

# Wrapped to avoid arrayrefs (which are much easier in typemap)
PackageListFree
alpm_db_search(db, needles)
    ALPM_DB db
    StringListFree needles

#-----------------------------------------------------------------
# PUBLIC DATABASE METHODS
#-----------------------------------------------------------------

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

MODULE = ALPM   PACKAGE = ALPM::DB

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
	pmpkg_t *pkg;
 CODE:
	pkg = alpm_db_get_pkg(db, name);
	if(pkg == NULL){
		RETVAL = &PL_sv_undef;
	}else{
		RETVAL = newSV(0);
		sv_setref_pv(RETVAL, "ALPM::Package", (void*)pkg);
	}
 OUTPUT:
	RETVAL

ALPM_Group
find_group(db, name)
	ALPM_DB db
	const char * name
 CODE:
	RETVAL = alpm_db_readgrp(db, name);
 OUTPUT:
	RETVAL

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
	STACK2LIST(i, lst, p2c_str);
	RETVAL = alpm_option_set_servers(self, L);
 OUTPUT:
	RETVAL

#-----------------------------------------------------------------
# PUBLIC GROUP METHODS
#-----------------------------------------------------------------

MODULE=ALPM    PACKAGE=ALPM::Group

const char *
name(grp)
	ALPM_Group grp
 CODE:
	RETVAL = alpm_grp_get_name(grp);
 OUTPUT:
	RETVAL

#-----------------------------------------------------------------
# PRIVATE GROUP METHODS
#-----------------------------------------------------------------

MODULE=ALPM    PACKAGE=ALPM::Group    PREFIX=alpm_grp

PackageList
alpm_grp_get_pkgs(grp)
    ALPM_Group grp

INCLUDE: xs/Options.xs

INCLUDE: xs/Package.xs

INCLUDE: xs/Transaction.xs

# EOF
