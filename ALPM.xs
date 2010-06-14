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

MODULE = ALPM    PACKAGE = ALPM

ALPM_PackageFree
alpm_pkg_load(filename, ...)
    const char *filename
  PREINIT:
    pmpkg_t *pkg;
#    unsigned short full;
  CODE:
#    full = ( items > 1 ? 1 : 0 );
    if ( alpm_pkg_load( filename, 1, &pkg ) != 0 )
        croak( "ALPM Error: %s", alpm_strerror( pm_errno ));
    RETVAL = pkg;
  OUTPUT:
    RETVAL

MODULE = ALPM    PACKAGE = ALPM    PREFIX=alpm_

negative_is_error
alpm_initialize()

negative_is_error
alpm_release()

MODULE = ALPM    PACKAGE = ALPM

SV *
alpm_option_get_logcb()
  CODE:
    RETVAL = ( cb_log_sub == NULL ? &PL_sv_undef : cb_log_sub );
  OUTPUT:
    RETVAL

void
alpm_option_set_logcb(callback)
    SV * callback
  CODE:
    if ( ! SvOK(callback) ) {
        if ( cb_log_sub != NULL ) {
            SvREFCNT_dec( cb_log_sub );
            alpm_option_set_logcb( NULL );
            cb_log_sub = NULL;
        }
    }
    else {
        if ( ! SvROK(callback) || SvTYPE( SvRV(callback) ) != SVt_PVCV ) {
            croak( "value for logcb option must be a code reference" );
        }

        if ( cb_log_sub ) {
            sv_setsv( cb_log_sub, callback );
        }
        else {
            cb_log_sub = newSVsv(callback);
            alpm_option_set_logcb( cb_log_wrapper );
        }
    }

SV *
alpm_option_get_dlcb()
  CODE:
    RETVAL = ( cb_download_sub == NULL ? &PL_sv_undef : cb_download_sub );
  OUTPUT:
    RETVAL

void
alpm_option_set_dlcb(callback)
    SV * callback
  CODE:
    if ( ! SvOK(callback) ) {
        if ( cb_download_sub != NULL ) {
            SvREFCNT_dec( cb_download_sub );
            alpm_option_set_dlcb( NULL );
            cb_download_sub = NULL;
        }
    }
    else {
        if ( ! SvROK(callback) || SvTYPE( SvRV(callback) ) != SVt_PVCV ) {
            croak( "value for dlcb option must be a code reference" );
        }

        if ( cb_download_sub ) {
            sv_setsv( cb_download_sub, callback );
        }
        else {
            cb_download_sub = newSVsv(callback);
            alpm_option_set_dlcb( cb_download_wrapper );
        }
    }


SV *
alpm_option_get_totaldlcb()
  CODE:
    RETVAL = ( cb_totaldl_sub == NULL ? &PL_sv_undef : cb_totaldl_sub );
  OUTPUT:
    RETVAL

void
alpm_option_set_totaldlcb(callback)
    SV * callback
  CODE:
    if ( ! SvOK(callback) ) {
        if ( cb_totaldl_sub != NULL ) {
            SvREFCNT_dec( cb_totaldl_sub );
            alpm_option_set_totaldlcb( NULL );
            cb_totaldl_sub = NULL;
        }
    }
    else {
        if ( ! SvROK(callback) || SvTYPE( SvRV(callback) ) != SVt_PVCV ) {
            croak( "value for totaldlcb option must be a code reference" );
        }

        if ( cb_totaldl_sub ) {
            sv_setsv( cb_totaldl_sub, callback );
        }
        else {
            cb_totaldl_sub = newSVsv(callback);
            alpm_option_set_totaldlcb( cb_totaldl_wrapper );
        }
    }

SV *
alpm_option_get_fetchcb()
  CODE:
    RETVAL = ( cb_fetch_sub == NULL ? &PL_sv_undef : cb_fetch_sub );
  OUTPUT:
    RETVAL

void
alpm_option_set_fetchcb(callback)
    SV * callback
  CODE:
    if ( ! SvOK(callback) ) {
        if ( cb_fetch_sub != NULL ) {
            SvREFCNT_dec( cb_fetch_sub );
            alpm_option_set_fetchcb( NULL );
            cb_fetch_sub = NULL;
        }
    }
    else {
        if ( ! SvROK(callback) || SvTYPE( SvRV(callback) ) != SVt_PVCV ) {
            croak( "value for fetchcb option must be a code reference" );
        }

        if ( cb_fetch_sub ) {
            sv_setsv( cb_fetch_sub, callback );
        }
        else {
            cb_fetch_sub = newSVsv(callback);
            alpm_option_set_fetchcb( cb_fetch_wrapper );
        }
    }


const char *
alpm_option_get_root()

negative_is_error
alpm_option_set_root(root)
    const char * root

const char *
alpm_option_get_dbpath()

negative_is_error
alpm_option_set_dbpath(dbpath)
    const char *dbpath

StringListNoFree
alpm_option_get_cachedirs()

negative_is_error
alpm_option_add_cachedir(cachedir)
    const char * cachedir

void
alpm_option_set_cachedirs(dirlist)
    StringListNoFree dirlist

negative_is_error
alpm_option_remove_cachedir(cachedir)
    const char * cachedir

const char *
alpm_option_get_logfile()

negative_is_error
alpm_option_set_logfile(logfile);
    const char * logfile

const char *
alpm_option_get_lockfile()

unsigned short
alpm_option_get_usesyslog()

void
alpm_option_set_usesyslog(usesyslog)
    unsigned short usesyslog

StringListNoFree
alpm_option_get_noupgrades()

void
alpm_option_add_noupgrade(pkg)
  const char * pkg

void
alpm_option_set_noupgrades(upgrade_list)
    StringListNoFree upgrade_list

negative_is_error
alpm_option_remove_noupgrade(pkg)
    const char * pkg

StringListNoFree
alpm_option_get_noextracts()

void
alpm_option_add_noextract(pkg)
    const char * pkg

void
alpm_option_set_noextracts(noextracts_list)
    StringListNoFree noextracts_list

negative_is_error
alpm_option_remove_noextract(pkg)
    const char * pkg

StringListNoFree
alpm_option_get_ignorepkgs()

void
alpm_option_add_ignorepkg(pkg)
    const char * pkg

void
alpm_option_set_ignorepkgs(ignorepkgs_list)
    StringListNoFree ignorepkgs_list

negative_is_error
alpm_option_remove_ignorepkg(pkg)
    const char * pkg

StringListNoFree
alpm_option_get_ignoregrps()

void
alpm_option_add_ignoregrp(grp)
    const char  * grp

void
alpm_option_set_ignoregrps(ignoregrps_list)
    StringListNoFree ignoregrps_list

negative_is_error
alpm_option_remove_ignoregrp(grp)
    const char  * grp

void
alpm_option_set_usedelta(usedelta)
    unsigned short usedelta

SV *
alpm_option_get_localdb()
  PREINIT:
    pmdb_t *db;
  CODE:
    db = alpm_option_get_localdb();
    if ( db == NULL )
        RETVAL = &PL_sv_undef;
    else {
        RETVAL = newSV(0);
        sv_setref_pv( RETVAL, "ALPM::DB", (void *)db );
    }
  OUTPUT:
    RETVAL

DatabaseList
alpm_option_get_syncdbs()

negative_is_error
alpm_db_unregister_all()

#--------------------------------------------------------------------------
# ALPM::DB Functions
#--------------------------------------------------------------------------

MODULE = ALPM    PACKAGE = ALPM    PREFIX=alpm_

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

MODULE=ALPM    PACKAGE=ALPM::Package    PREFIX=alpm_pkg_
    
negative_is_error
alpm_pkg_checkmd5sum(pkg)
    ALPM_Package pkg

# TODO: implement this in perl with LWP
#char *
#alpm_fetch_pkgurl(url)
#    const char *url

int
alpm_pkg_vercmp(a, b)
    const char *a
    const char *b

StringListFree
alpm_pkg_requiredby(pkg)
    ALPM_Package pkg
  CODE:
    RETVAL = alpm_pkg_compute_requiredby(pkg);
  OUTPUT:
    RETVAL

const char *
alpm_pkg_filename(pkg)
    ALPM_Package pkg
  CODE:
    RETVAL = alpm_pkg_get_filename(pkg);
  OUTPUT:
    RETVAL

const char *
alpm_pkg_name(pkg)
    ALPM_Package pkg
  CODE:
    RETVAL = alpm_pkg_get_name(pkg);
  OUTPUT:
    RETVAL

const char *
alpm_pkg_version(pkg)
    ALPM_Package pkg
  CODE:
    RETVAL = alpm_pkg_get_version(pkg);
  OUTPUT:
    RETVAL

const char *
alpm_pkg_desc(pkg)
    ALPM_Package pkg
  CODE:
    RETVAL = alpm_pkg_get_desc(pkg);
  OUTPUT:
    RETVAL

const char *
alpm_pkg_url(pkg)
    ALPM_Package pkg
  CODE:
    RETVAL = alpm_pkg_get_url(pkg);
  OUTPUT:
    RETVAL

time_t
alpm_pkg_builddate(pkg)
    ALPM_Package pkg
  CODE:
    RETVAL = alpm_pkg_get_builddate(pkg);
  OUTPUT:
    RETVAL

time_t
alpm_pkg_installdate(pkg)
    ALPM_Package pkg
  CODE:
    RETVAL = alpm_pkg_get_installdate(pkg);
  OUTPUT:
    RETVAL

const char *
alpm_pkg_packager(pkg)
    ALPM_Package pkg
  CODE:
    RETVAL = alpm_pkg_get_packager(pkg);
  OUTPUT:
    RETVAL

const char *
alpm_pkg_md5sum(pkg)
    ALPM_Package pkg
  CODE:
    RETVAL = alpm_pkg_get_md5sum(pkg);
  OUTPUT:
    RETVAL

const char *
alpm_pkg_arch(pkg)
    ALPM_Package pkg
  CODE:
    RETVAL = alpm_pkg_get_arch(pkg);
  OUTPUT:
    RETVAL

off_t
alpm_pkg_size(pkg)
    ALPM_Package pkg
  CODE:
    RETVAL = alpm_pkg_get_size(pkg);
  OUTPUT:
    RETVAL

off_t
alpm_pkg_isize(pkg)
    ALPM_Package pkg
  CODE:
    RETVAL = alpm_pkg_get_isize(pkg);
  OUTPUT:
    RETVAL

pmpkgreason_t
alpm_pkg_reason(pkg)
    ALPM_Package pkg
  CODE:
    RETVAL = alpm_pkg_get_reason(pkg);
  OUTPUT:
    RETVAL

StringListNoFree
alpm_pkg_licenses(pkg)
    ALPM_Package pkg
  CODE:
    RETVAL = alpm_pkg_get_licenses(pkg);
  OUTPUT:
    RETVAL

StringListNoFree
alpm_pkg_groups(pkg)
    ALPM_Package pkg
  CODE:
    RETVAL = alpm_pkg_get_groups(pkg);
  OUTPUT:
    RETVAL

DependList
alpm_pkg_depends(pkg)
    ALPM_Package pkg
  CODE:
    RETVAL = alpm_pkg_get_depends(pkg);
  OUTPUT:
    RETVAL

StringListNoFree
alpm_pkg_optdepends(pkg)
    ALPM_Package pkg
  CODE:
    RETVAL = alpm_pkg_get_optdepends(pkg);
  OUTPUT:
    RETVAL

StringListNoFree
alpm_pkg_conflicts(pkg)
    ALPM_Package pkg
  CODE:
    RETVAL = alpm_pkg_get_conflicts(pkg);
  OUTPUT:
    RETVAL

StringListNoFree
alpm_pkg_provides(pkg)
    ALPM_Package pkg
  CODE:
    RETVAL = alpm_pkg_get_provides(pkg);
  OUTPUT:
    RETVAL

StringListNoFree
alpm_pkg_deltas(pkg)
    ALPM_Package pkg
  CODE:
    RETVAL = alpm_pkg_get_deltas(pkg);
  OUTPUT:
    RETVAL

StringListNoFree
alpm_pkg_replaces(pkg)
    ALPM_Package pkg
  CODE:
    RETVAL = alpm_pkg_get_replaces(pkg);
  OUTPUT:
    RETVAL

StringListNoFree
alpm_pkg_files(pkg)
    ALPM_Package pkg
  CODE:
    RETVAL = alpm_pkg_get_files(pkg);
  OUTPUT:
    RETVAL

StringListNoFree
alpm_pkg_backup(pkg)
    ALPM_Package pkg
  CODE:
    RETVAL = alpm_pkg_get_backup(pkg);
  OUTPUT:
    RETVAL

StringListNoFree
alpm_pkg_removes(pkg)
    ALPM_Package pkg
  CODE:
    RETVAL = alpm_pkg_get_removes(pkg);
  OUTPUT:
    RETVAL

ALPM_DB
alpm_pkg_db(pkg)
    ALPM_Package pkg
  CODE:
    RETVAL = alpm_pkg_get_db(pkg);
  OUTPUT:
    RETVAL

SV *
alpm_pkg_changelog(pkg)
    ALPM_Package pkg
  PREINIT:
    void *fp;
    char buffer[128];
    size_t bytes_read;
    SV *changelog_txt;
  CODE:
    changelog_txt = newSVpv( "", 0 );
    RETVAL = changelog_txt;

    fp = alpm_pkg_changelog_open( pkg );
    if ( fp ) {
        while ( 1 ) {
            bytes_read = alpm_pkg_changelog_read( (void *)buffer, 128,
                                                  pkg, fp );
            /* fprintf( stderr, "DEBUG: read %d bytes of changelog\n", */
            /*          bytes_read ); */
            if ( bytes_read == 0 ) break;
            sv_catpvn( changelog_txt, buffer, bytes_read );
        }
        alpm_pkg_changelog_close( pkg, fp );
    }
  OUTPUT:
    RETVAL

unsigned short
alpm_pkg_has_scriptlet(pkg)
    ALPM_Package pkg

unsigned short
alpm_pkg_has_force(pkg)
    ALPM_Package pkg

off_t
alpm_pkg_download_size(newpkg)
    ALPM_Package newpkg

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

#-----------------------------------------------------------------------------
# TRANSACTIONS
#-----------------------------------------------------------------------------

MODULE=ALPM    PACKAGE=ALPM

negative_is_error
alpm_trans_init(type, flags, event_sub, conv_sub, progress_sub)
    int type
    int flags
    SV  *event_sub
    SV  *conv_sub
    SV  *progress_sub
  PREINIT:
    alpm_trans_cb_event     event_func = NULL;
    alpm_trans_cb_conv      conv_func  = NULL;
    alpm_trans_cb_progress  progress_func  = NULL;
  CODE:
    /* I'm guessing that event callbacks provided for previous transactions
       shouldn't come into effect for later transactions unless explicitly
       provided. */

    UPDATE_TRANS_CALLBACK( event )
    UPDATE_TRANS_CALLBACK( conv )
    UPDATE_TRANS_CALLBACK( progress )

    RETVAL = alpm_trans_init( type, flags,
                              event_func, conv_func, progress_func );
  OUTPUT:
    RETVAL

negative_is_error
alpm_trans_sysupgrade(enable_downgrade)
    int enable_downgrade
  CODE:
    RETVAL = alpm_trans_sysupgrade( enable_downgrade );
  OUTPUT:
    RETVAL

MODULE=ALPM    PACKAGE=ALPM::Transaction

# This is used internally, we use the full name of the function
# (no PREFIX above)

negative_is_error
alpm_trans_addtarget(target)
    char * target

negative_is_error
DESTROY(self)
    SV * self
  CODE:
#   fprintf( stderr, "DEBUG Releasing the transaction\n" );
    RETVAL = alpm_trans_release();
  OUTPUT:
    RETVAL

MODULE=ALPM    PACKAGE=ALPM::Transaction    PREFIX=alpm_trans_

negative_is_error
alpm_trans_prepare(self)
    SV * self
  PREINIT:
    alpm_list_t *errors;
    HV *trans;
    SV *trans_error, **prepared;
  CODE:
    trans = (HV *) SvRV(self);

    prepared = hv_fetch( trans, "prepared", 8, 0 );
    if ( SvOK(*prepared) && SvTRUE(*prepared) ) {
        RETVAL = 0;
    }
    else {
        /* fprintf( stderr, "DEBUG: ALPM::Transaction::prepare\n" ); */

        errors = NULL;
        RETVAL = alpm_trans_prepare( &errors );

        if ( RETVAL == -1 ) {
            trans_error = convert_trans_errors( errors );
            if ( trans_error ) {
                hv_store( trans, "error", 5, trans_error, 0 );

                croak( "ALPM Transaction Error: %s", alpm_strerror( pm_errno ));
                fprintf( stderr, "ERROR: prepare shouldn't get here?\n" );
                RETVAL = 0;
            }

            /* If we don't catch all the kinds of errors we'll get memory
               leaks inside the list!  Yay! */
            if ( errors ) {
                fprintf( stderr,
                         "ERROR: unknown prepare error caused memory leak "
                         "at %s line %d\n", __FILE__, __LINE__ );
            }
        }
        else hv_store( trans, "prepared", 8, newSViv(1), 0 );

        /* fprintf( stderr, "DEBUG: ALPM::Transaction::prepare returning\n" ); */
    }
  OUTPUT:
    RETVAL

negative_is_error
alpm_trans_commit(self)
    SV * self
  PREINIT:
    alpm_list_t *errors;
    HV *trans;
    SV *trans_error, **prepared;
  CODE:
    /* make sure we are called as a method */
    if ( !( SvROK(self) /* && SvTYPE(self) == SVt_PVMG */
            && sv_isa( self, "ALPM::Transaction" ) ) ) {
        croak( "commit must be called as a method to ALPM::Transaction" );
    }

    trans = (HV *) SvRV(self);
    prepared = hv_fetch( trans, "prepared", 8, 0 );

    /*fprintf( stderr, "DEBUG: prepared = %d\n", SvIV(*prepared) );*/

    /* prepare before we commit */
    if ( ! SvOK(*prepared) || ! SvTRUE(*prepared) ) {
        PUSHMARK(SP);
        XPUSHs(self);
        PUTBACK;
        call_method( "prepare", G_DISCARD );
    }
    
    errors = NULL;
    RETVAL = alpm_trans_commit( &errors );

    if ( RETVAL == -1 ) {
        trans_error = convert_trans_errors( errors );
        if ( trans_error ) {
            hv_store( trans, "error", 5, trans_error, 0 );
            croak( "ALPM Transaction Error: %s", alpm_strerror( pm_errno ));
            fprintf( stderr, "ERROR: commit shouldn't get here?\n" );
            RETVAL = 0;
        }

        if ( errors ) {
            fprintf( stderr,
                     "ERROR: unknown commit error caused memory leak "
                     "at %s line %d\n",
                     __FILE__, __LINE__ );
        }
    }
  OUTPUT:
    RETVAL

negative_is_error
alpm_trans_interrupt(self)
    SV * self
  CODE:
    RETVAL = alpm_trans_interrupt();
  OUTPUT:
    RETVAL

# EOF
