#ifndef ALPM_EXCEPTION_H
#define ALPM_EXCEPTION_H

const char * lookup_eclass(alpm_errno_t err);
void alpm_throw(alpm_errno_t err);
void register_eclasses(void);

#endif
