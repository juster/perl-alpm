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
new(unused, root, dbpath)
	SV * unused
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
 CODE:
	RETVAL = alpm_find_satisfier(pkglist, depstr);
 OUTPUT:
	RETVAL

ALPM_PackageOrNull
alpm_find_dbs_satisfier(self, dblist, depstr)
	ALPM_Handle self
	DatabaseList dblist
	const char * depstr

int
alpm_vercmp(self, a, b)
	SV * self
	const char *a
	const char *b
 CODE:
	RETVAL = alpm_pkg_vercmp(a, b);
 OUTPUT:
	RETVAL

StringListFree
alpm_check_conflicts(self, plist)
	ALPM_Handle self
	PackageListNoFree plist
 CODE:
	RETVAL = alpm_checkconflicts(self, plist)
 OUTPUT:
	RETVAL

#-----------------------------------------------------------------
# PRIVATE ALPM METHODS
#-----------------------------------------------------------------

MODULE = ALPM    PACKAGE = ALPM    PREFIX=alpm

ALPM_PackageFree
alpm_pkg_load(filename, ...)
	const char *filename
 PREINIT:
	pmpkg_t *pkg;
 CODE:
	if(alpm_pkg_load(filename, 1, &pkg) != 0){
		croak("ALPM Error: %s", alpm_strerror(pm_errno));
	}
	RETVAL = pkg;
 OUTPUT:
	RETVAL

# Because this unregisters the local database and there is no
# longer any way to re-register the local database this
# function is now even more pointless. Removed until this
# minor bug is fixed with libalpm.
#
# Should be in next pacman release. (currently 3.5.1)
# falconindy already fixed this! :)
#
#negative_is_error
#alpm_db_unregister_all ()

#-----------------------------------------------------------------
# PRIVATE DATABASE METHODS
#-----------------------------------------------------------------

# This is used inside ALPM.pm, so it keeps its _db prefix.
ALPM_DB
alpm_db_register_sync(sync_name)
    const char * sync_name

# Remove PREFIX
MODULE = ALPM    PACKAGE = ALPM::DB    PREFIX = alpm_db

# We have a wrapper for this because it crashes on local db.
const char *
alpm_db_get_url(db)
    ALPM_DB db

PackageList
alpm_db_get_pkgcache(db)
    ALPM_DB db

# Wrapper for this checks if a transaction is active.
# We have to reverse the arguments because it is a method.
negative_is_error
alpm_db_update(db, force)
    ALPM_DB db
    int force
 CODE:
    RETVAL = alpm_db_update(force, db);
 OUTPUT:
    RETVAL

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

MODULE = ALPM   PACKAGE = ALPM::DB    PREFIX = alpm_db_

negative_is_error
alpm_db_unregister(self)
    ALPM_DB self

MODULE = ALPM   PACKAGE = ALPM::DB

const char *
name(db)
    ALPM_DB db
 CODE:
    RETVAL = alpm_db_get_name(db);
 OUTPUT:
    RETVAL

negative_is_error
add_url(db, url)
    ALPM_DB db
    const char * url
 CODE:
    RETVAL = alpm_db_setserver(db, url);
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
    if ( pkg == NULL ) RETVAL = &PL_sv_undef;
    else {
        RETVAL = newSV(0);
        sv_setref_pv(RETVAL, "ALPM::Package",(void *)pkg);
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

negative_is_error
set_pkg_reason(self, pkgname, pkgreason)
    ALPM_DB       self
    char        * pkgname
    pmpkgreason_t pkgreason
 CODE:
    RETVAL = alpm_db_set_pkgreason(self, pkgname, pkgreason);
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
