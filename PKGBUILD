# Justin Davis <jrcd83@gmail.com>
pkgname=perl-alpm-git
pkgver=20130411
pkgrel=1
pkgdesc='Developer release for ALPM perl module'
arch=(i686 x86_64)
license=(PerlArtistic GPL)
options=('!emptydirs')
depends=(perl)
provides=(perl-alpm)
url='http://github.com/juster/perl-alpm'
md5sums=()
source=()
_gitroot='git://github.com/juster/perl-alpm.git'
_gitbranch=${BRANCH:-master}

build()
(
	_dir="$startdir/$pkgname"
	msg 'Creating ALPM developer package...'

	if [ -d "$_dir" ] ; then
		warning 'Repository directory already exists!'
		msg2 'Attempting to pull from repo...'
		cd "$_dir"
		git pull origin "$_gitbranch"
	else
		msg2 "Cloning $_gitroot repository..."
		git clone "$_gitroot" "$_dir"
		cd "$_dir"
	fi

	msg2 "Checking out the $_gitbranch branch..."
	git checkout "$_gitbranch"
	if [ "$?" -ne 0 ] ; then
		error "Failed to checkout the $_gitbranch branch... aborting."
		return 1
	fi

	msg 'Building ALPM...'
	/usr/bin/perl Makefile.PL
	make
)

check()
{
	cd "$startdir/$pkgname"
	make test
}

package()
{
	cd "$startdir/$pkgname"
	make install INSTALLDIRS=vendor "DESTDIR=$pkgdir"
	find "$pkgdir" -name .packlist -o -name perllocal.pod -delete
}
