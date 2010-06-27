#include "alpm_xs.h"

/* CONVERTER FUNCTIONS ******************************************************/

/* These all convert C data structures to their Perl counterparts */

SV * convert_stringlist ( alpm_list_t * string_list )
{
    AV *string_array = newAV();
    alpm_list_t *iter;
    for ( iter = string_list; iter; iter = iter->next ) {
        SV *string = newSVpv( iter->data, strlen( iter->data ) );
        av_push( string_array, string );
    }
    return newRV_noinc( (SV *)string_array );
}

SV * convert_packagelist ( alpm_list_t * alpm_pkg_list )
{
    /* copied from the typemap */
    AV * package_list;
    SV * package_obj;
    alpm_list_t *iter;

    package_list = newAV();
    iter         = alpm_pkg_list;

    while ( iter != NULL ) {
        package_obj = newSV(0);
        sv_setref_pv( package_obj, "ALPM::Package", iter->data );
        av_push( package_list, package_obj );
        iter = iter->next;
    }

    /* if ( alpm_pkg_list != NULL ) */
    /*     alpm_list_free( alpm_pkg_list ); */

    return newRV_noinc( (SV *)package_list );
}

SV * convert_depend ( const pmdepend_t * depend )
{
    HV *depend_hash;
    SV *depend_ref;
    pmdepmod_t depmod;

    depend_hash = newHV();
    depend_ref  = newRV_noinc( (SV *)depend_hash );
        
    hv_store( depend_hash, "name", 4, newSVpv( depend->name, 0 ), 0 );
    
    if ( depend->version != NULL ) {
        hv_store( depend_hash, "version", 7, newSVpv( depend->version, 0 ),
                  0 );
    }
    
    depmod = depend->mod;
    if ( depmod != 1 ) {
        hv_store( depend_hash, "mod", 3,
                  newSVpv( ( depmod == 2 ? "==" :
                             depmod == 3 ? ">=" :
                             depmod == 4 ? "<=" :
                             depmod == 5 ? ">"  :
                             depmod == 6 ? "<"  :
                             "ERROR" ), 0 ),
                  0 );
    }

    return depend_ref;
}

SV * convert_depmissing ( const pmdepmissing_t * depmiss )
{
    HV *depmiss_hash;

    depmiss_hash = newHV();
    hv_store( depmiss_hash, "target", 6,
              newSVpv( depmiss->target, 0 ), 0 );
    hv_store( depmiss_hash, "cause", 5,
              newSVpv( depmiss->causingpkg, 0 ), 0 );
    hv_store( depmiss_hash, "depend", 6,
              convert_depend( depmiss->depend ), 0 );
    return newRV_noinc( (SV *)depmiss_hash );
}

SV * convert_conflict ( const pmconflict_t * conflict )
{
    AV *conflict_list;
    HV *conflict_hash;

    conflict_list = newAV();
    conflict_hash = newHV();

    av_push( conflict_list, newSVpv( conflict->package1, 0 ) );
    av_push( conflict_list, newSVpv( conflict->package2, 0 ) );

    hv_store( conflict_hash, "packages", 8,
              newRV_noinc( (SV *)conflict_list ), 0 );
    hv_store( conflict_hash, "reason", 6,
              newSVpv( conflict->reason, 0 ), 0 );

    return newRV_noinc( (SV *)conflict_hash );
}

SV * convert_fileconflict ( const pmfileconflict_t * fileconflict )
{
    HV *conflict_hash;

    conflict_hash = newHV();
    hv_store( conflict_hash, "type", 4,
              newSVpv( ( fileconflict->type == PM_FILECONFLICT_TARGET ?
                         "target" :
                         fileconflict->type == PM_FILECONFLICT_FILESYSTEM ?
                         "filesystem" : "ERROR" ), 0 ), 0);
    hv_store( conflict_hash, "target", 6, newSVpv( fileconflict->target, 0 ),
              0 );
    hv_store( conflict_hash, "file", 4, newSVpv( fileconflict->file, 0 ),
              0 );
    hv_store( conflict_hash, "ctarget", 7, newSVpv( fileconflict->ctarget, 0 ),
              0 );

    return newRV_noinc( (SV *)conflict_hash );
}

void free_stringlist_errors ( char *string )
{
    free(string);
}

/* Copy/pasted from ALPM's conflict.c */
void free_fileconflict_errors ( pmfileconflict_t *conflict )
{
	if ( strlen( conflict->ctarget ) > 0 ) {
		free(conflict->ctarget);
	}
	free(conflict->file);
	free(conflict->target);
	free(conflict);
}

/* Copy/pasted from ALPM's deps.c */
void free_depmissing_errors ( pmdepmissing_t *miss )
{
	free(miss->depend->name);
	free(miss->depend->version);
	free(miss->depend);

	free(miss->target);
	free(miss->causingpkg);
	free(miss);
}

/* Copy/pasted from ALPM's conflict.c */
void free_conflict_errors ( pmconflict_t *conflict )
{
	free(conflict->package2);
	free(conflict->package1);
    free(conflict->reason);
	free(conflict);
}

SV * convert_trans_errors ( alpm_list_t * errors )
{
    HV *error_hash;
    AV *error_list;
    alpm_list_t *iter;
    SV *ref;

    error_hash = newHV();
    error_list = newAV();

    hv_store( error_hash, "msg", 3,
              newSVpv( alpm_strerror( pm_errno ), 0 ), 0 );

    /* First convert the error list returned by the transaction
       into an array reference.  Also store the type. */

#define MAPERRLIST( TYPE )                                              \
    hv_store( error_hash, "type", 4, newSVpv( #TYPE, 0 ), 0 );          \
    for ( iter = errors ; iter ; iter = iter->next ) {                  \
        ref = convert_ ## TYPE ((pm ## TYPE ## _t *) iter->data );      \
        av_push( error_list, ref );                                     \
    }                                                                   \
    alpm_list_free_inner( errors,                                       \
                          (alpm_list_fn_free)                           \
                          free_ ## TYPE ## _errors );                   \
    alpm_list_free( errors );                                           \
    break

#define convert_invalid_delta(STR) newSVpv( STR, 0 )
#define pminvalid_delta_t char
#define free_invalid_delta_errors free
#define convert_invalid_package(STR) newSVpv( STR, 0 )
#define pminvalid_package_t char
#define free_invalid_package_errors free
#define convert_invalid_arch(STR) newSVpv( STR, 0 )
#define pminvalid_arch_t          char
#define free_invalid_arch_errors  free


    switch ( pm_errno ) {
    case PM_ERR_FILE_CONFLICTS:    MAPERRLIST( fileconflict );
    case PM_ERR_UNSATISFIED_DEPS:  MAPERRLIST( depmissing );
    case PM_ERR_CONFLICTING_DEPS:  MAPERRLIST( conflict );
    case PM_ERR_DLT_INVALID:       MAPERRLIST( invalid_delta );
    case PM_ERR_PKG_INVALID:       MAPERRLIST( invalid_package );
    case PM_ERR_PKG_INVALID_ARCH:  MAPERRLIST( invalid_arch );
    default:
        SvREFCNT_dec( (SV *)error_hash );
        SvREFCNT_dec( (SV *)error_list );
        return NULL;
    }

#undef MAPERRLIST
#undef convert_invalid_delta
#undef pminvalid_delta_t
#undef free_invalid_delta_errors
#undef convert_invalid_package
#undef pminvalid_package_t
#undef free_invalid_package_errors
    
    hv_store( error_hash, "list", 4, newRV_noinc( (SV *)error_list ),
              0 );

    ref = newRV_noinc( (SV *)error_hash );
    return ref;
}
