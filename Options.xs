MODULE = ALPM    PACKAGE = ALPM

DatabaseList
alpm_option_get_syncdbs()

SV *
alpm_option_get_logcb()
  CODE:
    DEF_GET_CALLBACK( log )
  OUTPUT:
    RETVAL

void
alpm_option_set_logcb ( callback )
    SV * callback
  CODE:
    DEF_SET_CALLBACK( log )

SV *
alpm_option_get_dlcb()
  CODE:
    DEF_GET_CALLBACK( dl )
  OUTPUT:
    RETVAL

void
alpm_option_set_dlcb(callback)
    SV * callback
  CODE:
    DEF_SET_CALLBACK( dl )

SV *
alpm_option_get_totaldlcb()
  CODE:
    DEF_GET_CALLBACK( totaldl )
  OUTPUT:
    RETVAL

void
alpm_option_set_totaldlcb(callback)
    SV * callback
  CODE:
    DEF_SET_CALLBACK( totaldl )

SV *
alpm_option_get_fetchcb()
  CODE:
    DEF_GET_CALLBACK( fetch )
  OUTPUT:
    RETVAL

void
alpm_option_set_fetchcb(callback)
    SV * callback
  CODE:
    DEF_SET_CALLBACK( fetch )

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
