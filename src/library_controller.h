#pragma once

#include <QAbstractListModel>
#include <QFileSystemWatcher>
#include <QHash>
#include <QProcess>
#include <QSet>
#include <QString>
#include <QStringList>
#include <QTimer>
#include <QUrl>
#include <QVariantList>
#include <QVariantMap>
#include <QVector>

class LibraryController final : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(QStringList folders READ folders NOTIFY changed)
    Q_PROPERTY(int trackCount READ trackCount NOTIFY tracksChanged)
    Q_PROPERTY(int visibleTrackCount READ visibleTrackCount NOTIFY visibleTracksChanged)

public:
    explicit LibraryController(QObject *parent = nullptr);
    static bool selfCheck();

    enum Role {
        TrackRole = Qt::UserRole + 1
    };

    QStringList folders() const;
    int trackCount() const { return m_trackCount; }
    int visibleTrackCount() const { return m_visibleRows.size(); }
    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void loadFolder(const QUrl &url);
    Q_INVOKABLE void removeFolder(const QString &path);
    Q_INVOKABLE QString localPath(const QUrl &url) const;
    Q_INVOKABLE QString artworkFor(const QString &filePath);
    Q_INVOKABLE QVariantMap trackForPath(const QString &filePath) const;
    Q_INVOKABLE QVariantMap firstPlayableTrack() const;
    Q_INVOKABLE QVariantList playbackTracks() const;
    Q_INVOKABLE QVariantMap catalogGroups() const;
    Q_INVOKABLE void setLibraryFilter(const QString &query, const QString &filter,
                                      const QVariantMap &favorites, const QString &sortMetric,
                                      bool ascending, const QVariantList &excludedFolders,
                                      bool ignoreShortClips);
    Q_INVOKABLE void setSearchFilter(const QString &query, const QString &format,
                                     const QVariantList &excludedFolders, bool ignoreShortClips);

signals:
    void changed();
    void tracksChanged();
    void visibleTracksChanged();

private:
    void setFolderPaths(QStringList paths);
    void startScan();
    void rescanFolder();
    void updateFolderWatch();
    void setFilter(const QString &query, const QString &format, bool strictFormat,
                   bool favoritesOnly, const QVariantMap &favorites, const QString &sortMetric,
                   bool ascending, const QVariantList &excludedFolders, bool ignoreShortClips);
    void rebuildVisibleRows();
    bool isAvailable(const QVariantMap &track) const;
    bool matchesVisibleFilter(const QVariantMap &track) const;

    QStringList m_folders;
    QVariantList m_tracks;
    QVector<int> m_visibleRows;
    QString m_query;
    QString m_format;
    QString m_sortMetric;
    QStringList m_excludedFolders;
    QSet<QString> m_favorites;
    bool m_strictFormat = false;
    bool m_favoritesOnly = false;
    bool m_sortAscending = true;
    bool m_ignoreShortClips = false;
    int m_trackCount = 0;
    QHash<QString, QString> m_artworkUrls;
    QFileSystemWatcher m_folderWatcher;
    QTimer m_watchDebounce;
    QProcess m_scanProcess;
    QStringList m_pendingScanPaths;
    QVariantList m_scannedTracks;
    quint64 m_scanGeneration = 0;
    quint64 m_activeScanGeneration = 0;
};
