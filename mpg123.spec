# This is a generic spec file that should "just work" with rpmbuild on any distro.
# Make sure you have appropriate -devel packes installed:
# - devel packages for alsa, sdl, etc... to build the respective output modules.
Summary:	The fast console mpeg audio decoder/player.
Name:		mpg123
Version:	1.33.0
Release:	1
URL:		http://www.mpg123.org/
License:	GPL
Group:		Applications/Multimedia
Packager:	Michael Ryzhykh <mclroy@gmail.com>
Source:		http://www.mpg123.org/download/mpg123-%{version}.tar.bz2
BuildRoot:	%_tmppath/%name-%version
Prefix: 	/usr

%description
This is a console based decoder/player for mono/stereo mpeg audio files,
probably more familiar as MP3 or MP2 files. It's focus is speed.
It can play MPEG1.0/2.0/2.5 layer I, II, II (1, 2, 3;-) files
(VBR files are fine, too) and produce output on a number of different ways:
raw data to stdout and different sound systems depending on your platform.

%package devel
Summary:	Files needed for development with libmpg123 or libout123 or libsyn123
Group:		Development/Libraries

%description devel
Libraries and header files for development with mpg123.

%prep
%setup -q -n %name-%version

%build
%configure --enable-shared --enable-static
make

%install
%{__rm} -rf %{buildroot}
%makeinstall

%clean
%{__rm} -rf %{buildroot}

%files
%defattr(755,root,root)
%{_bindir}/*
%defattr(644,root,root)
%doc %{_mandir}/*/mpg123.1.gz
%doc %{_mandir}/*/out123.1.gz
%{_libdir}/libmpg123.so.*
%{_libdir}/libout123.so.*
%{_libdir}/libsyn123.so.*
%{_libdir}/mpg123/output_*.so

%files devel
%defattr(644,root,root)
%{_libdir}/pkgconfig/libmpg123.pc
%{_libdir}/pkgconfig/libout123.pc
%{_libdir}/pkgconfig/libsyn123.pc
%{_includedir}/*.h
%{_libdir}/libmpg123.a
%{_libdir}/libmpg123.la
%{_libdir}/libmpg123.so
%{_libdir}/libout123.a
%{_libdir}/libout123.la
%{_libdir}/libout123.so
%{_libdir}/libsyn123.a
%{_libdir}/libsyn123.la
%{_libdir}/libsyn123.so

%changelog
* 2021-05-23 Thomas Orgis <thomas@orgis.org>
- removed output_*.a exclude, because build is fixed
* 2018-02-17 Thomas Orgis <thomas@orgis.org>
- added libsyn123
* 2017-02-27 Thomas Orgis <thomas@orgis.org>
- libltdl and module .la files gone
* Sat Sep  3 2016 Srikanth Rao <srirao@bandwidth.com>
- remove junk added in last edit, add out123 manpage
* Much later Thomas Orgis <thomas@orgis.org>
- some blind update
* Tue Jan  1 2008 Michael Ryzhykh <mclroy@gmail.com>
- Initial Version.

