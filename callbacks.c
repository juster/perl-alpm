#include "alpm_xs.h"

/* CALLBACKS ***************************************************************/

/* Code references to use as callbacks. */
SV *cb_log_sub      = NULL;
SV *cb_dl_sub = NULL;
SV *cb_totaldl_sub  = NULL;
SV *cb_fetch_sub    = NULL;
/* transactions */
SV *cb_trans_event_sub    = NULL;
SV *cb_trans_conv_sub     = NULL;
SV *cb_trans_progress_sub = NULL;

/* String constants to use for log levels (instead of bitflags) */
const char * log_lvl_error    = "error";
const char * log_lvl_warning  = "warning";
const char * log_lvl_debug    = "debug";
const char * log_lvl_function = "function";
const char * log_lvl_unknown  = "unknown";

void cb_log_wrapper ( pmloglevel_t level, char * format, va_list args )
{
    SV *s_level, *s_message;
    char *lvl_str, buffer[256];
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
    vsnprintf( buffer, 255, format, args );
    sv_setpv( s_message, buffer );

    /* The following gets screwed up by j's: %jd or %ji, etc... */
    /*sv_vsetpvfn( s_message, format, strlen(format), &args,
                 (SV **)NULL, 0, NULL );*/
    
    PUSHMARK(SP);
    XPUSHs(s_level);
    XPUSHs(s_message);
    PUTBACK;

    call_sv(cb_log_sub, G_DISCARD);

    FREETMPS;
    LEAVE;
}

void cb_dl_wrapper ( const char *filename, off_t xfered, off_t total )
{
    SV *s_filename, *s_xfered, *s_total;
    dSP;

    if ( cb_dl_sub == NULL ) return;

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

    call_sv(cb_dl_sub, G_DISCARD);

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

int cb_fetch_wrapper ( const char *url, const char *localpath, int force )
{
    time_t new_time;
    int    count;
    SV     *result;
    int    retval;
    dSP;

    /* We shouldn't be called if cb_fetch_sub is null, return error. */
    if ( cb_fetch_sub == NULL ) return -1;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs( sv_2mortal( newSVpv( url, strlen(url) )));
    XPUSHs( sv_2mortal( newSVpv( localpath, strlen(localpath) )));
    XPUSHs( sv_2mortal( newSViv( force )));
    PUTBACK;

    count = call_sv( cb_fetch_sub, G_EVAL | G_SCALAR );

    SPAGAIN;

    result = POPs;

    /* If a perl error occurred, give an automatic warning. */
    if ( ! SvTRUE( result ) || SvTRUE( ERRSV ) ) {
        if ( SvTRUE( ERRSV )) warn( SvPV_nolen( ERRSV ));
        retval = -1;
    }
    /* The perl code must be sure to return 0 or 1 properly. */
    else if ( ! SvIOK( result )) {
        /* What if it didn't return a number?  Return an error. */
        retval = -1;
    }
    else {
        retval = SvIV( result );
    }

    PUTBACK;
    FREETMPS;
    LEAVE;

    return retval;
}

/* TRANSACTION CALLBACKS ***************************************************/

/* We convert all enum constants into strings.  An event is now a hash
   with a name, status (start/done/failed/""), and arguments.
   Arguments can have any name in the hash they prefer.  The event
   hash is passed as a ref to the callback. */
void cb_trans_event_wrapper ( pmtransevt_t event,
                              void *arg_one, void *arg_two )
{
    SV *s_pkg, *s_event_ref;
    HV *h_event;
    AV *a_args;
    dSP;

    if ( cb_trans_event_sub == NULL ) return;

    ENTER;
    SAVETMPS;

    h_event = (HV*) sv_2mortal( (SV*) newHV() );

#define EVT_NAME(name) \
    hv_store( h_event, "name", 4, newSVpv( name, 0 ), 0 );

#define EVT_STATUS(name) \
    hv_store( h_event, "status", 6, newSVpv( name, 0 ), 0 );

#define EVT_PKG(key, pkgptr)                                    \
    s_pkg = newRV_noinc( newSV(0) );                            \
    sv_setref_pv( s_pkg, "ALPM::Package", (void *)pkgptr );     \
    hv_store( h_event, key, strlen(key), s_pkg, 0 );

#define EVT_TEXT(key, text)    \
    hv_store( h_event, key, 0, \
              newSVpv( (char *)text, 0 ), 0 );

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
        EVT_TEXT("db", arg_one)
        break;
    case PM_TRANS_EVT_DISKSPACE_START:
        EVT_NAME("diskspace")
        EVT_STATUS("start")
        break;
    case PM_TRANS_EVT_DISKSPACE_DONE:
        EVT_NAME("diskspace")
        EVT_STATUS("done")
        break;
    }

#undef EVT_NAME
#undef EVT_STATUS
#undef EVT_PKG
#undef EVT_TEXT

    s_event_ref = newRV_noinc( (SV *)h_event );

    PUSHMARK(SP);
    XPUSHs(s_event_ref);
    PUTBACK;

    call_sv( cb_trans_event_sub, G_DISCARD );

    FREETMPS;
    LEAVE;

    return;
}

void cb_trans_conv_wrapper ( pmtransconv_t type,
                             void *arg_one, void *arg_two, void *arg_three,
                             int *result )
{
    HV *h_event;
    SV *s_pkg;
    dSP;

    if ( cb_trans_conv_sub == NULL ) return;

    ENTER;
    SAVETMPS;

    h_event = (HV*) sv_2mortal( (SV*) newHV() );

#define EVT_PKG(key, pkgptr)                                    \
    do {                                                        \
        s_pkg = newRV_noinc( newSV(0) );                        \
        sv_setref_pv( s_pkg, "ALPM::Package", (void *)pkgptr ); \
        hv_store( h_event, key, strlen(key), s_pkg, 0 );        \
    } while (0)

#define EVT_TEXT(key, text)                                     \
    do {                                                        \
        hv_store( h_event, key, strlen(key),                    \
                  newSVpv( (char *)text, 0 ), 0 ); \
    } while (0)

#define EVT_NAME( NAME ) EVT_TEXT("name", NAME)

#define EVT_PKGLIST( KEY, PKGLIST )                                   \
    do {                                                              \
        hv_store( h_event, KEY, strlen( KEY ),                        \
                  convert_packagelist( (alpm_list_t *)PKGLIST ), 0 ); \
    } while ( 0 )

    hv_store( h_event, "id", 2, newSViv(type), 0 );
    
    switch ( type ) {
    case PM_TRANS_CONV_INSTALL_IGNOREPKG:
        EVT_NAME( "install_ignore" );
        EVT_PKG ( "package", arg_one );
        break;
    case PM_TRANS_CONV_REPLACE_PKG:
        EVT_NAME( "replace_package" );
        EVT_PKG ( "old", arg_one );
        EVT_PKG ( "new", arg_two );
        EVT_TEXT( "db",  arg_three  );
        break;
    case PM_TRANS_CONV_CONFLICT_PKG:
        EVT_NAME( "package_conflict" );
        EVT_TEXT( "target",   arg_one );
        EVT_TEXT( "local",    arg_two );
        EVT_TEXT( "conflict", arg_three );
        break;
    case PM_TRANS_CONV_REMOVE_PKGS:
        EVT_NAME   ( "remove_packages" );
        EVT_PKGLIST( "packages", arg_one );
        break;
    case PM_TRANS_CONV_LOCAL_NEWER:
        EVT_NAME( "local_newer"      );
        EVT_PKG ( "package", arg_one );
        break;
    case PM_TRANS_CONV_CORRUPTED_PKG:
        EVT_NAME( "corrupted_file" );
        EVT_TEXT( "filename", arg_one );
        break;
    }

#undef EVENT
#undef EVT_NAME
#undef EVT_PKG
#undef EVT_TEXT
#undef EVT_PKGLIST

    PUSHMARK(SP);
    XPUSHs( newRV_noinc( (SV *)h_event ));
    PUTBACK;

    /* fprintf( stderr, "DEBUG: trans conv callback start\n" ); */

    call_sv( cb_trans_conv_sub, G_SCALAR );

    /* fprintf( stderr, "DEBUG: trans conv callback stop\n" ); */

    SPAGAIN;

    *result = POPi;

    PUTBACK;
    FREETMPS;
    LEAVE;

    return;
}

void cb_trans_progress_wrapper( pmtransprog_t type,
                                const char * desc,
                                int item_progress,
                                size_t total_count,
                                size_t total_pos )
{
    HV *h_event;
    dSP;

    if ( cb_trans_progress_sub == NULL ) return;

    ENTER;
    SAVETMPS;

    h_event = (HV*) sv_2mortal( (SV*) newHV() );

#define EVT_TEXT(key, text)                        \
    do {                                           \
        hv_store( h_event, key, strlen(key),       \
                  newSVpv( (char *)text, 0 ), 0 ); \
    } while (0)

#define EVT_NAME( NAME ) EVT_TEXT("name", NAME); break;

#define EVT_INT(KEY, INT)                          \
    do {                                           \
        hv_store( h_event, KEY, strlen(KEY),       \
                  newSViv(INT), 0 );               \
    } while (0)

    switch( type ) {
    case PM_TRANS_PROGRESS_ADD_START:       EVT_NAME( "add"       );
    case PM_TRANS_PROGRESS_UPGRADE_START:   EVT_NAME( "upgrade"   );
    case PM_TRANS_PROGRESS_REMOVE_START:    EVT_NAME( "remove"    );
    case PM_TRANS_PROGRESS_CONFLICTS_START: EVT_NAME( "conflicts" );
    }

    EVT_INT ( "id",          type );
    EVT_TEXT( "desc",        desc );
    EVT_INT ( "item",        item_progress );
    EVT_INT ( "total_count", total_count );
    EVT_INT ( "total_pos",   total_pos );

#undef EVT_INT
#undef EVT_NAME

    PUSHMARK(SP);
    XPUSHs( newRV_noinc( (SV *)h_event ));
    PUTBACK;

    /* fprintf( stderr, "DEBUG: trans progress callback start\n" ); */

    call_sv( cb_trans_progress_sub, G_SCALAR );

    /* fprintf( stderr, "DEBUG: trans progress callback stop\n" ); */

    PUTBACK;
    FREETMPS;
    LEAVE;

    return;
}

