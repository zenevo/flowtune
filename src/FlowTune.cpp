
#ifdef QT_QML_DEBUG
#include <QtQuick>
#endif

#include <QtQuick>
#include <sailfishapp.h>
#include <QObject>
#include <QTextCodec>
#include <QSettings>
#include <QStandardPaths>
#include <QDir>
#include <QFile>

#include "playlistmanager.h"
#include "utils.h"
#include "coversearch.h"
#include "coverflowtransform.h"
#include "meta.h"
#include "lfm.h"
#include "datos.h"
#include "missing.h"
#include "database.h"
#include "radios.h"
#include "player.h"

bool isDBOpened;
bool databaseWorking;

int main(int argc, char *argv[])
{
    QTextCodec *linuxCodec = QTextCodec::codecForName("UTF-8");
    QTextCodec::setCodecForLocale(linuxCodec);

    // The MPRIS QML module is bundled with the app (so mpris-qt5-qml-plugin
    // is not needed): its runtime library lives in the app's own lib folder.
    {
        const QByteArray old = qgetenv("LD_LIBRARY_PATH");
        qputenv("LD_LIBRARY_PATH",
                QByteArray("/usr/share/flowtune/lib")
                + (old.isEmpty() ? QByteArray() : QByteArray(":") + old));
    }

    QGuiApplication *app = SailfishApp::application(argc, argv);
    app->setOrganizationName("sailfishos-applications");
    app->setApplicationName("flowtune");

    // One-time migration: the app used to be called "flowplayer". Move the
    // existing library database and settings over so users keep their music.
    {
        const QString base = QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation)
                             + "/sailfishos-applications";
        const QDir oldDir(base + "/flowplayer");
        const QDir newDir(base + "/flowtune");
        if (oldDir.exists() && !newDir.exists()) {
            QDir().mkpath(newDir.path());
            QFile::copy(oldDir.filePath("flowplayer.db"), newDir.filePath("flowtune.db"));
            QFile::copy(oldDir.filePath("flowplayer.conf"), newDir.filePath("flowtune.conf"));

        }
    }

    QString lang;
    QTranslator translator;

    QSettings settings(QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation) + "/flowtune.conf", QSettings::NativeFormat);
    lang = settings.value("Language", "undefined").toString();

    if (lang=="undefined")
    {
        lang=  QLocale().name();
        qDebug() << "Getting language from locale:" << lang;
    }
    else
    {
        qDebug() << "Stored language: " << lang;
    }

    if (QFile::exists("/usr/share/flowtune/translations/"+ lang + ".qm"))
        translator.load("/usr/share/flowtune/translations/" + lang);
    else
        translator.load("/usr/share/flowtune/translations/en");

    app->installTranslator(&translator);

    // bring the cached album art over from the old application name
    // also bring the cached album art over
    const QString oldCache = QStandardPaths::writableLocation(QStandardPaths::GenericCacheLocation)
                             + "/sailfishos-applications/flowplayer";
    const QString newCache = QStandardPaths::writableLocation(QStandardPaths::GenericCacheLocation)
                             + "/sailfishos-applications/flowtune";
    if (QDir(oldCache).exists() && !QDir(newCache).exists()) {
        QDir().mkpath(newCache);
        const QStringList files = QDir(oldCache).entryList(QDir::Files);
        for (const QString &f : files)
            QFile::copy(QDir(oldCache).filePath(f), QDir(newCache).filePath(f));
        const QString artDir = "media-art";
        if (QDir(oldCache + "/" + artDir).exists()) {
            QDir().mkpath(newCache + "/" + artDir);
            const QStringList arts = QDir(oldCache + "/" + artDir).entryList(QDir::Files);
            for (const QString &f : arts)
                QFile::copy(oldCache + "/" + artDir + "/" + f, newCache + "/" + artDir + "/" + f);
        }
    }

    // ensure the media cache dir is created
    const QString mediaCacheDir = QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + "/media-art";
    QDir().mkpath(mediaCacheDir);

    QScopedPointer<QQuickView> window(SailfishApp::createView());
    window->setTitle("FlowTune");

    window->engine()->addImportPath("/usr/share/flowtune/qml");
    window->rootContext()->setContextProperty("appVersion", VERSION);
    bool hasPickers = false;
    for (const QString &path : window->engine()->importPathList()) {
        hasPickers = hasPickers || QFile::exists(path + "/Sailfish/Pickers");
    }
    window->rootContext()->setContextProperty("hasPickers", hasPickers);

    qmlRegisterType<Utils>("FlowTune", 1, 0, "Utils");
    qmlRegisterType<CoverSearch>("FlowTune", 1, 0, "CoverSearch");
    qmlRegisterType<CoverFlowTransform>("FlowTune", 1, 0, "CoverFlowTransform");
    qmlRegisterType<Meta>("FlowTune", 1, 0, "Meta");
    qmlRegisterType<LFM>("FlowTune", 1, 0, "LFM");
    qmlRegisterType<Datos>("FlowTune", 1, 0, "Datos");
    qmlRegisterType<PlaylistManager>("FlowTune", 1, 0, "MyPlaylistManager");
    qmlRegisterType<Missing>("FlowTune", 1, 0, "Missing");
    qmlRegisterType<Database>("FlowTune", 1, 0, "Database");
    qmlRegisterType<Radios>("FlowTune", 1, 0, "Radios");

    qmlRegisterType<Player>("FlowTune", 1, 0, "Player");

    //qmlRegisterType<Playlist>("FlowTune", 1, 0, "Playlist");
    //qmlRegisterType<MyPlaylist>("FlowTune", 1, 0, "MyPlaylist");
    //qmlRegisterType<MyPlaylists>("FlowTune", 1, 0, "MyPlaylists");
    //qmlRegisterType<MusicModel>("FlowTune", 1, 0, "MusicModel");

    window->setSource(SailfishApp::pathTo("qml/flowtune.qml"));

    window->showFullScreen();
    return app->exec();
    qDebug() << "Good bye!";
}

