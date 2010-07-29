# PRIVATE ###################################################################

MODULE=ALPM    PACKAGE=ALPM    PREFIX=alpm

negative_is_error
alpm_trans_init(flags, event_sub, conv_sub, progress_sub)
    int flags
    SV  *event_sub
    SV  *conv_sub
    SV  *progress_sub
  PREINIT:
    alpm_trans_cb_event     event_func = NULL;
    alpm_trans_cb_conv      conv_func  = NULL;
    alpm_trans_cb_progress  progress_func  = NULL;
  CODE:
    /* I'm guessing that event callbacks provided for previous transactions
       shouldn't come into effect for later transactions unless explicitly
       provided. */

    UPDATE_TRANS_CALLBACK( event )
    UPDATE_TRANS_CALLBACK( conv )
    UPDATE_TRANS_CALLBACK( progress )

    RETVAL = alpm_trans_init( flags, event_func, conv_func, progress_func );
  OUTPUT:
    RETVAL

MODULE=ALPM    PACKAGE=ALPM::Transaction    PREFIX=alpm

int
alpm_trans_get_flags()

PackageListNoFree
alpm_trans_get_add()

PackageListNoFree
alpm_trans_get_remove()

# PUBLIC METHODS ############################################################

MODULE=ALPM    PACKAGE=ALPM::Transaction

negative_is_error
DESTROY(self)
    SV * self
  CODE:
#   fprintf( stderr, "DEBUG Releasing the transaction\n" );
    RETVAL = alpm_trans_release();
  OUTPUT:
    RETVAL

negative_is_error
sysupgrade ( self, ... )
    SV  * self
  PREINIT:
    int enable_downgrade;
  CODE:
    enable_downgrade = ( items > 1 ? 1 : 0 );
    RETVAL = alpm_sync_sysupgrade( enable_downgrade );
  OUTPUT:
    RETVAL

negative_is_error
sync ( self, target )
    SV   * self
    char * target
  CODE:
    RETVAL = alpm_sync_target( target );
  OUTPUT:
    RETVAL

negative_is_error
pkgfile ( self, target )
    SV   * self
    char * target
  CODE:
    RETVAL = alpm_add_target( target );
  OUTPUT:
    RETVAL

negative_is_error
remove ( self, target )
    SV   * self
    char * target
  CODE:
    RETVAL = alpm_remove_target( target );
  OUTPUT:
    RETVAL

negative_is_error
sync_from_db ( self, db, target )
    SV   * self
    char * target
    char * db
  CODE:
    RETVAL = alpm_sync_dbtarget( db, target );
  OUTPUT:
    RETVAL

MODULE=ALPM    PACKAGE=ALPM::Transaction    PREFIX=alpm_trans_

negative_is_error
alpm_trans_prepare ( self )
    SV * self
  PREINIT:
    alpm_list_t *errors;
    HV *trans;
    SV *trans_error, **prepared;
  CODE:
    /* make sure we are called as a method */
    if ( !( SvROK(self) /* && SvTYPE(self) == SVt_PVMG */
            && sv_isa( self, "ALPM::Transaction" ) ) ) {
        croak( "prepare must be called as a method" );
    }

    trans = (HV *) SvRV(self);

    prepared = hv_fetch( trans, "prepared", 8, 0 );
    if ( SvOK(*prepared) && SvTRUE(*prepared) ) {
        RETVAL = 0;
    }
    else {
        /* fprintf( stderr, "DEBUG: ALPM::Transaction::prepare\n" ); */

        errors = NULL;
        RETVAL = alpm_trans_prepare( &errors );

        if ( RETVAL == -1 ) {
            trans_error = convert_trans_errors( errors );
            if ( trans_error ) {
                hv_store( trans, "error", 5, trans_error, 0 );

                croak( "ALPM Transaction Error: %s",
                       alpm_strerror( pm_errno ));
                fprintf( stderr, "ERROR: prepare shouldn't get here?\n" );
                RETVAL = 0;
            }

            /* If we don't catch all the kinds of errors we'll get memory
               leaks inside the list!  Yay! */
            if ( errors ) {
                fprintf( stderr,
                         "ERROR: unknown prepare error caused memory leak "
                         "at %s line %d\n", __FILE__, __LINE__ );
            }
        }
        else hv_store( trans, "prepared", 8, newSViv(1), 0 );
    }
  OUTPUT:
    RETVAL

negative_is_error
alpm_trans_commit(self)
    SV * self
  PREINIT:
    alpm_list_t *errors;
    HV *trans;
    SV *trans_error, **prepared;
  CODE:
    /* make sure we are called as a method */
    if ( !( SvROK(self) /* && SvTYPE(self) == SVt_PVMG */
            && sv_isa( self, "ALPM::Transaction" ) ) ) {
        croak( "commit must be called as a method" );
    }

    trans = (HV *) SvRV(self);
    prepared = hv_fetch( trans, "prepared", 8, 0 );

    /*fprintf( stderr, "DEBUG: prepared = %d\n", SvIV(*prepared) );*/

    /* prepare before we commit */
    if ( ! SvOK(*prepared) || ! SvTRUE(*prepared) ) {
        PUSHMARK(SP);
        XPUSHs(self);
        PUTBACK;
        call_method( "prepare", G_DISCARD );
    }
    
    errors = NULL;
    RETVAL = alpm_trans_commit( &errors );

    if ( RETVAL == -1 ) {
        trans_error = convert_trans_errors( errors );
        if ( trans_error ) {
            hv_store( trans, "error", 5, trans_error, 0 );
            croak( "ALPM Transaction Error: %s", alpm_strerror( pm_errno ));
            fprintf( stderr, "ERROR: commit shouldn't get here?\n" );
            RETVAL = 0;
        }

        if ( errors ) {
            fprintf( stderr,
                     "ERROR: unknown commit error caused memory leak "
                     "at %s line %d\n",
                     __FILE__, __LINE__ );
        }
    }
  OUTPUT:
    RETVAL

negative_is_error
alpm_trans_interrupt(self)
    SV * self
  CODE:
    RETVAL = alpm_trans_interrupt();
  OUTPUT:
    RETVAL
