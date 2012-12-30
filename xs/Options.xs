MODULE = ALPM	PACKAGE = ALPM	PREFIX = alpm_option_

## CALLBACKS

void
alpm_option_set_logcb(self, cb)
	ALPM_Handle self
	SV * cb
 CODE:
	DEFSETCB(log, self, cb)

void
alpm_option_set_dlcb(self, cb)
	ALPM_Handle self
	SV * cb
 CODE:
	DEFSETCB(dl, self, cb)

void
alpm_option_set_fetchcb(self, cb)
	ALPM_Handle self
	SV * cb
 CODE:
	DEFSETCB(fetch, self, cb)

void
alpm_option_set_totaldlcb(self, cb)
	ALPM_Handle self
	SV * cb
 CODE:
	DEFSETCB(totaldl, self, cb)

#SV *
#alpm_option_get_dlcb(self)
#	ALPM_Handle self
# CODE:
#	DEF_GET_CALLBACK(dl)
# OUTPUT:
#	RETVAL
#
#void
#alpm_option_set_dlcb(self, callback)
#	ALPM_Handle self
#	SV * callback
# CODE:
#	DEF_SET_CALLBACK(dl)
#
#SV *
#alpm_option_get_totaldlcb(self)
#	ALPM_Handle self
# CODE:
#	DEF_GET_CALLBACK(totaldl)
# OUTPUT:
#	RETVAL
#
#void
#alpm_option_set_totaldlcb(self, callback)
#	ALPM_Handle self
#	SV * callback
# CODE:
#	DEF_SET_CALLBACK(totaldl)
#
#SV *
#alpm_option_get_fetchcb(self)
#	ALPM_Handle self
# CODE:
#	DEF_GET_CALLBACK(fetch)
# OUTPUT:
#	RETVAL
#

## REGULAR OPTIONS

StringOption
option_string_get(self)
	ALPM_Handle self
 INTERFACE:
	alpm_option_get_logfile
	alpm_option_get_lockfile
	alpm_option_get_arch
	alpm_option_get_gpgdir

SetOption
option_string_set(self, string)
	ALPM_Handle self
	const char * string
 INTERFACE:
	alpm_option_set_logfile
	alpm_option_set_arch
	alpm_option_set_gpgdir

# String List Options

void
alpm_option_get_cachedirs(self)
	ALPM_Handle self
 PREINIT:
	alpm_list_t *lst;
 PPCODE:
	lst = alpm_option_get_cachedirs(self);
	LIST2STACK(lst, c2p_str);

void
alpm_option_get_noupgrades(self)
	ALPM_Handle self
 PREINIT:
	alpm_list_t *lst;
 PPCODE:
	lst = alpm_option_get_noupgrades(self);
	LIST2STACK(lst, c2p_str);

void
alpm_option_get_noextracts(self)
	ALPM_Handle self
 PREINIT:
	alpm_list_t *lst;
 PPCODE:
	lst = alpm_option_get_noextracts(self);
	LIST2STACK(lst, c2p_str);

void
alpm_option_get_ignorepkgs(self)
	ALPM_Handle self
 PREINIT:
	alpm_list_t *lst;
 PPCODE:
	lst = alpm_option_get_ignorepkgs(self);
	LIST2STACK(lst, c2p_str);

void
alpm_option_get_ignoregroups(self)
	ALPM_Handle self
 PREINIT:
	alpm_list_t *lst;
 PPCODE:
	lst = alpm_option_get_ignoregroups(self);
	LIST2STACK(lst, c2p_str);

SetOption
option_stringlist_add(self, add_string)
	ALPM_Handle self
	const char *add_string
 INTERFACE:
	alpm_option_add_noupgrade
	alpm_option_add_noextract
	alpm_option_add_ignorepkg
	alpm_option_add_ignoregroup
	alpm_option_add_cachedir

SetOption
alpm_option_set_cachedirs(self, ...)
	ALPM_Handle self
 PREINIT:
	alpm_list_t *lst;
	int i;
 CODE:
	i = 1;
	STACK2LIST(i, lst, p2c_str);
	RETVAL = alpm_option_set_cachedirs(self, lst);
	ZAPLIST(lst, free);
 OUTPUT:
	RETVAL

SetOption
alpm_option_set_noupgrades(self, ...)
	ALPM_Handle self
 PREINIT:
	alpm_list_t *lst;
	int i;
 CODE:
	i = 1;
	STACK2LIST(i, lst, p2c_str);
	RETVAL = alpm_option_set_noupgrades(self, lst);
	ZAPLIST(lst, free);
 OUTPUT:
	RETVAL

SetOption
alpm_option_set_noextracts(self, ...)
	ALPM_Handle self
 PREINIT:
	alpm_list_t *lst;
	int i;
 CODE:
	i = 1;
	STACK2LIST(i, lst, p2c_str);
	RETVAL = alpm_option_set_noextracts(self, lst);
	ZAPLIST(lst, free);
 OUTPUT:
	RETVAL

SetOption
alpm_option_set_ignorepkgs(self, ...)
	ALPM_Handle self
 PREINIT:
	alpm_list_t *lst;
	int i;
 CODE:
	i = 1;
	STACK2LIST(i, lst, p2c_str);
	RETVAL = alpm_option_set_ignorepkgs(self, lst);
	ZAPLIST(lst, free);
 OUTPUT:
	RETVAL

SetOption
alpm_option_set_ignoregroups(self, ...)
	ALPM_Handle self
 PREINIT:
	alpm_list_t *lst;
	int i;
 CODE:
	i = 1;
	STACK2LIST(i, lst, p2c_str);
	RETVAL = alpm_option_set_ignoregroups(self, lst);
	ZAPLIST(lst, free);
 OUTPUT:
	RETVAL

# Use IntOption to return the number of items removed (0 or 1).

IntOption
option_stringlist_remove(self, badstring)
	ALPM_Handle self
	const char * badstring
INTERFACE:
	alpm_option_remove_cachedir
	alpm_option_remove_noupgrade
	alpm_option_remove_noextract
	alpm_option_remove_ignorepkg
	alpm_option_remove_ignoregroup

IntOption
option_int_get(self)
	ALPM_Handle self
INTERFACE:
	alpm_option_get_usesyslog
	alpm_option_get_usedelta
	alpm_option_get_checkspace

SetOption
option_int_set(self, new_int)
	ALPM_Handle self
	int new_int
INTERFACE:
	alpm_option_set_usesyslog
	alpm_option_set_usedelta
	alpm_option_set_checkspace

# Why have get_localdb when there is no set_localdb? s/get_//;

ALPM_LocalDB
alpm_option_localdb(self)
	ALPM_Handle self
 CODE:
	RETVAL = alpm_option_get_localdb(self);
 OUTPUT:
	RETVAL

# Ditto.

void
alpm_option_syncdbs(self)
	ALPM_Handle self
 PREINIT:
	alpm_list_t *lst;
 PPCODE:
	lst = alpm_option_get_syncdbs(self);
	if(lst == NULL && alpm_errno(self)) alpm_croak(self);
	LIST2STACK(lst, c2p_syncdb);

MODULE = ALPM	PACKAGE = ALPM	PREFIX = alpm_option_

ALPM_SigLevel
get_defsiglvl(self)
	ALPM_Handle self
 CODE:
	RETVAL = alpm_option_get_default_siglevel(self);
 OUTPUT:
	RETVAL

SetOption
set_defsiglvl(self, siglvl)
	ALPM_Handle self
	ALPM_SigLevel siglvl
 CODE:
	RETVAL = alpm_option_set_default_siglevel(self, siglvl);
 OUTPUT:
	RETVAL

# EOF
