MODULE = ALPM    PACKAGE = ALPM

DatabaseList
alpm_option_get_syncdbs()

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

int
alpm_option_get_usesyslog()

void
alpm_option_set_usesyslog(usesyslog)
    int usesyslog

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

const char *
alpm_option_get_arch ()

void
alpm_option_set_arch ( arch )
    const char * arch

int
alpm_option_get_usedelta()

void
alpm_option_set_usedelta(usedelta)
    int usedelta

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

# EOF
