#include <stdlib.h>
#include <string.h>
#include <alpm.h>

/* Perl API headers. */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <alpm.h>

#include "exception.h"

struct {
    alpm_errno_t err;
    char *pclass;
} emap[] = {
    { ALPM_ERR_BADPERMS, "ALPM::Exception::BadPerms" },
    { ALPM_ERR_CONFLICTING_DEPS, "ALPM::Exception::ConflictingDependencies" },
    { ALPM_ERR_DB_CREATE, "ALPM::Exception::DatabaseCreate" },
    { ALPM_ERR_DB_INVALID, "ALPM::Exception::DatabaseInvalid" },
    { ALPM_ERR_DB_INVALID_SIG, "ALPM::Exception::DatabaseInvalidSignature" },
    { ALPM_ERR_DB_NOT_FOUND, "ALPM::Exception::DatabaseNotFound" },
    { ALPM_ERR_DB_NOT_NULL, "ALPM::Exception::DatabaseNotNull" },
    { ALPM_ERR_DB_NULL, "ALPM::Exception::DatabaseNull" },
    { ALPM_ERR_DB_OPEN, "ALPM::Exception::DatabaseOpen" },
    { ALPM_ERR_DB_REMOVE, "ALPM::Exception::DatabaseRemove" },
    { ALPM_ERR_DB_VERSION, "ALPM::Exception::DatabaseVersion" },
    { ALPM_ERR_DB_WRITE, "ALPM::Exception::DatabaseWrite" },
    { ALPM_ERR_DLT_INVALID, "ALPM::Exception::DeltaInvalid" },
    { ALPM_ERR_DLT_PATCHFAILED, "ALPM::Exception::DeltaPatchFailed" },
    { ALPM_ERR_DISK_SPACE, "ALPM::Exception::DiskSpace" },
    { ALPM_ERR_EXTERNAL_DOWNLOAD, "ALPM::Exception::ExternalDownload" },
    { ALPM_ERR_FILE_CONFLICTS, "ALPM::Exception::FileConflicts" },
    { ALPM_ERR_GPGME, "ALPM::Exception::GPGME" },
    { ALPM_ERR_HANDLE_LOCK, "ALPM::Exception::HandleLock" },
    { ALPM_ERR_HANDLE_NOT_NULL, "ALPM::Exception::HandleNotNull" },
    { ALPM_ERR_HANDLE_NULL, "ALPM::Exception::HandleNull" },
    { ALPM_ERR_INVALID_REGEX, "ALPM::Exception::InvalidRegex" },
    { ALPM_ERR_LIBARCHIVE, "ALPM::Exception::LibArchive" },
    { ALPM_ERR_LIBCURL, "ALPM::Exception::LibCurl" },
    { ALPM_ERR_MEMORY, "ALPM::Exception::Memory" },
    { ALPM_ERR_NOT_A_DIR, "ALPM::Exception::NotADirectory" },
    { ALPM_ERR_NOT_A_FILE, "ALPM::Exception::NotAFile" },
    { ALPM_ERR_PKG_CANT_REMOVE, "ALPM::Exception::PackageCantRemove" },
    { ALPM_ERR_PKG_IGNORED, "ALPM::Exception::PackageIgnored" },
    { ALPM_ERR_PKG_INVALID, "ALPM::Exception::PackageInvalid" },
    { ALPM_ERR_PKG_INVALID_ARCH, "ALPM::Exception::PackageInvalidArchitecture" },
    { ALPM_ERR_PKG_INVALID_CHECKSUM, "ALPM::Exception::PackageInvalidChecksum" },
    { ALPM_ERR_PKG_INVALID_NAME, "ALPM::Exception::PackageInvalidName" },
    { ALPM_ERR_PKG_INVALID_SIG, "ALPM::Exception::PackageInvalidSignature" },
    { ALPM_ERR_PKG_MISSING_SIG, "ALPM::Exception::PackageMissingSignature" },
    { ALPM_ERR_PKG_NOT_FOUND, "ALPM::Exception::PackageNotFound" },
    { ALPM_ERR_PKG_OPEN, "ALPM::Exception::PackageOpen" },
    { ALPM_ERR_PKG_REPO_NOT_FOUND, "ALPM::Exception::PackageRepoNotFound" },
    { ALPM_ERR_RETRIEVE, "ALPM::Exception::Retrieve" },
    { ALPM_ERR_SERVER_BAD_URL, "ALPM::Exception::ServerBadURL" },
    { ALPM_ERR_SERVER_NONE, "ALPM::Exception::ServerNone" },
    { ALPM_ERR_SIG_INVALID, "ALPM::Exception::SignatureInvalid" },
    { ALPM_ERR_SIG_MISSING, "ALPM::Exception::SignatureMissing" },
    { ALPM_ERR_SYSTEM, "ALPM::Exception::System" },
    { ALPM_ERR_TRANS_ABORT, "ALPM::Exception::TransactionAborted" },
    { ALPM_ERR_TRANS_DUP_TARGET, "ALPM::Exception::TransactionDuplicateTarget" },
    { ALPM_ERR_TRANS_NOT_INITIALIZED, "ALPM::Exception::TransactionNotInitialized" },
    { ALPM_ERR_TRANS_NOT_LOCKED, "ALPM::Exception::TransactionNotLocked" },
    { ALPM_ERR_TRANS_NOT_NULL, "ALPM::Exception::TransactionNotNull" },
    { ALPM_ERR_TRANS_NOT_PREPARED, "ALPM::Exception::TransactionNotPrepared" },
    { ALPM_ERR_TRANS_NULL, "ALPM::Exception::TransactionNull" },
    { ALPM_ERR_TRANS_TYPE, "ALPM::Exception::TransactionType" },
    { ALPM_ERR_UNSATISFIED_DEPS, "ALPM::Exception::UnsatisfiedDependencies" },
    { ALPM_ERR_WRONG_ARGS, "ALPM::Exception::WrongArgs" },
};

const char *
lookup_eclass(alpm_errno_t err)
{
    int i;
    for(i = 0; i < sizeof(emap) / sizeof(*emap); i++) {
        if(emap[i].err == err) {
            return emap[i].pclass;
        }
    }
    return "ALPM::Exception";
}

void
alpm_throw(alpm_errno_t err)
{
    SV *e = newRV_noinc((SV*) newHV());
    croak_sv(sv_bless(e, gv_stashpv(lookup_eclass(err), GV_ADD)));
}

void
register_eclasses(void)
{
    int i;
    char vname[50];
    for(i = 0; i < sizeof(emap) / sizeof(*emap); i++) {
        sprintf(vname, "%s::ISA", emap[i].pclass);
        av_push(get_av(vname, GV_ADD), newSVpv("ALPM::Exception", 0));
        sprintf(vname, "%s::errno", emap[i].pclass);
        /* no idea why we can't just sv_setiv here */
        sv_setsv(get_sv(vname, GV_ADD), sv_2mortal(newSViv(emap[i].err)));
    }
}
