#define PERL_constant_NOTFOUND	1
#define PERL_constant_NOTDEF	2
#define PERL_constant_ISIV	3
#define PERL_constant_ISNO	4
#define PERL_constant_ISNV	5
#define PERL_constant_ISPV	6
#define PERL_constant_ISPVN	7
#define PERL_constant_ISSV	8
#define PERL_constant_ISUNDEF	9
#define PERL_constant_ISUV	10
#define PERL_constant_ISYES	11

#ifndef NVTYPE
typedef double NV; /* 5.6 and later define NVTYPE, and typedef NV to it.  */
#endif
#ifndef aTHX_
#define aTHX_ /* 5.6 or later define this for threading support.  */
#endif
#ifndef pTHX_
#define pTHX_ /* 5.6 or later define this for threading support.  */
#endif

static int
constant_13 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     PM_DEP_MOD_EQ PM_DEP_MOD_GE PM_DEP_MOD_GT PM_DEP_MOD_LE PM_DEP_MOD_LT
     PM_ERR_MEMORY PM_ERR_SYSTEM */
  /* Offset 12 gives the best switch position.  */
  switch (name[12]) {
  case 'E':
    if (memEQ(name, "PM_DEP_MOD_G", 12)) {
    /*                           E      */
      *iv_return = PM_DEP_MOD_GE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "PM_DEP_MOD_L", 12)) {
    /*                           E      */
      *iv_return = PM_DEP_MOD_LE;
      return PERL_constant_ISIV;
    }
    break;
  case 'M':
    if (memEQ(name, "PM_ERR_SYSTE", 12)) {
    /*                           M      */
      *iv_return = PM_ERR_SYSTEM;
      return PERL_constant_ISIV;
    }
    break;
  case 'Q':
    if (memEQ(name, "PM_DEP_MOD_E", 12)) {
    /*                           Q      */
      *iv_return = PM_DEP_MOD_EQ;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "PM_DEP_MOD_G", 12)) {
    /*                           T      */
      *iv_return = PM_DEP_MOD_GT;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "PM_DEP_MOD_L", 12)) {
    /*                           T      */
      *iv_return = PM_DEP_MOD_LT;
      return PERL_constant_ISIV;
    }
    break;
  case 'Y':
    if (memEQ(name, "PM_ERR_MEMOR", 12)) {
    /*                           Y      */
      *iv_return = PM_ERR_MEMORY;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_14 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     PM_DEP_MOD_ANY PM_ERR_DB_NULL PM_ERR_DB_OPEN PM_ERR_DB_SYNC PM_LOG_WARNING
     */
  /* Offset 13 gives the best switch position.  */
  switch (name[13]) {
  case 'C':
    if (memEQ(name, "PM_ERR_DB_SYN", 13)) {
    /*                            C      */
      *iv_return = PM_ERR_DB_SYNC;
      return PERL_constant_ISIV;
    }
    break;
  case 'G':
    if (memEQ(name, "PM_LOG_WARNIN", 13)) {
    /*                            G      */
      *iv_return = PM_LOG_WARNING;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "PM_ERR_DB_NUL", 13)) {
    /*                            L      */
      *iv_return = PM_ERR_DB_NULL;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "PM_ERR_DB_OPE", 13)) {
    /*                            N      */
      *iv_return = PM_ERR_DB_OPEN;
      return PERL_constant_ISIV;
    }
    break;
  case 'Y':
    if (memEQ(name, "PM_DEP_MOD_AN", 13)) {
    /*                            Y      */
      *iv_return = PM_DEP_MOD_ANY;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_15 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     PM_ERR_BADPERMS PM_ERR_DB_WRITE PM_ERR_PKG_HOLD PM_ERR_PKG_LOAD
     PM_ERR_PKG_OPEN PM_ERR_RETRIEVE PM_LOG_FUNCTION */
  /* Offset 11 gives the best switch position.  */
  switch (name[11]) {
  case 'E':
    if (memEQ(name, "PM_ERR_BADPERMS", 15)) {
    /*                          ^          */
      *iv_return = PM_ERR_BADPERMS;
      return PERL_constant_ISIV;
    }
    break;
  case 'H':
    if (memEQ(name, "PM_ERR_PKG_HOLD", 15)) {
    /*                          ^          */
      *iv_return = PM_ERR_PKG_HOLD;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "PM_ERR_RETRIEVE", 15)) {
    /*                          ^          */
      *iv_return = PM_ERR_RETRIEVE;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "PM_ERR_PKG_LOAD", 15)) {
    /*                          ^          */
      *iv_return = PM_ERR_PKG_LOAD;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "PM_ERR_PKG_OPEN", 15)) {
    /*                          ^          */
      *iv_return = PM_ERR_PKG_OPEN;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "PM_ERR_DB_WRITE", 15)) {
    /*                          ^          */
      *iv_return = PM_ERR_DB_WRITE;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "PM_LOG_FUNCTION", 15)) {
    /*                          ^          */
      *iv_return = PM_LOG_FUNCTION;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_16 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     PM_ERR_DB_CREATE PM_ERR_DB_REMOVE PM_ERR_NOT_A_DIR */
  /* Offset 14 gives the best switch position.  */
  switch (name[14]) {
  case 'I':
    if (memEQ(name, "PM_ERR_NOT_A_DIR", 16)) {
    /*                             ^        */
      *iv_return = PM_ERR_NOT_A_DIR;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "PM_ERR_DB_CREATE", 16)) {
    /*                             ^        */
      *iv_return = PM_ERR_DB_CREATE;
      return PERL_constant_ISIV;
    }
    break;
  case 'V':
    if (memEQ(name, "PM_ERR_DB_REMOVE", 16)) {
    /*                             ^        */
      *iv_return = PM_ERR_DB_REMOVE;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_17 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     PM_ERR_LIBARCHIVE PM_ERR_NOT_A_FILE PM_ERR_TRANS_NULL PM_ERR_TRANS_TYPE
     PM_ERR_USER_ABORT PM_ERR_WRONG_ARGS */
  /* Offset 13 gives the best switch position.  */
  switch (name[13]) {
  case 'A':
    if (memEQ(name, "PM_ERR_WRONG_ARGS", 17)) {
    /*                            ^          */
      *iv_return = PM_ERR_WRONG_ARGS;
      return PERL_constant_ISIV;
    }
    break;
  case 'B':
    if (memEQ(name, "PM_ERR_USER_ABORT", 17)) {
    /*                            ^          */
      *iv_return = PM_ERR_USER_ABORT;
      return PERL_constant_ISIV;
    }
    break;
  case 'F':
    if (memEQ(name, "PM_ERR_NOT_A_FILE", 17)) {
    /*                            ^          */
      *iv_return = PM_ERR_NOT_A_FILE;
      return PERL_constant_ISIV;
    }
    break;
  case 'H':
    if (memEQ(name, "PM_ERR_LIBARCHIVE", 17)) {
    /*                            ^          */
      *iv_return = PM_ERR_LIBARCHIVE;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "PM_ERR_TRANS_NULL", 17)) {
    /*                            ^          */
      *iv_return = PM_ERR_TRANS_NULL;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "PM_ERR_TRANS_TYPE", 17)) {
    /*                            ^          */
      *iv_return = PM_ERR_TRANS_TYPE;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_18 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     PM_ERR_DB_NOT_NULL PM_ERR_DLT_INVALID PM_ERR_HANDLE_LOCK
     PM_ERR_HANDLE_NULL PM_ERR_LIBDOWNLOAD PM_ERR_PKG_INVALID
     PM_ERR_TRANS_ABORT PM_TRANS_TYPE_SYNC */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case 'A':
    if (memEQ(name, "PM_ERR_HANDLE_LOCK", 18)) {
    /*                       ^                */
      *iv_return = PM_ERR_HANDLE_LOCK;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "PM_ERR_HANDLE_NULL", 18)) {
    /*                       ^                */
      *iv_return = PM_ERR_HANDLE_NULL;
      return PERL_constant_ISIV;
    }
    break;
  case 'B':
    if (memEQ(name, "PM_ERR_DB_NOT_NULL", 18)) {
    /*                       ^                */
      *iv_return = PM_ERR_DB_NOT_NULL;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "PM_ERR_LIBDOWNLOAD", 18)) {
    /*                       ^                */
      *iv_return = PM_ERR_LIBDOWNLOAD;
      return PERL_constant_ISIV;
    }
    break;
  case 'K':
    if (memEQ(name, "PM_ERR_PKG_INVALID", 18)) {
    /*                       ^                */
      *iv_return = PM_ERR_PKG_INVALID;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "PM_ERR_DLT_INVALID", 18)) {
    /*                       ^                */
      *iv_return = PM_ERR_DLT_INVALID;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "PM_ERR_TRANS_ABORT", 18)) {
    /*                       ^                */
      *iv_return = PM_ERR_TRANS_ABORT;
      return PERL_constant_ISIV;
    }
    break;
  case '_':
    if (memEQ(name, "PM_TRANS_TYPE_SYNC", 18)) {
    /*                       ^                */
      *iv_return = PM_TRANS_TYPE_SYNC;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_20 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     PM_ERR_GRP_NOT_FOUND PM_ERR_INVALID_REGEX PM_ERR_PKG_NOT_FOUND
     PM_PKG_REASON_DEPEND PM_TRANS_FLAG_DBONLY PM_TRANS_FLAG_NEEDED
     PM_TRANS_FLAG_NODEPS PM_TRANS_FLAG_NOSAVE PM_TRANS_TYPE_REMOVE */
  /* Offset 17 gives the best switch position.  */
  switch (name[17]) {
  case 'A':
    if (memEQ(name, "PM_TRANS_FLAG_NOSAVE", 20)) {
    /*                                ^         */
      *iv_return = PM_TRANS_FLAG_NOSAVE;
      return PERL_constant_ISIV;
    }
    break;
  case 'D':
    if (memEQ(name, "PM_TRANS_FLAG_NEEDED", 20)) {
    /*                                ^         */
      *iv_return = PM_TRANS_FLAG_NEEDED;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "PM_PKG_REASON_DEPEND", 20)) {
    /*                                ^         */
      *iv_return = PM_PKG_REASON_DEPEND;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "PM_TRANS_FLAG_NODEPS", 20)) {
    /*                                ^         */
      *iv_return = PM_TRANS_FLAG_NODEPS;
      return PERL_constant_ISIV;
    }
    break;
  case 'G':
    if (memEQ(name, "PM_ERR_INVALID_REGEX", 20)) {
    /*                                ^         */
      *iv_return = PM_ERR_INVALID_REGEX;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "PM_TRANS_FLAG_DBONLY", 20)) {
    /*                                ^         */
      *iv_return = PM_TRANS_FLAG_DBONLY;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "PM_TRANS_TYPE_REMOVE", 20)) {
    /*                                ^         */
      *iv_return = PM_TRANS_TYPE_REMOVE;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "PM_ERR_GRP_NOT_FOUND", 20)) {
    /*                                ^         */
      *iv_return = PM_ERR_GRP_NOT_FOUND;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "PM_ERR_PKG_NOT_FOUND", 20)) {
    /*                                ^         */
      *iv_return = PM_ERR_PKG_NOT_FOUND;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_21 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     PM_ERR_FILE_CONFLICTS PM_ERR_INTERNAL_ERROR PM_ERR_PKG_CANT_FRESH
     PM_ERR_SERVER_BAD_URL PM_ERR_TRANS_NOT_NULL PM_TRANS_EVT_ADD_DONE
     PM_TRANS_EVT_PRINTURI PM_TRANS_FLAG_ALLDEPS PM_TRANS_FLAG_CASCADE
     PM_TRANS_FLAG_RECURSE PM_TRANS_TYPE_UPGRADE */
  /* Offset 14 gives the best switch position.  */
  switch (name[14]) {
  case 'A':
    if (memEQ(name, "PM_TRANS_FLAG_ALLDEPS", 21)) {
    /*                             ^             */
      *iv_return = PM_TRANS_FLAG_ALLDEPS;
      return PERL_constant_ISIV;
    }
    break;
  case 'B':
    if (memEQ(name, "PM_ERR_SERVER_BAD_URL", 21)) {
    /*                             ^             */
      *iv_return = PM_ERR_SERVER_BAD_URL;
      return PERL_constant_ISIV;
    }
    break;
  case 'C':
    if (memEQ(name, "PM_TRANS_FLAG_CASCADE", 21)) {
    /*                             ^             */
      *iv_return = PM_TRANS_FLAG_CASCADE;
      return PERL_constant_ISIV;
    }
    break;
  case 'D':
    if (memEQ(name, "PM_TRANS_EVT_ADD_DONE", 21)) {
    /*                             ^             */
      *iv_return = PM_TRANS_EVT_ADD_DONE;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "PM_ERR_INTERNAL_ERROR", 21)) {
    /*                             ^             */
      *iv_return = PM_ERR_INTERNAL_ERROR;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "PM_ERR_FILE_CONFLICTS", 21)) {
    /*                             ^             */
      *iv_return = PM_ERR_FILE_CONFLICTS;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "PM_ERR_TRANS_NOT_NULL", 21)) {
    /*                             ^             */
      *iv_return = PM_ERR_TRANS_NOT_NULL;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "PM_TRANS_EVT_PRINTURI", 21)) {
    /*                             ^             */
      *iv_return = PM_TRANS_EVT_PRINTURI;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "PM_TRANS_FLAG_RECURSE", 21)) {
    /*                             ^             */
      *iv_return = PM_TRANS_FLAG_RECURSE;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "PM_ERR_PKG_CANT_FRESH", 21)) {
    /*                             ^             */
      *iv_return = PM_ERR_PKG_CANT_FRESH;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "PM_TRANS_TYPE_UPGRADE", 21)) {
    /*                             ^             */
      *iv_return = PM_TRANS_TYPE_UPGRADE;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_22 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     PM_ERR_DLT_PATCHFAILED PM_ERR_HANDLE_NOT_NULL PM_ERR_PKG_CANT_REMOVE
     PM_ERR_TRANS_COMMITING PM_FILECONFLICT_TARGET PM_PKG_REASON_EXPLICIT
     PM_TRANS_EVT_ADD_START PM_TRANS_FLAG_UNNEEDED */
  /* Offset 19 gives the best switch position.  */
  switch (name[19]) {
  case 'A':
    if (memEQ(name, "PM_TRANS_EVT_ADD_START", 22)) {
    /*                                  ^         */
      *iv_return = PM_TRANS_EVT_ADD_START;
      return PERL_constant_ISIV;
    }
    break;
  case 'C':
    if (memEQ(name, "PM_PKG_REASON_EXPLICIT", 22)) {
    /*                                  ^         */
      *iv_return = PM_PKG_REASON_EXPLICIT;
      return PERL_constant_ISIV;
    }
    break;
  case 'D':
    if (memEQ(name, "PM_TRANS_FLAG_UNNEEDED", 22)) {
    /*                                  ^         */
      *iv_return = PM_TRANS_FLAG_UNNEEDED;
      return PERL_constant_ISIV;
    }
    break;
  case 'G':
    if (memEQ(name, "PM_FILECONFLICT_TARGET", 22)) {
    /*                                  ^         */
      *iv_return = PM_FILECONFLICT_TARGET;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "PM_ERR_TRANS_COMMITING", 22)) {
    /*                                  ^         */
      *iv_return = PM_ERR_TRANS_COMMITING;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "PM_ERR_DLT_PATCHFAILED", 22)) {
    /*                                  ^         */
      *iv_return = PM_ERR_DLT_PATCHFAILED;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "PM_ERR_PKG_CANT_REMOVE", 22)) {
    /*                                  ^         */
      *iv_return = PM_ERR_PKG_CANT_REMOVE;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "PM_ERR_HANDLE_NOT_NULL", 22)) {
    /*                                  ^         */
      *iv_return = PM_ERR_HANDLE_NOT_NULL;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_23 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     PM_ERR_CONFLICTING_DEPS PM_ERR_PKG_INVALID_NAME PM_ERR_TRANS_DUP_TARGET
     PM_ERR_UNSATISFIED_DEPS PM_TRANS_FLAG_PRINTURIS */
  /* Offset 7 gives the best switch position.  */
  switch (name[7]) {
  case 'C':
    if (memEQ(name, "PM_ERR_CONFLICTING_DEPS", 23)) {
    /*                      ^                      */
      *iv_return = PM_ERR_CONFLICTING_DEPS;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "PM_ERR_PKG_INVALID_NAME", 23)) {
    /*                      ^                      */
      *iv_return = PM_ERR_PKG_INVALID_NAME;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "PM_TRANS_FLAG_PRINTURIS", 23)) {
    /*                      ^                      */
      *iv_return = PM_TRANS_FLAG_PRINTURIS;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "PM_ERR_TRANS_DUP_TARGET", 23)) {
    /*                      ^                      */
      *iv_return = PM_ERR_TRANS_DUP_TARGET;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "PM_ERR_UNSATISFIED_DEPS", 23)) {
    /*                      ^                      */
      *iv_return = PM_ERR_UNSATISFIED_DEPS;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_24 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     PM_ERR_EXTERNAL_DOWNLOAD PM_ERR_TRANS_DOWNLOADING PM_TRANS_EVT_REMOVE_DONE
     PM_TRANS_FLAG_RECURSEALL */
  /* Offset 23 gives the best switch position.  */
  switch (name[23]) {
  case 'D':
    if (memEQ(name, "PM_ERR_EXTERNAL_DOWNLOA", 23)) {
    /*                                      D      */
      *iv_return = PM_ERR_EXTERNAL_DOWNLOAD;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "PM_TRANS_EVT_REMOVE_DON", 23)) {
    /*                                      E      */
      *iv_return = PM_TRANS_EVT_REMOVE_DONE;
      return PERL_constant_ISIV;
    }
    break;
  case 'G':
    if (memEQ(name, "PM_ERR_TRANS_DOWNLOADIN", 23)) {
    /*                                      G      */
      *iv_return = PM_ERR_TRANS_DOWNLOADING;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "PM_TRANS_FLAG_RECURSEAL", 23)) {
    /*                                      L      */
      *iv_return = PM_TRANS_FLAG_RECURSEALL;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_25 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     PM_ERR_PKG_REPO_NOT_FOUND PM_ERR_TRANS_NOT_PREPARED
     PM_TRANS_CONV_LOCAL_NEWER PM_TRANS_CONV_REPLACE_PKG
     PM_TRANS_EVT_REMOVE_START PM_TRANS_EVT_UPGRADE_DONE
     PM_TRANS_FLAG_ALLEXPLICIT PM_TRANS_FLAG_NOCONFLICTS
     PM_TRANS_FLAG_NOSCRIPTLET */
  /* Offset 22 gives the best switch position.  */
  switch (name[22]) {
  case 'A':
    if (memEQ(name, "PM_TRANS_EVT_REMOVE_START", 25)) {
    /*                                     ^         */
      *iv_return = PM_TRANS_EVT_REMOVE_START;
      return PERL_constant_ISIV;
    }
    break;
  case 'C':
    if (memEQ(name, "PM_TRANS_FLAG_ALLEXPLICIT", 25)) {
    /*                                     ^         */
      *iv_return = PM_TRANS_FLAG_ALLEXPLICIT;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "PM_TRANS_FLAG_NOCONFLICTS", 25)) {
    /*                                     ^         */
      *iv_return = PM_TRANS_FLAG_NOCONFLICTS;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "PM_TRANS_FLAG_NOSCRIPTLET", 25)) {
    /*                                     ^         */
      *iv_return = PM_TRANS_FLAG_NOSCRIPTLET;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "PM_TRANS_EVT_UPGRADE_DONE", 25)) {
    /*                                     ^         */
      *iv_return = PM_TRANS_EVT_UPGRADE_DONE;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "PM_TRANS_CONV_REPLACE_PKG", 25)) {
    /*                                     ^         */
      *iv_return = PM_TRANS_CONV_REPLACE_PKG;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "PM_ERR_TRANS_NOT_PREPARED", 25)) {
    /*                                     ^         */
      *iv_return = PM_ERR_TRANS_NOT_PREPARED;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "PM_ERR_PKG_REPO_NOT_FOUND", 25)) {
    /*                                     ^         */
      *iv_return = PM_ERR_PKG_REPO_NOT_FOUND;
      return PERL_constant_ISIV;
    }
    break;
  case 'W':
    if (memEQ(name, "PM_TRANS_CONV_LOCAL_NEWER", 25)) {
    /*                                     ^         */
      *iv_return = PM_TRANS_CONV_LOCAL_NEWER;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_26 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     PM_FILECONFLICT_FILESYSTEM PM_TRANS_CONV_CONFLICT_PKG
     PM_TRANS_EVT_UPGRADE_START PM_TRANS_FLAG_DOWNLOADONLY */
  /* Offset 9 gives the best switch position.  */
  switch (name[9]) {
  case 'C':
    if (memEQ(name, "PM_TRANS_CONV_CONFLICT_PKG", 26)) {
    /*                        ^                       */
      *iv_return = PM_TRANS_CONV_CONFLICT_PKG;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "PM_TRANS_EVT_UPGRADE_START", 26)) {
    /*                        ^                       */
      *iv_return = PM_TRANS_EVT_UPGRADE_START;
      return PERL_constant_ISIV;
    }
    break;
  case 'F':
    if (memEQ(name, "PM_TRANS_FLAG_DOWNLOADONLY", 26)) {
    /*                        ^                       */
      *iv_return = PM_TRANS_FLAG_DOWNLOADONLY;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "PM_FILECONFLICT_FILESYSTEM", 26)) {
    /*                        ^                       */
      *iv_return = PM_FILECONFLICT_FILESYSTEM;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_27 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     PM_TRANS_CONV_CORRUPTED_PKG PM_TRANS_EVT_CHECKDEPS_DONE
     PM_TRANS_EVT_INTEGRITY_DONE PM_TRANS_EVT_RETRIEVE_START
     PM_TRANS_EVT_SCRIPTLET_INFO PM_TRANS_PROGRESS_ADD_START
     PM_TRANS_TYPE_REMOVEUPGRADE */
  /* Offset 18 gives the best switch position.  */
  switch (name[18]) {
  case 'A':
    if (memEQ(name, "PM_TRANS_PROGRESS_ADD_START", 27)) {
    /*                                 ^               */
      *iv_return = PM_TRANS_PROGRESS_ADD_START;
      return PERL_constant_ISIV;
    }
    break;
  case 'D':
    if (memEQ(name, "PM_TRANS_EVT_CHECKDEPS_DONE", 27)) {
    /*                                 ^               */
      *iv_return = PM_TRANS_EVT_CHECKDEPS_DONE;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "PM_TRANS_EVT_RETRIEVE_START", 27)) {
    /*                                 ^               */
      *iv_return = PM_TRANS_EVT_RETRIEVE_START;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "PM_TRANS_EVT_INTEGRITY_DONE", 27)) {
    /*                                 ^               */
      *iv_return = PM_TRANS_EVT_INTEGRITY_DONE;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "PM_TRANS_EVT_SCRIPTLET_INFO", 27)) {
    /*                                 ^               */
      *iv_return = PM_TRANS_EVT_SCRIPTLET_INFO;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "PM_TRANS_CONV_CORRUPTED_PKG", 27)) {
    /*                                 ^               */
      *iv_return = PM_TRANS_CONV_CORRUPTED_PKG;
      return PERL_constant_ISIV;
    }
    break;
  case 'V':
    if (memEQ(name, "PM_TRANS_TYPE_REMOVEUPGRADE", 27)) {
    /*                                 ^               */
      *iv_return = PM_TRANS_TYPE_REMOVEUPGRADE;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_28 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     PM_ERR_TRANS_NOT_INITIALIZED PM_TRANS_CONV_REMOVE_HOLDPKG
     PM_TRANS_EVT_CHECKDEPS_START PM_TRANS_EVT_INTEGRITY_START */
  /* Offset 17 gives the best switch position.  */
  switch (name[17]) {
  case 'G':
    if (memEQ(name, "PM_TRANS_EVT_INTEGRITY_START", 28)) {
    /*                                ^                 */
      *iv_return = PM_TRANS_EVT_INTEGRITY_START;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "PM_ERR_TRANS_NOT_INITIALIZED", 28)) {
    /*                                ^                 */
      *iv_return = PM_ERR_TRANS_NOT_INITIALIZED;
      return PERL_constant_ISIV;
    }
    break;
  case 'K':
    if (memEQ(name, "PM_TRANS_EVT_CHECKDEPS_START", 28)) {
    /*                                ^                 */
      *iv_return = PM_TRANS_EVT_CHECKDEPS_START;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "PM_TRANS_CONV_REMOVE_HOLDPKG", 28)) {
    /*                                ^                 */
      *iv_return = PM_TRANS_CONV_REMOVE_HOLDPKG;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_30 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     PM_TRANS_EVT_DELTA_PATCH_START PM_TRANS_EVT_RESOLVEDEPS_START
     PM_TRANS_PROGRESS_REMOVE_START */
  /* Offset 16 gives the best switch position.  */
  switch (name[16]) {
  case 'O':
    if (memEQ(name, "PM_TRANS_EVT_RESOLVEDEPS_START", 30)) {
    /*                               ^                    */
      *iv_return = PM_TRANS_EVT_RESOLVEDEPS_START;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "PM_TRANS_PROGRESS_REMOVE_START", 30)) {
    /*                               ^                    */
      *iv_return = PM_TRANS_PROGRESS_REMOVE_START;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "PM_TRANS_EVT_DELTA_PATCH_START", 30)) {
    /*                               ^                    */
      *iv_return = PM_TRANS_EVT_DELTA_PATCH_START;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_31 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     PM_TRANS_CONV_INSTALL_IGNOREPKG PM_TRANS_EVT_DELTA_PATCHES_DONE
     PM_TRANS_EVT_DELTA_PATCH_FAILED PM_TRANS_EVT_FILECONFLICTS_DONE
     PM_TRANS_PROGRESS_UPGRADE_START */
  /* Offset 23 gives the best switch position.  */
  switch (name[23]) {
  case 'C':
    if (memEQ(name, "PM_TRANS_EVT_FILECONFLICTS_DONE", 31)) {
    /*                                      ^              */
      *iv_return = PM_TRANS_EVT_FILECONFLICTS_DONE;
      return PERL_constant_ISIV;
    }
    break;
  case 'D':
    if (memEQ(name, "PM_TRANS_PROGRESS_UPGRADE_START", 31)) {
    /*                                      ^              */
      *iv_return = PM_TRANS_PROGRESS_UPGRADE_START;
      return PERL_constant_ISIV;
    }
    break;
  case 'G':
    if (memEQ(name, "PM_TRANS_CONV_INSTALL_IGNOREPKG", 31)) {
    /*                                      ^              */
      *iv_return = PM_TRANS_CONV_INSTALL_IGNOREPKG;
      return PERL_constant_ISIV;
    }
    break;
  case 'H':
    if (memEQ(name, "PM_TRANS_EVT_DELTA_PATCHES_DONE", 31)) {
    /*                                      ^              */
      *iv_return = PM_TRANS_EVT_DELTA_PATCHES_DONE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "PM_TRANS_EVT_DELTA_PATCH_FAILED", 31)) {
    /*                                      ^              */
      *iv_return = PM_TRANS_EVT_DELTA_PATCH_FAILED;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_32 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     PM_TRANS_EVT_DELTA_PATCHES_START PM_TRANS_EVT_FILECONFLICTS_START
     PM_TRANS_EVT_INTERCONFLICTS_DONE */
  /* Offset 19 gives the best switch position.  */
  switch (name[19]) {
  case 'N':
    if (memEQ(name, "PM_TRANS_EVT_FILECONFLICTS_START", 32)) {
    /*                                  ^                   */
      *iv_return = PM_TRANS_EVT_FILECONFLICTS_START;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "PM_TRANS_EVT_INTERCONFLICTS_DONE", 32)) {
    /*                                  ^                   */
      *iv_return = PM_TRANS_EVT_INTERCONFLICTS_DONE;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "PM_TRANS_EVT_DELTA_PATCHES_START", 32)) {
    /*                                  ^                   */
      *iv_return = PM_TRANS_EVT_DELTA_PATCHES_START;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_33 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     PM_TRANS_EVT_DELTA_INTEGRITY_DONE PM_TRANS_EVT_INTERCONFLICTS_START
     PM_TRANS_PROGRESS_CONFLICTS_START */
  /* Offset 15 gives the best switch position.  */
  switch (name[15]) {
  case 'L':
    if (memEQ(name, "PM_TRANS_EVT_DELTA_INTEGRITY_DONE", 33)) {
    /*                              ^                        */
      *iv_return = PM_TRANS_EVT_DELTA_INTEGRITY_DONE;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "PM_TRANS_PROGRESS_CONFLICTS_START", 33)) {
    /*                              ^                        */
      *iv_return = PM_TRANS_PROGRESS_CONFLICTS_START;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "PM_TRANS_EVT_INTERCONFLICTS_START", 33)) {
    /*                              ^                        */
      *iv_return = PM_TRANS_EVT_INTERCONFLICTS_START;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant (pTHX_ const char *name, STRLEN len, IV *iv_return) {
  /* Initially switch on the length of the name.  */
  /* When generated this function returned values for the list of names given
     in this section of perl code.  Rather than manually editing these functions
     to add or remove constants, which would result in this comment and section
     of code becoming inaccurate, we recommend that you edit this section of
     code, and use it to regenerate a new set of constant functions which you
     then use to replace the originals.

     Regenerate these constant functions by feeding this entire source file to
     perl -x

#!/usr/bin/perl -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(),
            {name=>"PM_DEP_MOD_ANY", type=>"IV", macro=>"1"},
            {name=>"PM_DEP_MOD_EQ", type=>"IV", macro=>"1"},
            {name=>"PM_DEP_MOD_GE", type=>"IV", macro=>"1"},
            {name=>"PM_DEP_MOD_GT", type=>"IV", macro=>"1"},
            {name=>"PM_DEP_MOD_LE", type=>"IV", macro=>"1"},
            {name=>"PM_DEP_MOD_LT", type=>"IV", macro=>"1"},
            {name=>"PM_ERR_BADPERMS", type=>"IV", macro=>"1"},
            {name=>"PM_ERR_CONFLICTING_DEPS", type=>"IV", macro=>"1"},
            {name=>"PM_ERR_DB_CREATE", type=>"IV", macro=>"1"},
            {name=>"PM_ERR_DB_NOT_FOUND", type=>"IV", macro=>"1"},
            {name=>"PM_ERR_DB_NOT_NULL", type=>"IV", macro=>"1"},
            {name=>"PM_ERR_DB_NULL", type=>"IV", macro=>"1"},
            {name=>"PM_ERR_DB_OPEN", type=>"IV", macro=>"1"},
            {name=>"PM_ERR_DB_REMOVE", type=>"IV", macro=>"1"},
            {name=>"PM_ERR_DB_SYNC", type=>"IV", macro=>"1"},
            {name=>"PM_ERR_DB_WRITE", type=>"IV", macro=>"1"},
            {name=>"PM_ERR_DLT_INVALID", type=>"IV", macro=>"1"},
            {name=>"PM_ERR_DLT_PATCHFAILED", type=>"IV", macro=>"1"},
            {name=>"PM_ERR_EXTERNAL_DOWNLOAD", type=>"IV", macro=>"1"},
            {name=>"PM_ERR_FILE_CONFLICTS", type=>"IV", macro=>"1"},
            {name=>"PM_ERR_GRP_NOT_FOUND", type=>"IV", macro=>"1"},
            {name=>"PM_ERR_HANDLE_LOCK", type=>"IV", macro=>"1"},
            {name=>"PM_ERR_HANDLE_NOT_NULL", type=>"IV", macro=>"1"},
            {name=>"PM_ERR_HANDLE_NULL", type=>"IV", macro=>"1"},
            {name=>"PM_ERR_INTERNAL_ERROR", type=>"IV", macro=>"1"},
            {name=>"PM_ERR_INVALID_REGEX", type=>"IV", macro=>"1"},
            {name=>"PM_ERR_LIBARCHIVE", type=>"IV", macro=>"1"},
            {name=>"PM_ERR_LIBDOWNLOAD", type=>"IV", macro=>"1"},
            {name=>"PM_ERR_MEMORY", type=>"IV", macro=>"1"},
            {name=>"PM_ERR_NOT_A_DIR", type=>"IV", macro=>"1"},
            {name=>"PM_ERR_NOT_A_FILE", type=>"IV", macro=>"1"},
            {name=>"PM_ERR_PKG_CANT_FRESH", type=>"IV", macro=>"1"},
            {name=>"PM_ERR_PKG_CANT_REMOVE", type=>"IV", macro=>"1"},
            {name=>"PM_ERR_PKG_HOLD", type=>"IV", macro=>"1"},
            {name=>"PM_ERR_PKG_INVALID", type=>"IV", macro=>"1"},
            {name=>"PM_ERR_PKG_INVALID_NAME", type=>"IV", macro=>"1"},
            {name=>"PM_ERR_PKG_LOAD", type=>"IV", macro=>"1"},
            {name=>"PM_ERR_PKG_NOT_FOUND", type=>"IV", macro=>"1"},
            {name=>"PM_ERR_PKG_OPEN", type=>"IV", macro=>"1"},
            {name=>"PM_ERR_PKG_REPO_NOT_FOUND", type=>"IV", macro=>"1"},
            {name=>"PM_ERR_RETRIEVE", type=>"IV", macro=>"1"},
            {name=>"PM_ERR_SERVER_BAD_URL", type=>"IV", macro=>"1"},
            {name=>"PM_ERR_SYSTEM", type=>"IV", macro=>"1"},
            {name=>"PM_ERR_TRANS_ABORT", type=>"IV", macro=>"1"},
            {name=>"PM_ERR_TRANS_COMMITING", type=>"IV", macro=>"1"},
            {name=>"PM_ERR_TRANS_DOWNLOADING", type=>"IV", macro=>"1"},
            {name=>"PM_ERR_TRANS_DUP_TARGET", type=>"IV", macro=>"1"},
            {name=>"PM_ERR_TRANS_NOT_INITIALIZED", type=>"IV", macro=>"1"},
            {name=>"PM_ERR_TRANS_NOT_NULL", type=>"IV", macro=>"1"},
            {name=>"PM_ERR_TRANS_NOT_PREPARED", type=>"IV", macro=>"1"},
            {name=>"PM_ERR_TRANS_NULL", type=>"IV", macro=>"1"},
            {name=>"PM_ERR_TRANS_TYPE", type=>"IV", macro=>"1"},
            {name=>"PM_ERR_UNSATISFIED_DEPS", type=>"IV", macro=>"1"},
            {name=>"PM_ERR_USER_ABORT", type=>"IV", macro=>"1"},
            {name=>"PM_ERR_WRONG_ARGS", type=>"IV", macro=>"1"},
            {name=>"PM_FILECONFLICT_FILESYSTEM", type=>"IV", macro=>"1"},
            {name=>"PM_FILECONFLICT_TARGET", type=>"IV", macro=>"1"},
            {name=>"PM_LOG_DEBUG", type=>"IV", macro=>"1"},
            {name=>"PM_LOG_ERROR", type=>"IV", macro=>"1"},
            {name=>"PM_LOG_FUNCTION", type=>"IV", macro=>"1"},
            {name=>"PM_LOG_WARNING", type=>"IV", macro=>"1"},
            {name=>"PM_PKG_REASON_DEPEND", type=>"IV", macro=>"1"},
            {name=>"PM_PKG_REASON_EXPLICIT", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_CONV_CONFLICT_PKG", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_CONV_CORRUPTED_PKG", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_CONV_INSTALL_IGNOREPKG", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_CONV_LOCAL_NEWER", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_CONV_REMOVE_HOLDPKG", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_CONV_REPLACE_PKG", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_EVT_ADD_DONE", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_EVT_ADD_START", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_EVT_CHECKDEPS_DONE", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_EVT_CHECKDEPS_START", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_EVT_DELTA_INTEGRITY_DONE", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_EVT_DELTA_INTEGRITY_START", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_EVT_DELTA_PATCHES_DONE", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_EVT_DELTA_PATCHES_START", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_EVT_DELTA_PATCH_DONE", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_EVT_DELTA_PATCH_FAILED", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_EVT_DELTA_PATCH_START", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_EVT_FILECONFLICTS_DONE", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_EVT_FILECONFLICTS_START", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_EVT_INTEGRITY_DONE", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_EVT_INTEGRITY_START", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_EVT_INTERCONFLICTS_DONE", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_EVT_INTERCONFLICTS_START", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_EVT_PRINTURI", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_EVT_REMOVE_DONE", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_EVT_REMOVE_START", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_EVT_RESOLVEDEPS_DONE", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_EVT_RESOLVEDEPS_START", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_EVT_RETRIEVE_START", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_EVT_SCRIPTLET_INFO", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_EVT_UPGRADE_DONE", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_EVT_UPGRADE_START", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_FLAG_ALLDEPS", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_FLAG_ALLEXPLICIT", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_FLAG_CASCADE", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_FLAG_DBONLY", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_FLAG_DOWNLOADONLY", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_FLAG_FORCE", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_FLAG_NEEDED", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_FLAG_NOCONFLICTS", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_FLAG_NODEPS", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_FLAG_NOSAVE", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_FLAG_NOSCRIPTLET", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_FLAG_PRINTURIS", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_FLAG_RECURSE", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_FLAG_RECURSEALL", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_FLAG_UNNEEDED", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_PROGRESS_ADD_START", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_PROGRESS_CONFLICTS_START", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_PROGRESS_REMOVE_START", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_PROGRESS_UPGRADE_START", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_TYPE_REMOVE", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_TYPE_REMOVEUPGRADE", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_TYPE_SYNC", type=>"IV", macro=>"1"},
            {name=>"PM_TRANS_TYPE_UPGRADE", type=>"IV", macro=>"1"});

print constant_types(), "\n"; # macro defs
foreach (C_constant ("ALPM", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("ALPM", $types);
__END__
   */

  switch (len) {
  case 12:
    /* Names all of length 12.  */
    /* PM_LOG_DEBUG PM_LOG_ERROR */
    /* Offset 7 gives the best switch position.  */
    switch (name[7]) {
    case 'D':
      if (memEQ(name, "PM_LOG_DEBUG", 12)) {
      /*                      ^           */
        *iv_return = PM_LOG_DEBUG;
        return PERL_constant_ISIV;
      }
      break;
    case 'E':
      if (memEQ(name, "PM_LOG_ERROR", 12)) {
      /*                      ^           */
        *iv_return = PM_LOG_ERROR;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 13:
    return constant_13 (aTHX_ name, iv_return);
    break;
  case 14:
    return constant_14 (aTHX_ name, iv_return);
    break;
  case 15:
    return constant_15 (aTHX_ name, iv_return);
    break;
  case 16:
    return constant_16 (aTHX_ name, iv_return);
    break;
  case 17:
    return constant_17 (aTHX_ name, iv_return);
    break;
  case 18:
    return constant_18 (aTHX_ name, iv_return);
    break;
  case 19:
    /* Names all of length 19.  */
    /* PM_ERR_DB_NOT_FOUND PM_TRANS_FLAG_FORCE */
    /* Offset 18 gives the best switch position.  */
    switch (name[18]) {
    case 'D':
      if (memEQ(name, "PM_ERR_DB_NOT_FOUN", 18)) {
      /*                                 D      */
        *iv_return = PM_ERR_DB_NOT_FOUND;
        return PERL_constant_ISIV;
      }
      break;
    case 'E':
      if (memEQ(name, "PM_TRANS_FLAG_FORC", 18)) {
      /*                                 E      */
        *iv_return = PM_TRANS_FLAG_FORCE;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 20:
    return constant_20 (aTHX_ name, iv_return);
    break;
  case 21:
    return constant_21 (aTHX_ name, iv_return);
    break;
  case 22:
    return constant_22 (aTHX_ name, iv_return);
    break;
  case 23:
    return constant_23 (aTHX_ name, iv_return);
    break;
  case 24:
    return constant_24 (aTHX_ name, iv_return);
    break;
  case 25:
    return constant_25 (aTHX_ name, iv_return);
    break;
  case 26:
    return constant_26 (aTHX_ name, iv_return);
    break;
  case 27:
    return constant_27 (aTHX_ name, iv_return);
    break;
  case 28:
    return constant_28 (aTHX_ name, iv_return);
    break;
  case 29:
    /* Names all of length 29.  */
    /* PM_TRANS_EVT_DELTA_PATCH_DONE PM_TRANS_EVT_RESOLVEDEPS_DONE */
    /* Offset 20 gives the best switch position.  */
    switch (name[20]) {
    case 'A':
      if (memEQ(name, "PM_TRANS_EVT_DELTA_PATCH_DONE", 29)) {
      /*                                   ^               */
        *iv_return = PM_TRANS_EVT_DELTA_PATCH_DONE;
        return PERL_constant_ISIV;
      }
      break;
    case 'D':
      if (memEQ(name, "PM_TRANS_EVT_RESOLVEDEPS_DONE", 29)) {
      /*                                   ^               */
        *iv_return = PM_TRANS_EVT_RESOLVEDEPS_DONE;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 30:
    return constant_30 (aTHX_ name, iv_return);
    break;
  case 31:
    return constant_31 (aTHX_ name, iv_return);
    break;
  case 32:
    return constant_32 (aTHX_ name, iv_return);
    break;
  case 33:
    return constant_33 (aTHX_ name, iv_return);
    break;
  case 34:
    if (memEQ(name, "PM_TRANS_EVT_DELTA_INTEGRITY_START", 34)) {
      *iv_return = PM_TRANS_EVT_DELTA_INTEGRITY_START;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

