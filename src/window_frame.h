#pragma once

#include <QAbstractNativeEventFilter>
#include <QObject>
#include <QPointer>
#include <QStringList>

class QQuickItem;

/// Makes the drawn maximize button behave like a native one on Windows, so hovering it shows Snap Layouts on
/// Windows 11. While the pointer is over it, Windows owns the mouse, so hover and clicks are reported from here.
class WindowFrame final : public QObject, public QAbstractNativeEventFilter {
    Q_OBJECT
    Q_PROPERTY(bool maximizeHovered READ maximizeHovered NOTIFY maximizeHoveredChanged)
    /// How far a maximized window extends past each screen edge, in device-independent pixels.
    Q_PROPERTY(qreal maximizedMargin READ maximizedMargin NOTIFY maximizedMarginChanged)
    /// The window buttons on the right of the title bar, in order, as the Linux desktop sets them: "close" alone
    /// by default on GNOME. Empty elsewhere.
    Q_PROPERTY(QStringList linuxButtons READ linuxButtons CONSTANT)
    /// Whether the Linux desktop draws round, filled title bar buttons, as GNOME and its relatives do.
    Q_PROPERTY(bool roundButtons READ roundButtons CONSTANT)

  public:
    explicit WindowFrame(QObject *parent = nullptr);
    ~WindowFrame() override;

    Q_INVOKABLE void setMaximizeButton(QQuickItem *button);
    bool maximizeHovered() const;
    qreal maximizedMargin() const;
    QStringList linuxButtons() const;
    bool roundButtons() const;

    bool nativeEventFilter(const QByteArray &eventType, void *message, qintptr *result) override;

  signals:
    void maximizeHoveredChanged();
    void maximizedMarginChanged();
    void maximizeClicked();

  private:
    /// Whether the screen point \p x, \p y in physical pixels lies over the maximize button.
    bool overButton(int x, int y) const;
    void setHovered(bool hovered);
    void setMaximizedMargin(qreal margin);
    static QStringList readLinuxButtons();

    QPointer<QQuickItem> m_button;
    bool m_hovered = false;
    qreal m_maximizedMargin = 0;
    QStringList m_linuxButtons;
};
