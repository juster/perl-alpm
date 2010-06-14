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
