#pragma once

#include <QList>
#include <QNetworkReply>
#include <QPointer>

inline void cancelNetworkReplies(const QList<QPointer<QNetworkReply>> &replies)
{
    // abort() can emit finished() synchronously and mutate the caller's list.
    const auto pending = replies;
    for (const auto &reply : pending) {
        if (reply && reply->isRunning()) reply->abort();
    }
}
