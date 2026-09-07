#pragma once

#include <QAbstractListModel>
#include <QVariantList>

class RemoteTrackModel final : public QAbstractListModel
{
    Q_OBJECT

public:
    enum Role {
        TrackRole = Qt::UserRole + 1
    };

    explicit RemoteTrackModel(const QString &source, QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void setTracks(const QVariantList &tracks);

private:
    QString m_source;
    QVariantList m_tracks;
};
