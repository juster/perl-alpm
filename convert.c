#include "alpm_xs.h"

/* CONVERTER FUNCTIONS ******************************************************/

/* These all convert C data structures to their Perl counterparts */

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
        iter = alpm_list_next( iter );
    }

    /* if ( alpm_pkg_list != NULL ) */
    /*     alpm_list_free( alpm_pkg_list ); */

    return newRV_noinc( (SV *)package_list );
}

SV * convert_depend ( pmdepend_t * depend )
{
    HV *depend_hash;
    SV *depend_ref, *mod;
    pmdepmod_t depmod;
    const char * depver;

    depend_hash = newHV();
    depend_ref  = newRV_noinc( (SV *)depend_hash );
        
    hv_store( depend_hash, "name", 4,
              newSVpv( alpm_dep_get_name( depend ), 0 ), 0 );

    depver = alpm_dep_get_version( depend );
    if ( depver != NULL ) {
        hv_store( depend_hash, "version", 7,
                  newSVpv( depver, 0 ),
                  0 );
    }
    
    mod = perl_depmod(alpm_dep_get_mod(depend));
    hv_store(depend_hash, "mod", 3, mod, 0);
    return depend_hash;
}

    return depend_ref;
}

SV * convert_depmissing ( pmdepmissing_t * depmiss )
{
    HV *depmiss_hash;

    depmiss_hash = newHV();
    hv_store( depmiss_hash, "target", 6,
              newSVpv( alpm_miss_get_target( depmiss ), 0 ), 0 );
    hv_store( depmiss_hash, "cause", 5,
              newSVpv( alpm_miss_get_causingpkg( depmiss ), 0 ), 0 );
    hv_store( depmiss_hash, "depend", 6,
              convert_depend( alpm_miss_get_dep( depmiss )), 0 );
    return newRV_noinc( (SV *)depmiss_hash );
}

SV * convert_conflict ( pmconflict_t * conflict )
{
    AV *conflict_list;
    HV *conflict_hash;

    conflict_list = newAV();
    conflict_hash = newHV();

    av_push( conflict_list,
             newSVpv( alpm_conflict_get_package1( conflict ), 0 ) );
    av_push( conflict_list,
             newSVpv( alpm_conflict_get_package2( conflict ), 0 ) );

    hv_store( conflict_hash, "packages", 8,
              newRV_noinc( (SV *)conflict_list ), 0 );
    hv_store( conflict_hash, "reason", 6,
              newSVpv( alpm_conflict_get_reason( conflict ), 0 ), 0 );

    return newRV_noinc( (SV *)conflict_hash );
}

SV * convert_fileconflict ( pmfileconflict_t * fileconflict )
{
    HV *conflict_hash;
    pmfileconflicttype_t contype;

    contype       = alpm_fileconflict_get_type( fileconflict );
    conflict_hash = newHV();

    hv_store( conflict_hash, "type", 4,
              newSVpv( ( contype == PM_FILECONFLICT_TARGET ?
                         "target" :
                         contype == PM_FILECONFLICT_FILESYSTEM ?
                         "filesystem" : "ERROR" ), 0 ), 0);
    hv_store( conflict_hash, "target", 6,
              newSVpv( alpm_fileconflict_get_target( fileconflict ), 0 ),
              0 );
    hv_store( conflict_hash, "file", 4,
              newSVpv( alpm_fileconflict_get_file( fileconflict ), 0 ),
              0 );
    hv_store( conflict_hash, "ctarget", 7,
              newSVpv( alpm_fileconflict_get_ctarget( fileconflict ), 0 ),
              0 );

    return newRV_noinc( (SV *)conflict_hash );
}

static void free_stringlist_errors ( void * string )
{
    free(string);
}

/* Copy/pasted from ALPM's conflict.c */
static void free_fileconflict_errors ( void * ptr )
{
    pmfileconflict_t * conflict = ptr;
    const char       * ctarget;

    ctarget = alpm_fileconflict_get_ctarget( conflict );
	if ( strlen( ctarget ) > 0 ) { free( (void *) ctarget ); }
	free( (void *) alpm_fileconflict_get_file( conflict ));
	free( (void *) alpm_fileconflict_get_target( conflict ));
	free( (void *) conflict);
}

/* Copy/pasted from ALPM's deps.c */
static void free_depmissing_errors ( void * ptr )
{
    pmdepmissing_t * miss = ptr;
    pmdepend_t * dep;

    dep = alpm_miss_get_dep( miss );
    if ( dep != NULL ) {
        free( (void *) alpm_dep_get_name( dep ));
        free( (void *) alpm_dep_get_version( dep ));
        free( dep );
    }

	free( (void *) alpm_miss_get_target( miss ));
	free( (void *) alpm_miss_get_causingpkg( miss ));
	free( miss );
}

/* Copy/pasted from ALPM's conflict.c */
static void free_conflict_errors ( void * ptr )
{
    pmconflict_t * conflict = ptr;
	free( (void *)alpm_conflict_get_package1( conflict ));
	free( (void *)alpm_conflict_get_package2( conflict ));
    free( (void *)alpm_conflict_get_reason( conflict ));
	free( conflict);
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
    for ( iter = errors ; iter ; iter = alpm_list_next( iter )) {       \
        ref = convert_ ## TYPE ((pm ## TYPE ## _t *) iter->data );      \
        av_push( error_list, ref );                                     \
    }                                                                   \
    alpm_list_free_inner( errors,                                       \
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
