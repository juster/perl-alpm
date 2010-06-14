#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <alpm.h>
#include "const-c.inc"
#include "alpm_xs.h"

MODULE = ALPM    PACKAGE = ALPM

PROTOTYPES: DISABLE

INCLUDE: const-xs.inc

# Make ALPM::PackageFree a subclass of ALPM::Package
BOOT:
    av_push( get_av( "ALPM::PackageFree::ISA", GV_ADD ),
             newSVpvn( "ALPM::Package", 13 ) );

MODULE = ALPM    PACKAGE = ALPM::ListAutoFree

void
DESTROY(self)
    ListAutoFree self;
  CODE:
#   fprintf( stderr, "DEBUG Freeing memory for ListAutoFree\n" );
    alpm_list_free(self);

MODULE = ALPM    PACKAGE = ALPM::PackageFree

negative_is_error
DESTROY(self)
    ALPM_PackageFree self;
  CODE:
#   fprintf( stderr, "DEBUG Freeing memory for ALPM::PackageFree object\n" );
    RETVAL = alpm_pkg_free(self);
  OUTPUT:
    RETVAL

#----------------------------------------------------------------------------
# PRIVATE FUNCTIONS
#----------------------------------------------------------------------------
 
MODULE = ALPM    PACKAGE = ALPM    PREFIX=alpm

ALPM_PackageFree
alpm_pkg_load(filename, ...)
    const char *filename
  PREINIT:
    pmpkg_t *pkg;
  CODE:
    if ( alpm_pkg_load( filename, 1, &pkg ) != 0 )
        croak( "ALPM Error: %s", alpm_strerror( pm_errno ));
    RETVAL = pkg;
  OUTPUT:
    RETVAL

negative_is_error
alpm_db_unregister_all()

negative_is_error
alpm_initialize()

negative_is_error
alpm_release()

#----------------------------------------------------------------------------
# DATABASE FUNCTIONS
#----------------------------------------------------------------------------

ALPM_DB
alpm_db_register_local()

ALPM_DB
alpm_db_register_sync(sync_name)
    const char * sync_name

MODULE = ALPM   PACKAGE = ALPM::DB

const char *
name(db)
    ALPM_DB db
  CODE:
    RETVAL = alpm_db_get_name(db);
  OUTPUT:
    RETVAL

# We have a wrapper for this because it crashes on local db.
const char *
_url(db)
    ALPM_DB db
  CODE:
    RETVAL = alpm_db_get_url(db);
  OUTPUT:
    RETVAL

negative_is_error
set_server(db, url)
    ALPM_DB db
    const char * url
  CODE:
    RETVAL = alpm_db_setserver(db, url);
  OUTPUT:
    RETVAL

# Wrapper for this checks if a transaction is active.
negative_is_error
_update(db, level)
    ALPM_DB db
    int level
  CODE:
    RETVAL = alpm_db_update(level, db);
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
        sv_setref_pv( RETVAL, "ALPM::Package", (void *)pkg );
    }
  OUTPUT:
    RETVAL

PackageListNoFree
_get_pkg_cache(db)
    ALPM_DB db
  CODE:
    RETVAL = alpm_db_get_pkgcache(db);
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
  
GroupList
_get_group_cache(db)
    ALPM_DB db
  CODE:
    RETVAL = alpm_db_get_grpcache(db);
  OUTPUT:
    RETVAL

# Wrapped to avoid arrayrefs (which are much easier in typemap)
PackageListFree
_search(db, needles)
    ALPM_DB db
    StringListFree needles
  CODE:
    RETVAL = alpm_db_search(db, needles);
  OUTPUT:
    RETVAL

#-----------------------------------------------------------------------------
# PACKAGE GROUPS
#-----------------------------------------------------------------------------

MODULE=ALPM    PACKAGE=ALPM::Group

const char *
name(grp)
    ALPM_Group grp
  CODE:
    RETVAL = alpm_grp_get_name(grp);
  OUTPUT:
    RETVAL

PackageListNoFree
_get_pkgs(grp)
    ALPM_Group grp
  CODE:
    RETVAL = alpm_grp_get_pkgs(grp);
  OUTPUT:
    RETVAL

INCLUDE: Options.xs

INCLUDE: Package.xs

INCLUDE: Transaction.xs

# EOF
