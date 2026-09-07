#include "remote_track_model.h"

#include <utility>

RemoteTrackModel::RemoteTrackModel(const QString &source, QObject *parent)
    : QAbstractListModel(parent)
    , m_source(source)
{
}

int RemoteTrackModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_tracks.size();
}

QVariant RemoteTrackModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_tracks.size()) return {};
    if (role == TrackRole) return m_tracks.at(index.row());
    return {};
}

QHash<int, QByteArray> RemoteTrackModel::roleNames() const
{
    return {{TrackRole, "track"}};
}

void RemoteTrackModel::setTracks(const QVariantList &tracks)
{
    QVariantList filtered;
    filtered.reserve(tracks.size());
    for (const QVariant &value : tracks) {
        if (value.toMap().value("source").toString() == m_source) filtered.append(value);
    }

    beginResetModel();
    m_tracks = std::move(filtered);
    endResetModel();
}
