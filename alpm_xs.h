#ifndef ALPM_XS_H
#define ALPM_XS_H

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <alpm.h>

/* These are missing in alpm.h */

/* from deps.h */
struct __pmdepend_t {
	pmdepmod_t mod;
	char *name;
	char *version;
};

struct __pmdepmissing_t {
	char *target;
	pmdepend_t *depend;
	char *causingpkg; /* this is used in case of remove dependency error only */
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

/* from conflicts.h */

struct __pmconflict_t {
    char *package1;
    char *package2;
    char *reason;
};

struct __pmfileconflict_t {
    char *target;
    pmfileconflicttype_t type;
    char *file;
    char *ctarget;
};

typedef int           negative_is_error;
typedef pmdb_t      * ALPM_DB;
typedef pmpkg_t     * ALPM_Package;
typedef pmpkg_t     * ALPM_PackageFree;
typedef pmgrp_t     * ALPM_Group;

typedef pmdepend_t  * DependHash;
typedef pmconflict_t * ConflictArray;

typedef alpm_list_t * StringListFree;
typedef alpm_list_t * StringListNoFree;
typedef alpm_list_t * PackageListFree;
typedef alpm_list_t * PackageListNoFree;
typedef alpm_list_t * GroupList;
typedef alpm_list_t * DatabaseList;
typedef alpm_list_t * DependList;
typedef alpm_list_t * ListAutoFree;

/* Code references to use as callbacks. */
extern SV *cb_log_sub;
extern SV *cb_dl_sub;
extern SV *cb_totaldl_sub;
extern SV *cb_fetch_sub;

/* transactions */
extern SV *cb_trans_event_sub;
extern SV *cb_trans_conv_sub;
extern SV *cb_trans_progress_sub;

/* String constants to use for log levels (instead of bitflags) */
extern const char * log_lvl_error;
extern const char * log_lvl_warning;
extern const char * log_lvl_debug;
extern const char * log_lvl_function;
extern const char * log_lvl_unknown;

/* CALLBACKS ****************************************************************/

#define DEF_SET_CALLBACK( CBTYPE )                                  \
    if ( ! SvOK(callback) && cb_ ## CBTYPE ## _sub != NULL ) {      \
        SvREFCNT_dec( cb_ ## CBTYPE ## _sub );                      \
        alpm_option_set_ ## CBTYPE ## cb( NULL );                   \
        cb_ ## CBTYPE ## _sub = NULL;                               \
    }                                                               \
    else {                                                          \
        if ( !SvROK(callback)                                       \
             || SvTYPE( SvRV(callback) ) != SVt_PVCV ) {            \
            croak( "value for %scb option must be a code reference", \
                   #CBTYPE );                                       \
        }                                                           \
        if ( cb_ ## CBTYPE ## _sub ) {                              \
            sv_setsv( cb_ ## CBTYPE ## _sub, callback );            \
        }                                                           \
        else {                                                      \
            cb_ ## CBTYPE ## _sub = newSVsv(callback);              \
            alpm_option_set_ ## CBTYPE ## cb                        \
                ( cb_ ## CBTYPE ## _wrapper );                      \
        }                                                           \
    }

#define DEF_GET_CALLBACK( CBTYPE )                          \
    RETVAL = ( cb_ ## CBTYPE ## _sub == NULL                \
               ? &PL_sv_undef : cb_ ## CBTYPE ## _sub );

void cb_log_wrapper ( pmloglevel_t level, char * format, va_list args );
void cb_dl_wrapper ( const char *filename, off_t xfered, off_t total );
void cb_totaldl_wrapper ( off_t total );
int  cb_fetch_wrapper ( const char *url, const char *localpath, int force );

/* TRANSACTIONS ************************************************************/

/* This macro is used inside alpm_trans_init.
   CB_NAME is one of the transaction callback types (event, conv, progress).

   * [CB_NAME]_sub is the argument to the trans_init XSUB.
   * [CB_NAME]_func is a variable to hold the function pointer to pass
     to the real C ALPM function.
   * cb_trans_[CB_NAME]_wrapper is the name of the C wrapper function which
     calls the perl sub stored in the global variable:
   * cb_trans_[CB_NAME]_sub.
*/
#define UPDATE_TRANS_CALLBACK( CB_NAME )                                \
    if ( SvOK( CB_NAME ## _sub ) ) {                                    \
        if ( SvTYPE( SvRV( CB_NAME ## _sub ) ) != SVt_PVCV ) {          \
            croak( "Callback arguments must be code references" );      \
        }                                                               \
        if ( cb_trans_ ## CB_NAME ## _sub ) {                           \
            sv_setsv( cb_trans_ ## CB_NAME ## _sub, CB_NAME ## _sub );   \
        }                                                               \
        else {                                                          \
            cb_trans_ ## CB_NAME ## _sub = newSVsv( CB_NAME ## _sub );  \
        }                                                               \
        CB_NAME ## _func = cb_trans_ ## CB_NAME ## _wrapper;            \
    }                                                                   \
    else if ( cb_trans_ ## CB_NAME ## _sub != NULL ) {                  \
        /* If no event callback was provided for this new transaction,  \
           and an event callback is active, then remove the old callback. */ \
        SvREFCNT_dec( cb_trans_ ## CB_NAME ## _sub );                   \
        cb_trans_ ## CB_NAME ## _sub = NULL;                            \
    }

void cb_trans_event_wrapper ( pmtransevt_t event,
                              void *arg_one, void *arg_two );
void cb_trans_conv_wrapper ( pmtransconv_t type,
                             void *arg_one, void *arg_two, void *arg_three,
                             int *result );
void cb_trans_progress_wrapper( pmtransprog_t type,
                                const char * desc,
                                int item_progress,
                                int total_count, int total_pos );

/* CONVERSION  *************************************************************/

SV * convert_stringlist ( alpm_list_t * string_list );
SV * convert_depend ( const pmdepend_t * depend );
SV * convert_depmissing ( const pmdepmissing_t * depmiss );
SV * convert_conflict ( const pmconflict_t * conflict );
SV * convert_fileconflict ( const pmfileconflict_t * fileconflict );
void free_stringlist_errors ( char *string );
void free_fileconflict_errors ( pmfileconflict_t *conflict );
void free_depmissing_errors ( pmdepmissing_t *miss );
void free_conflict_errors ( pmconflict_t *conflict );
SV * convert_trans_errors ( alpm_list_t * errors );

#endif
