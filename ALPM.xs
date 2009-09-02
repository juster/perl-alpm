#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <alpm.h>

/* #include "libalpm/alpm.h" */
/* #include "libalpm/alpm_list.h" */
/* #include "libalpm/deps.h" */
/* #include "libalpm/group.h" */
/* #include "libalpm/sync.h" */
/* #include "libalpm/trans.h" */

#include "const-c.inc"

/* These are missing in alpm.h */

/* from deps.h */
struct __pmdepend_t {
	pmdepmod_t mod;
	char *name;
	char *version;
};

/* from group.h */
struct __pmgrp_t {
	/*group name*/
	char *name;
	/*list of pmpkg_t packages*/
	alpm_list_t *packages;
};

/* from sync.h */
struct __pmsyncpkg_t {
	pmpkgreason_t newreason;
	pmpkg_t *pkg;
	alpm_list_t *removes;
};

typedef int           negative_is_error;
typedef pmdb_t      * ALPM_DB;
typedef pmpkg_t     * ALPM_Package;
typedef pmpkg_t     * ALPM_PackageFree;
typedef pmgrp_t     * ALPM_Group;

typedef alpm_list_t * StringListFree;
typedef alpm_list_t * StringListNoFree;
typedef alpm_list_t * PackageListFree;
typedef alpm_list_t * PackageListNoFree;
typedef alpm_list_t * GroupList;
typedef alpm_list_t * DatabaseList;
typedef alpm_list_t * DependList;
typedef alpm_list_t * ListAutoFree;

/* Code references to use as callbacks. */
static SV *cb_log_sub      = NULL;
static SV *cb_download_sub = NULL;
static SV *cb_totaldl_sub  = NULL;
static SV *cb_fetch_sub    = NULL;
/* transactions */
static SV *cb_trans_event_sub    = NULL;
static SV *cb_trans_conv_sub     = NULL;
static SV *cb_trans_progress_sub = NULL;


/* String constants to use for log levels (instead of bitflags) */
static const char * log_lvl_error    = "error";
static const char * log_lvl_warning  = "warning";
static const char * log_lvl_debug    = "debug";
static const char * log_lvl_function = "function";
static const char * log_lvl_unknown  = "unknown";

void cb_log_wrapper ( pmloglevel_t level, char * format, va_list args )
{
    SV *s_level, *s_message;
    char *lvl_str;
    int lvl_len;
    dSP;

    if ( cb_log_sub == NULL ) return;

    /* convert log level bitflag to a string */
    switch ( level ) {
    case PM_LOG_ERROR:
        lvl_str = (char *)log_lvl_error;
        break;
    case PM_LOG_WARNING:
        lvl_str = (char *)log_lvl_warning;
        break;
    case PM_LOG_DEBUG:
        lvl_str = (char *)log_lvl_debug;
        break;
    case PM_LOG_FUNCTION:
        lvl_str = (char *)log_lvl_function;
        break;
    default:
        lvl_str = (char *)log_lvl_unknown; 
    }
    lvl_len = strlen( lvl_str );

    ENTER;
    SAVETMPS;

    s_level   = sv_2mortal( newSVpv( lvl_str, lvl_len ) );
    s_message = sv_newmortal();
    sv_vsetpvfn( s_message, format, strlen(format), &args,
                 (SV **)NULL, 0, NULL );
    
    PUSHMARK(SP);
    XPUSHs(s_level);
    XPUSHs(s_message);
    PUTBACK;

    call_sv(cb_log_sub, G_DISCARD);

    FREETMPS;
    LEAVE;
}

void cb_download_wrapper ( const char *filename, off_t xfered, off_t total )
{
    SV *s_filename, *s_xfered, *s_total;
    dSP;

    if ( cb_download_sub == NULL ) return;

    ENTER;
    SAVETMPS;

    s_filename  = sv_2mortal( newSVpv( filename, strlen(filename) ) );
    s_xfered    = sv_2mortal( newSViv( xfered ) );
    s_total     = sv_2mortal( newSViv( total ) );
    
    PUSHMARK(SP);
    XPUSHs(s_filename);
    XPUSHs(s_xfered);
    XPUSHs(s_total);
    PUTBACK;

    call_sv(cb_download_sub, G_DISCARD);

    FREETMPS;
    LEAVE;
}

void cb_totaldl_wrapper ( off_t total )
{
    SV *s_total;
    dSP;

    if ( cb_totaldl_sub == NULL ) return;

    ENTER;
    SAVETMPS;

    s_total = sv_2mortal( newSViv( total ) );
    
    PUSHMARK(SP);
    XPUSHs(s_total);
    PUTBACK;

    call_sv( cb_totaldl_sub, G_DISCARD );

    FREETMPS;
    LEAVE;
}

int cb_fetch_wrapper ( const char *url, const char *localpath,
                       time_t mtimeold, time_t *mtimenew )
{
    time_t new_time;
    int    sub_retval_count;
    int    retval;

    dSP;
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs( sv_2mortal( newSVpv( url, strlen(url) ) ));
    XPUSHs( sv_2mortal( newSVpv( localpath, strlen(localpath) ) ));
    XPUSHs( sv_2mortal( newSViv( mtimeold ) ));

    sub_retval_count = call_sv( cb_fetch_sub, G_EVAL | G_SCALAR );
    
    SPAGAIN;

    if ( sub_retval_count == 0 || SvTRUE( ERRSV )) {
        retval = -1;
        /* not sure if we should print the error mesage */
    }
    else {
        new_time = (time_t) POPi;
        *mtimenew = new_time;
        retval = ( new_time == mtimeold ? 0 : 1 );
    }

    PUTBACK;
    FREETMPS;
    LEAVE;

    return retval;
}


/* We convert all enum constants into strings.  An event is now a hash
   with a name, status (start/done/failed/""), and arguments.
   Arguments can have any name in the hash they prefer.  The event
   hash is passed as a ref to the callback. */
void cb_trans_event_wrapper ( pmtransevt_t event, void *arg_one, void *arg_two )
{
    SV *s_pkg, *s_event_ref;
    HV *h_event;
    AV *a_args;
    dSP;

    if ( cb_trans_event_sub == NULL ) return;

    ENTER;
    SAVETMPS;

    h_event = newHV();

#define EVT_NAME(name) \
    hv_store( h_event, "name", 4, sv_2mortal( newSVpv( name, 0 )), 0 );

#define EVT_STATUS(name) \
    hv_store( h_event, "status", 6, sv_2mortal( newSVpv( name, 0 )), 0 );

#define EVT_PKG(key, pkgptr)                                    \
    s_pkg = newRV_inc( newSV(0) );                              \
    sv_setref_pv( s_pkg, "ALPM::PackageFree", (void *)pkgptr ); \
    hv_store( h_event, key, 0, s_pkg, 0 );

#define EVT_TEXT(key, text)    \
    hv_store( h_event, key, 0, \
              sv_2mortal( newSVpv( (char *)text, 0 )), 0 );

    switch ( event ) {
    case PM_TRANS_EVT_CHECKDEPS_START:
        EVT_NAME("checkdeps")
        EVT_STATUS("start")
        break;
    case PM_TRANS_EVT_CHECKDEPS_DONE:
        EVT_NAME("checkdeps")
        EVT_STATUS("done")
        break;
    case PM_TRANS_EVT_FILECONFLICTS_START:
        EVT_NAME("fileconflicts")
        EVT_STATUS("start")
        break;
	case PM_TRANS_EVT_FILECONFLICTS_DONE:
        EVT_NAME("fileconflicts")
        EVT_STATUS("done")
        break;
	case PM_TRANS_EVT_RESOLVEDEPS_START:
        EVT_NAME("resolvedeps")
        EVT_STATUS("start")
        break;
	case PM_TRANS_EVT_RESOLVEDEPS_DONE:
        EVT_NAME("resolvedeps")
        EVT_STATUS("done")
        break;
	case PM_TRANS_EVT_INTERCONFLICTS_START:
        EVT_NAME("interconflicts")
        EVT_STATUS("start")
        break;
	case PM_TRANS_EVT_INTERCONFLICTS_DONE:
        EVT_NAME("interconflicts")
        EVT_STATUS("done")
        EVT_PKG("target", arg_one)
        break;
	case PM_TRANS_EVT_ADD_START:
        EVT_NAME("add")
        EVT_STATUS("start")
        EVT_PKG("package", arg_one)
        break;
	case PM_TRANS_EVT_ADD_DONE:
        EVT_NAME("add")
        EVT_STATUS("done")
        EVT_PKG("package", arg_one)
        break;
	case PM_TRANS_EVT_REMOVE_START:
        EVT_NAME("remove")
        EVT_STATUS("start")
        EVT_PKG("package", arg_one)
		break;
	case PM_TRANS_EVT_REMOVE_DONE:
        EVT_NAME("remove")
        EVT_STATUS("done")
        EVT_PKG("package", arg_one)
		break;
	case PM_TRANS_EVT_UPGRADE_START:
        EVT_NAME("upgrade")
        EVT_STATUS("start")
        EVT_PKG("package", arg_one)
		break;
	case PM_TRANS_EVT_UPGRADE_DONE:
        EVT_NAME("upgrade")
        EVT_STATUS("done")
        EVT_PKG("new", arg_one)
        EVT_PKG("old", arg_two)
		break;
	case PM_TRANS_EVT_INTEGRITY_START:
        EVT_NAME("integrity")
        EVT_STATUS("start")
		break;
	case PM_TRANS_EVT_INTEGRITY_DONE:
        EVT_NAME("integrity")
        EVT_STATUS("done")
		break;
	case PM_TRANS_EVT_DELTA_INTEGRITY_START:
        EVT_NAME("deltaintegrity")
        EVT_STATUS("start")
		break;
	case PM_TRANS_EVT_DELTA_INTEGRITY_DONE:
        EVT_NAME("deltaintegrity")
        EVT_STATUS("done")
		break;
	case PM_TRANS_EVT_DELTA_PATCHES_START:
        EVT_NAME("deltapatches")
        EVT_STATUS("start")
		break;
	case PM_TRANS_EVT_DELTA_PATCHES_DONE:
        EVT_NAME("deltapatches")
        EVT_STATUS("done")
        EVT_TEXT("pkgname", arg_one)
        EVT_TEXT("patch", arg_two)
		break;
	case PM_TRANS_EVT_DELTA_PATCH_START:
        EVT_NAME("deltapatch")
        EVT_STATUS("start")
		break;
	case PM_TRANS_EVT_DELTA_PATCH_DONE:
        EVT_NAME("deltapatch")
        EVT_STATUS("done")
		break;
	case PM_TRANS_EVT_DELTA_PATCH_FAILED:
        EVT_NAME("deltapatch")
        EVT_STATUS("failed")
        EVT_TEXT("error", arg_one)
		break;
	case PM_TRANS_EVT_SCRIPTLET_INFO:
        EVT_NAME("scriplet")
        EVT_STATUS("")
        EVT_TEXT("text", arg_one)
		break;
    case PM_TRANS_EVT_RETRIEVE_START:
        EVT_NAME("retrieve")
        EVT_STATUS("start")
        break;        
    }

#undef EVT_NAME
#undef EVT_STATUS
#undef EVT_PKG
#undef EVT_TEXT

    s_event_ref = newRV_inc( (SV *)h_event );

    PUSHMARK(SP);
    XPUSHs(s_event_ref);
    PUTBACK;

    call_sv( cb_trans_event_sub, G_DISCARD );

    FREETMPS;
    LEAVE;
}

MODULE = ALPM    PACKAGE = ALPM

PROTOTYPES: DISABLE

INCLUDE: const-xs.inc

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

        if ( cb_log_sub != NULL ) SvREFCNT_dec( cb_log_sub );

        cb_log_sub = newSVsv(callback);
        alpm_option_set_logcb( cb_log_wrapper );
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

        if ( cb_download_sub != NULL ) SvREFCNT_dec( cb_download_sub );

        cb_download_sub = newSVsv(callback);
        alpm_option_set_dlcb( cb_download_wrapper );
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

        if ( cb_totaldl_sub != NULL ) SvREFCNT_dec( cb_totaldl_sub );

        cb_totaldl_sub = newSVsv(callback);
        alpm_option_set_totaldlcb( cb_totaldl_wrapper );
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

        if ( cb_fetch_sub != NULL ) SvREFCNT_dec( cb_fetch_sub );

        cb_fetch_sub = newSVsv(callback);
        alpm_option_set_fetchcb( cb_fetch_wrapper );
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

unsigned short
alpm_option_get_nopassiveftp()

void
alpm_option_set_nopassiveftp(nopasv)
    unsigned short nopasv

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

#--------------------------------------------------------------------------
# ALPM::DB Functions
#--------------------------------------------------------------------------

MODULE = ALPM    PACKAGE = ALPM    PREFIX=alpm_

ALPM_DB
alpm_db_register_local()

ALPM_DB
alpm_db_register_sync(sync_name)
    const char * sync_name

MODULE = ALPM   PACKAGE = ALPM::DB    PREFIX=alpm_db_

negative_is_error
alpm_db_unregister_all()

const char *
alpm_db_get_name(db)
    ALPM_DB db

const char *
alpm_db__get_url(db)
    ALPM_DB db
  CODE:
    RETVAL = alpm_db_get_url(db);
  OUTPUT:
    RETVAL

negative_is_error
alpm_db__set_server(db, url)
    ALPM_DB db
    const char * url
  CODE:
    RETVAL = alpm_db_setserver(db, url);
  OUTPUT:
    RETVAL

negative_is_error
alpm_db__update(db, level)
    ALPM_DB db
    int level
  CODE:
    RETVAL = alpm_db_update(level, db);
  OUTPUT:
    RETVAL

SV *
alpm_db_get_pkg(db, name)
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
alpm_db_get_pkg_cache(db)
    ALPM_DB db
  CODE:
    RETVAL = alpm_db_get_pkgcache(db);
  OUTPUT:
    RETVAL

PackageListNoFree
alpm_db_get_group(db, name)
    ALPM_DB      db
    const char   * name
  PREINIT:
    pmgrp_t *group;
  CODE:
    group = alpm_db_readgrp(db, name);
    RETVAL = ( group == NULL ? NULL : group->packages );
  OUTPUT:
    RETVAL
  
GroupList
alpm_db_get_group_cache(db)
    ALPM_DB       db
  CODE:
    RETVAL = alpm_db_get_grpcache(db);
  OUTPUT:
    RETVAL

PackageListFree
alpm_db__search(db, needles)
    ALPM_DB        db
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
alpm_pkg_compute_requiredby(pkg)
    ALPM_Package pkg

const char *
alpm_pkg_get_filename(pkg)
    ALPM_Package pkg

const char *
alpm_pkg_get_name(pkg)
    ALPM_Package pkg

const char *
alpm_pkg_get_version(pkg)
    ALPM_Package pkg

const char *
alpm_pkg_get_desc(pkg)
    ALPM_Package pkg

const char *
alpm_pkg_get_url(pkg)
    ALPM_Package pkg

time_t
alpm_pkg_get_builddate(pkg)
    ALPM_Package pkg

time_t
alpm_pkg_get_installdate(pkg)
    ALPM_Package pkg

const char *
alpm_pkg_get_packager(pkg)
    ALPM_Package pkg

const char *
alpm_pkg_get_md5sum(pkg)
    ALPM_Package pkg

const char *
alpm_pkg_get_arch(pkg)
    ALPM_Package pkg

off_t
alpm_pkg_get_size(pkg)
    ALPM_Package pkg

off_t
alpm_pkg_get_isize(pkg)
    ALPM_Package pkg

pmpkgreason_t
alpm_pkg_get_reason(pkg)
    ALPM_Package pkg

StringListNoFree
alpm_pkg_get_licenses(pkg)
    ALPM_Package pkg

StringListNoFree
alpm_pkg_get_groups(pkg)
    ALPM_Package pkg

DependList
alpm_pkg_get_depends(pkg)
    ALPM_Package pkg

StringListNoFree
alpm_pkg_get_optdepends(pkg)
    ALPM_Package pkg

StringListNoFree
alpm_pkg_get_conflicts(pkg)
    ALPM_Package pkg

StringListNoFree
alpm_pkg_get_provides(pkg)
    ALPM_Package pkg

StringListNoFree
alpm_pkg_get_deltas(pkg)
    ALPM_Package pkg

StringListNoFree
alpm_pkg_get_replaces(pkg)
    ALPM_Package pkg

StringListNoFree
alpm_pkg_get_files(pkg)
    ALPM_Package pkg

StringListNoFree
alpm_pkg_get_backup(pkg)
    ALPM_Package pkg

StringListNoFree
alpm_pkg_get_removes(pkg)
    ALPM_Package pkg

ALPM_DB
alpm_pkg_get_db(pkg)
    ALPM_Package pkg

# TODO: create get_changelog() method that does all this at once, easy with perl
# void *alpm_pkg_changelog_open(ALPM_Package pkg);
# size_t alpm_pkg_changelog_read(void *ptr, size_t size,
# 		const ALPM_Package pkg, const void *fp);
# int alpm_pkg_changelog_feof(const ALPM_Package pkg, void *fp);
# int alpm_pkg_changelog_close(const ALPM_Package pkg, void *fp);

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

MODULE=ALPM    PACKAGE=ALPM::Group    PREFIX=alpm_grp_

const char *
alpm_grp_get_name(grp)
    ALPM_Group grp

PackageListNoFree
alpm_grp_get_pkgs(grp)
    ALPM_Group grp

#-----------------------------------------------------------------------------
# TRANSACTIONS
#-----------------------------------------------------------------------------

MODULE=ALPM    PACKAGE=ALPM

negative_is_error
alpm_trans_init(type, flags, event_sub)
    int type
    int flags
    SV  *event_sub
  PREINIT:
    alpm_trans_cb_event event_func = NULL;
  CODE:
    # I'm guessing that event callbacks provided for previous transactions
    # shouldn't come into effect for later transactions unless explicitly
    # provided.
    if ( SvOK( event_sub ) ) {
        if ( ! SvTYPE( event_sub ) == SVt_PVCV ) {
            croak( "Callback arguments must be code references" );
        }
#       fprintf( stderr, "DEBUG: set event callback!\n" );
        cb_trans_event_sub = event_sub;
        event_func = cb_trans_event_wrapper;
    }
    else if ( cb_trans_event_sub != NULL ) {
        SvREFCNT_dec( cb_trans_event_sub );
        cb_trans_event_sub = NULL;
    }

    RETVAL = alpm_trans_init( type, flags, event_func, NULL, NULL );
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
alpm_trans_commit(self)
    SV * self
  PREINIT:
    alpm_list_t *errors;
    HV *trans;
    SV **prepared;
  CODE:
    /* make sure we are called as a method */
    if ( !( SvROK(self) /* && SvTYPE(self) == SVt_PVMG */
            && sv_isa( self, "ALPM::Transaction" ) ) ) {
        croak( "commit must be called as a method to ALPM::Transaction" );
    }

    trans = (HV *) SvRV(self);
    prepared = hv_fetch( trans, "prepared", 8, 0 );

    /* prepare before we commit */
    if ( ! SvOK(*prepared) || ! SvTRUE(*prepared) ) {
        PUSHMARK(SP);
        XPUSHs(self);
        PUTBACK;
#        fprintf( stderr, "DEBUG: before call_method\n" );
        call_method( "prepare", G_DISCARD );
#        fprintf( stderr, "DEBUG: after call_method\n" );
    }
    
    errors = NULL;
    RETVAL = alpm_trans_commit( &errors );
  OUTPUT:
    RETVAL

negative_is_error
alpm_trans_interrupt(self)
    SV * self
  CODE:
    RETVAL = alpm_trans_interrupt();
  OUTPUT:
    RETVAL

negative_is_error
alpm_trans_prepare(self)
    SV * self
  PREINIT:
    alpm_list_t *errors;
    HV *trans;
    SV **prepared;
  CODE:
    trans = (HV *) SvRV(self);

    prepared = hv_fetch( trans, "prepared", 8, 0 );
    if ( SvOK(*prepared) && SvTRUE(*prepared) ) {
        RETVAL = 0;
    }   
    else {
        hv_store( trans, "prepared", 8, newSViv(1), 0 );
        #fprintf( stderr, "DEBUG: ALPM::Transaction::prepare\n" );

        errors = NULL;
        RETVAL = alpm_trans_prepare( &errors );
    }
  OUTPUT:
    RETVAL

negative_is_error
alpm_trans_sysupgrade(self, enable_downgrade)
    SV * self
    int enable_downgrade
    
  CODE:
    RETVAL = alpm_trans_sysupgrade( enable_downgrade );
  OUTPUT:
    RETVAL

# EOF
