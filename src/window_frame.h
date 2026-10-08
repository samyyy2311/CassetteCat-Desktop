#pragma once

#include <QAbstractNativeEventFilter>
#include <QObject>
#include <QPointer>

class QQuickItem;

/// Makes the drawn maximize button behave like a native one on Windows, so hovering it shows Snap Layouts on
/// Windows 11. While the pointer is over it, Windows owns the mouse, so hover and clicks are reported from here.
class WindowFrame final : public QObject, public QAbstractNativeEventFilter {
    Q_OBJECT
    Q_PROPERTY(bool maximizeHovered READ maximizeHovered NOTIFY maximizeHoveredChanged)

  public:
    explicit WindowFrame(QObject *parent = nullptr);
    ~WindowFrame() override;

    Q_INVOKABLE void setMaximizeButton(QQuickItem *button);
    bool maximizeHovered() const;

    bool nativeEventFilter(const QByteArray &eventType, void *message, qintptr *result) override;

  signals:
    void maximizeHoveredChanged();
    void maximizeClicked();

  private:
    /// Whether the screen point \p x, \p y in physical pixels lies over the maximize button.
    bool overButton(int x, int y) const;
    void setHovered(bool hovered);

    QPointer<QQuickItem> m_button;
    bool m_hovered = false;
};
