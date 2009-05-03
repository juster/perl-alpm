#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <alpm.h>
#include <alpm_list.h>

/* These are missing in alpm.h */

/* from deps.h */
struct __pmdepend_t {
	pmdepmod_t mod;
	char *name;
	char *version;
};

/* from group.h */
struct __pmgrp_t {
	/** group name */
	char *name;
	/** list of pmpkg_t packages */
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

MODULE = ALPM    PACKAGE = ALPM::ListAutoFree

PROTOTYPES: DISABLE

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
load_pkgfile(filename, ...)
    const char *filename
  PREINIT:
    pmpkg_t *pkg;
    unsigned short full;
  CODE:
    full = ( items > 1 ? 1 : 0 );
    if ( alpm_pkg_load( filename, full, &pkg ) != 0 )
        croak( "ALPM Error: %s", alpm_strerror( pm_errno ));
    RETVAL = pkg;
  OUTPUT:
    RETVAL

MODULE = ALPM    PACKAGE = ALPM    PREFIX=alpm_

negative_is_error
alpm_initialize()

negative_is_error
alpm_release()

MODULE = ALPM    PACKAGE = ALPM    PREFIX=alpm_option_

#alpm_cb_log alpm_option_get_logcb();
#void alpm_option_set_logcb(alpm_cb_log cb);
#
#alpm_cb_download alpm_option_get_dlcb();
#void alpm_option_set_dlcb(alpm_cb_download cb);
#
#alpm_cb_totaldl alpm_option_get_totaldlcb();
#void alpm_option_set_totaldlcb(alpm_cb_totaldl cb);

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
alpm_option_get_holdpkgs()

void
alpm_option_add_holdpkg(pkg)
    const char * pkg

void
alpm_option_set_holdpkgs(holdpkgs_list)
    StringListNoFree holdpkgs_list

negative_is_error
alpm_option_remove_holdpkg(pkg)
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

const char *
alpm_option_get_xfercommand()

void
alpm_option_set_xfercommand(cmd)
    const char * cmd

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

MODULE = ALPM    PACKAGE = ALPM    PREFIX=alpm_

ALPM_DB
alpm_db_register_local()

ALPM_DB
alpm_db_register_sync(sync_name)
    const char * sync_name

MODULE = ALPM   PACKAGE = ALPM::DB

negative_is_error
DESTROY(self)
    ALPM_DB self
  CODE:
    alpm_db_unregister( self );
  OUTPUT:
    RETVAL

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
alpm_db_update(db, level)
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
    RETVAL = alpm_db_getpkgcache(db);
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
    RETVAL = alpm_db_getgrpcache(db);
  OUTPUT:
    RETVAL

PackageListFree
alpm_db_search(db, needles)
    ALPM_DB        db
    StringListFree needles

MODULE=ALPM    PACKAGE=ALPM::Package    PREFIX=alpm_pkg_
    
negative_is_error
alpm_pkg_checkmd5sum(pkg)
    ALPM_Package pkg

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

MODULE=ALPM    PACKAGE=ALPM::Group    PREFIX=alpm_grp_

const char *
alpm_grp_get_name(grp)
    ALPM_Group grp

PackageListNoFree
alpm_grp_get_pkgs(grp)
    ALPM_Group grp
