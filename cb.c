#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <alpm.h>
#include "cb.h"

SV * logcb_ref, * dlcb_ref, * totaldlcb_ref, * fetchcb_ref;

void c2p_logcb(alpm_loglevel_t lvl, const char * fmt, va_list args)
{
	SV * svlvl, * svmsg;
	const char *str;
	char buf[256];
	dSP;

	if(!logcb_ref) return;

	/* convert log level bitflag to a string */
	switch(lvl){
	case ALPM_LOG_ERROR: str = "error"; break;
	case ALPM_LOG_WARNING: str = "warning"; break;
	case ALPM_LOG_DEBUG: str = "debug"; break;
	case ALPM_LOG_FUNCTION: str = "function"; break;
	default: str = "unknown"; break;
	}

	ENTER;
	SAVETMPS;

	/* We can't use sv_vsetpvfn because it doesn't like j's: %jd or %ji, etc... */
	svlvl = sv_2mortal(newSVpv(str, 0));
	vsnprintf(buf, 255, fmt, args);
	svmsg = sv_2mortal(newSVpv(buf, 0));
	
	PUSHMARK(SP);
	XPUSHs(svlvl);
	XPUSHs(svmsg);
	PUTBACK;

	call_sv(logcb_ref, G_DISCARD);

	FREETMPS;
	LEAVE;
	return;
}
