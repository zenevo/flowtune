Name:       flowtune
Summary:    Music player for Sailfish OS (FlowPlayer fork with a landscape cover flow)
Version:    0.3.7
Release:    1
License:    MPL-2.0
Source0:    flowtune-0.3.7.tar.gz
BuildRequires:  pkgconfig(sailfishapp)
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Xml)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  pkgconfig(gstreamer-1.0)
BuildRequires:  pkgconfig(libresource)
BuildRequires:  pkgconfig(libresource-glib)
BuildRequires:  pkgconfig(taglib)
Requires:       jolla-mediaplayer
Requires:       mpris-qt5-qml-plugin

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
install -D -m 644 flowtune.desktop %{buildroot}%{_datadir}/applications/flowtune.desktop
for s in 86 108 128 172 256 512; do
  install -D -m 644 flowtune-$s.png %{buildroot}%{_datadir}/icons/hicolor/${s}x${s}/apps/flowtune.png
done

%files
%{_bindir}/flowtune
%{_datadir}/flowtune
%{_datadir}/applications/flowtune.desktop
%{_datadir}/icons/hicolor/*/apps/flowtune.png
