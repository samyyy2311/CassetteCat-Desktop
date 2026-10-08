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
    /// How far a maximized window extends past each screen edge, in device-independent pixels.
    Q_PROPERTY(qreal maximizedMargin READ maximizedMargin NOTIFY maximizedMarginChanged)

  public:
    explicit WindowFrame(QObject *parent = nullptr);
    ~WindowFrame() override;

    Q_INVOKABLE void setMaximizeButton(QQuickItem *button);
    bool maximizeHovered() const;
    qreal maximizedMargin() const;

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

    QPointer<QQuickItem> m_button;
    bool m_hovered = false;
    qreal m_maximizedMargin = 0;
};
