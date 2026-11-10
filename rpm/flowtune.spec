Name:       flowtune
Summary:    Music player for Sailfish OS (FlowPlayer fork with a landscape cover flow)
Version:    0.1
Release:    1
License:    MPL-2.0
Source0:    flowtune-0.1.tar.gz
BuildRequires:  pkgconfig(sailfishapp)
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Xml)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  pkgconfig(gstreamer-1.0)
BuildRequires:  pkgconfig(libresource)
BuildRequires:  pkgconfig(libresource-glib)
BuildRequires:  pkgconfig(taglib)
# Self-contained: the QML dependency generator would otherwise re-add
# jolla-mediaplayer / mpris-qt5-qml-plugin from the imports this package now
# carries, or provides itself.
%global __requires_exclude ^(jolla-mediaplayer|mpris-qt5-qml-plugin|libmpris-qt5\.so\.1.*)$

# No runtime package dependencies: the MPRIS QML module it needs is bundled
# (qml/org/nemomobile/mpris + lib/libmpris-qt5), and the jolla-mediaplayer
# module was replaced by local code (see qml/pages/MediaKey.qml).

%description
FlowTune is a fork of FlowPlayer, the feature rich music player for Sailfish OS,
with a landscape Cover Flow, working album art sources and artist photos.

%prep
%setup -q -n flowtune-%{version}

%build
cd flowtune-%{version}
qmake VERSION=%{version}
make %{?_smp_mflags}

%install
cd flowtune-%{version}
make install INSTALL_ROOT=%{buildroot}
# bundled MPRIS runtime library (see src/FlowTune.cpp: LD_LIBRARY_PATH)
install -d %{buildroot}%{_datadir}/flowtune/lib
install -m 755 lib/libmpris-qt5.so.1.0.6 %{buildroot}%{_datadir}/flowtune/lib/
ln -sf libmpris-qt5.so.1.0.6 %{buildroot}%{_datadir}/flowtune/lib/libmpris-qt5.so.1
install -D -m 644 flowtune.desktop %{buildroot}%{_datadir}/applications/flowtune.desktop
for s in 86 108 128 172 256 512; do
  install -D -m 644 flowtune-$s.png %{buildroot}%{_datadir}/icons/hicolor/${s}x${s}/apps/flowtune.png
done

%files
%{_bindir}/flowtune
%{_datadir}/flowtune
%{_datadir}/applications/flowtune.desktop
%{_datadir}/icons/hicolor/*/apps/flowtune.png
