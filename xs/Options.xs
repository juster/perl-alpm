MODULE = ALPM    PACKAGE = ALPM

#############################################################################
## CALLBACKS

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

#############################################################################

const char *
option_string_get ( )
INTERFACE:
    alpm_option_get_root
    alpm_option_get_dbpath
    alpm_option_get_cachedirs
    alpm_option_get_logfile
    alpm_option_get_lockfile
    alpm_option_get_arch

negative_is_error
option_string_set ( string )
    const char * string
INTERFACE:
    alpm_option_set_root
    alpm_option_set_dbpath
    alpm_option_set_cachedirs
    alpm_option_set_logfile

# the set_arch function has a void return type! we can't use it above

void
alpm_option_set_arch ( new_arch )
    const char * new_arch

StringListNoFree
option_stringlist_get ( )
INTERFACE:
    alpm_option_get_cachedirs
    alpm_option_get_noupgrades
    alpm_option_get_noextracts
    alpm_option_get_ignorepkgs
    alpm_option_get_ignoregrps

void
option_stringlist_add ( add_string )
    const char * add_string
INTERFACE:
    alpm_option_add_noupgrade
    alpm_option_add_noextract
    alpm_option_add_ignorepkg
    alpm_option_add_ignoregrp

# add_cachedir is the only add_ func that doesn't return void
negative_is_error
alpm_option_add_cachedir ( new_cachedir )
    const char * new_cachedir

void
option_stringlist_set ( stringlist )
    StringListNoFree stringlist
INTERFACE:
    alpm_option_set_cachedirs
    alpm_option_set_noupgrades
    alpm_option_set_noextracts
    alpm_option_set_ignorepkgs
    alpm_option_set_ignoregrps

void
option_stringlist_remove ( badstring )
    const char * badstring
INTERFACE:
    alpm_option_remove_cachedir
    alpm_option_remove_noupgrade
    alpm_option_remove_noextract
    alpm_option_remove_ignorepkg
    alpm_option_remove_ignoregrp

int
option_int_get ( )
INTERFACE:
    alpm_option_get_usesyslog
    alpm_option_get_usedelta

void
option_int_set ( new_int )
    int new_int
INTERFACE:
    alpm_option_set_usesyslog
    alpm_option_set_usedelta

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

# EOF
