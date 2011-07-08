# PUBLIC ####################################################################

MODULE = ALPM    PACKAGE = ALPM::Package

SV *
changelog(pkg)
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

StringListFree
requiredby(pkg)
    ALPM_Package pkg
  CODE:
    RETVAL = alpm_pkg_compute_requiredby(pkg);
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
alpm_pkg_has_scriptlet(pkg)
    ALPM_Package pkg

off_t
alpm_pkg_download_size(newpkg)
    ALPM_Package newpkg

MODULE = ALPM    PACKAGE = ALPM::Package    PREFIX = alpm_pkg_get_

const char *
package_get_string ( package )
    ALPM_Package package
INTERFACE:
    alpm_pkg_get_filename
    alpm_pkg_get_name
    alpm_pkg_get_version
    alpm_pkg_get_desc
    alpm_pkg_get_url
    alpm_pkg_get_packager
    alpm_pkg_get_md5sum
    alpm_pkg_get_arch

time_t
package_get_time ( package )
    ALPM_Package package
INTERFACE:
    alpm_pkg_get_builddate
    alpm_pkg_get_installdate

off_t
package_get_offset ( package )
    ALPM_Package package
INTERFACE:
    alpm_pkg_get_size
    alpm_pkg_get_isize

pmpkgreason_t
alpm_pkg_get_reason(pkg)
    ALPM_Package pkg

StringListNoFree
package_get_stringlist ( package )
    ALPM_Package package
INTERFACE:
    alpm_pkg_get_licenses
    alpm_pkg_get_groups
    alpm_pkg_get_optdepends
    alpm_pkg_get_conflicts
    alpm_pkg_get_provides
    alpm_pkg_get_deltas
    alpm_pkg_get_replaces
    alpm_pkg_get_files
    alpm_pkg_get_backup

DependList
alpm_pkg_get_depends(pkg)
    ALPM_Package pkg

ALPM_DB
alpm_pkg_get_db(pkg)
    ALPM_Package pkg
