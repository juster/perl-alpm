use ExtUtils::MakeMaker;

# Avoid FAIL reports from CPAN Testers...
require DynaLoader;
unless ( DynaLoader::dl_findfile( '-lalpm' )) {
    print STDERR "ERROR: pacman/libalpm must be installed for this module\n";
    exit 0;
}

WriteMakefile(
    NAME              => 'ALPM',
    VERSION_FROM      => 'lib/ALPM.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/ALPM.pod', # retrieve abstract from module
       AUTHOR         => 'Justin Davis <juster at cpan>') : ()),
    LIBS              => ['-lalpm'], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
    META_MERGE        => { resources =>
                           { repository => 'http://github.com/juster/perl-alpm'
			   }},
    clean => { FILES  => 't/root t/repos/share' },
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);

if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = map { +{ name => $_, macro => 1 } }
      (qw(PM_PKG_REASON_EXPLICIT
          PM_PKG_REASON_DEPEND

          PM_TRANS_TYPE_UPGRADE
          PM_TRANS_TYPE_REMOVE
          PM_TRANS_TYPE_REMOVEUPGRADE
          PM_TRANS_TYPE_SYNC

          PM_TRANS_FLAG_NODEPS
          PM_TRANS_FLAG_FORCE
          PM_TRANS_FLAG_NOSAVE
          PM_TRANS_FLAG_CASCADE
          PM_TRANS_FLAG_RECURSE
          PM_TRANS_FLAG_DBONLY
          PM_TRANS_FLAG_ALLDEPS
          PM_TRANS_FLAG_DOWNLOADONLY
          PM_TRANS_FLAG_NOSCRIPTLET
          PM_TRANS_FLAG_NOCONFLICTS
          PM_TRANS_FLAG_NEEDED
          PM_TRANS_FLAG_ALLEXPLICIT
          PM_TRANS_FLAG_UNNEEDED
          PM_TRANS_FLAG_RECURSEALL
          PM_TRANS_FLAG_NOLOCK

          PM_TRANS_EVT_CHECKDEPS_START
          PM_TRANS_EVT_CHECKDEPS_DONE
          PM_TRANS_EVT_FILECONFLICTS_START
          PM_TRANS_EVT_FILECONFLICTS_DONE
          PM_TRANS_EVT_RESOLVEDEPS_START
          PM_TRANS_EVT_RESOLVEDEPS_DONE
          PM_TRANS_EVT_INTERCONFLICTS_START
          PM_TRANS_EVT_INTERCONFLICTS_DONE
          PM_TRANS_EVT_ADD_START
          PM_TRANS_EVT_ADD_DONE
          PM_TRANS_EVT_REMOVE_START
          PM_TRANS_EVT_REMOVE_DONE
          PM_TRANS_EVT_UPGRADE_START
          PM_TRANS_EVT_UPGRADE_DONE
          PM_TRANS_EVT_INTEGRITY_START
          PM_TRANS_EVT_INTEGRITY_DONE
          PM_TRANS_EVT_DELTA_INTEGRITY_START
          PM_TRANS_EVT_DELTA_INTEGRITY_DONE
          PM_TRANS_EVT_DELTA_PATCHES_START
          PM_TRANS_EVT_DELTA_PATCHES_DONE
          PM_TRANS_EVT_DELTA_PATCH_START
          PM_TRANS_EVT_DELTA_PATCH_DONE
          PM_TRANS_EVT_DELTA_PATCH_FAILED
          PM_TRANS_EVT_SCRIPTLET_INFO
          PM_TRANS_EVT_RETRIEVE_START

          PM_TRANS_CONV_INSTALL_IGNOREPKG
          PM_TRANS_CONV_REPLACE_PKG
          PM_TRANS_CONV_CONFLICT_PKG
          PM_TRANS_CONV_CORRUPTED_PKG
          PM_TRANS_CONV_LOCAL_NEWER
          PM_TRANS_CONV_REMOVE_PKGS

          PM_TRANS_PROGRESS_ADD_START
          PM_TRANS_PROGRESS_UPGRADE_START
          PM_TRANS_PROGRESS_REMOVE_START
          PM_TRANS_PROGRESS_CONFLICTS_START

          PM_DEP_MOD_ANY
          PM_DEP_MOD_EQ
          PM_DEP_MOD_GE
          PM_DEP_MOD_LE
          PM_DEP_MOD_GT
          PM_DEP_MOD_LT

          PM_FILECONFLICT_TARGET
          PM_FILECONFLICT_FILESYSTEM

          PM_ERR_MEMORY
          PM_ERR_SYSTEM
          PM_ERR_BADPERMS
          PM_ERR_NOT_A_FILE
          PM_ERR_NOT_A_DIR
          PM_ERR_WRONG_ARGS

          PM_ERR_HANDLE_NULL
          PM_ERR_HANDLE_NOT_NULL
          PM_ERR_HANDLE_LOCK

          PM_ERR_DB_OPEN
          PM_ERR_DB_CREATE
          PM_ERR_DB_NULL
          PM_ERR_DB_NOT_NULL
          PM_ERR_DB_NOT_FOUND
          PM_ERR_DB_WRITE
          PM_ERR_DB_REMOVE

          PM_ERR_SERVER_BAD_URL
          PM_ERR_SERVER_NONE

          PM_ERR_TRANS_NOT_NULL
          PM_ERR_TRANS_NULL
          PM_ERR_TRANS_DUP_TARGET
          PM_ERR_TRANS_NOT_INITIALIZED
          PM_ERR_TRANS_NOT_PREPARED
          PM_ERR_TRANS_ABORT
          PM_ERR_TRANS_TYPE
          PM_ERR_TRANS_NOT_LOCKED

          PM_ERR_PKG_NOT_FOUND
          PM_ERR_PKG_IGNORED
          PM_ERR_PKG_INVALID
          PM_ERR_PKG_OPEN
          PM_ERR_PKG_CANT_REMOVE
          PM_ERR_PKG_INVALID_NAME
          PM_ERR_PKG_REPO_NOT_FOUND

          PM_ERR_DLT_INVALID
          PM_ERR_DLT_PATCHFAILED

          PM_ERR_UNSATISFIED_DEPS
          PM_ERR_CONFLICTING_DEPS
          PM_ERR_FILE_CONFLICTS
          PM_ERR_RETRIEVE
          PM_ERR_INVALID_REGEX
          PM_ERR_LIBARCHIVE
          PM_ERR_LIBFETCH
          PM_ERR_EXTERNAL_DOWNLOAD));

  ExtUtils::Constant::WriteConstants( NAME         => 'ALPM',
                                      NAMES        => \@names,
                                      DEFAULT_TYPE => 'IV',
                                      C_FILE       => 'const-c.inc',
                                      XS_FILE      => 'const-xs.inc',
                                  );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}
