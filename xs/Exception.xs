#include "exception.h"

MODULE = ALPM      PACKAGE = ALPM::Exception

BOOT:
    register_eclasses();

const char *
alpm_strerror(err)
        int err

# /* define errno here to avoid symbolic ref in ALPM/Exception.pm */
SV *
errno(self)
        SV * self
    CODE:
        HV *stash = sv_isobject(self) ? SvSTASH(SvRV(self)) : gv_stashsv(self, 0);
        SV **val = hv_fetchs(stash, "errno", 0);
        RETVAL = val == NULL ? &PL_sv_undef : newSVsv(GvSV(*val));
    OUTPUT:
        RETVAL
