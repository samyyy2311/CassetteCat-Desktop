#include "smtc_controller.h"
#include "player_controller.h"

#include <QDebug>
#include <QFileInfo>
#include <QUrl>
#include <algorithm>

#ifdef Q_OS_WIN
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <inspectable.h>
#include <winstring.h>
#include <winrt/base.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Storage.h>
#include <winrt/Windows.Storage.Streams.h>

// Authentic Windows 10/11 WinRT GUIDs
static const GUID IID_ISystemMediaTransportControlsInterop =
    { 0xddb0472d, 0xc911, 0x4a1f, { 0x86, 0xd9, 0xdc, 0x3d, 0x71, 0xa9, 0x5f, 0x5a } };

static const GUID IID_ISystemMediaTransportControls =
    { 0x99fa3ff4, 0x1742, 0x42a6, { 0x90, 0x2e, 0x08, 0x7d, 0x41, 0xf9, 0x65, 0xec } };

static const GUID IID_ISystemMediaTransportControls2 =
    { 0xea98d2f6, 0x7f3c, 0x4af2, { 0xa5, 0x86, 0x72, 0x88, 0x98, 0x08, 0xef, 0xb1 } };

static const GUID IID_ISystemMediaTransportControlsDisplayUpdater =
    { 0x8abbc53e, 0xfa55, 0x4ecf, { 0xad, 0x8e, 0xc9, 0x84, 0xe5, 0xdd, 0x15, 0x50 } };

static const GUID IID_IMusicDisplayProperties =
    { 0x6bbf0c59, 0xd0a0, 0x4d26, { 0x92, 0xa0, 0xf9, 0x78, 0xe1, 0xd1, 0x8e, 0x7b } };

static const GUID IID_IMusicDisplayProperties2 =
    { 0x00368462, 0x97d3, 0x44b9, { 0xb0, 0x0f, 0x00, 0x8a, 0xfc, 0xef, 0xaf, 0x18 } };

static const GUID IID_ISystemMediaTransportControlsTimelineProperties =
    { 0x5125316a, 0xc3a2, 0x475b, { 0x85, 0x07, 0x93, 0x53, 0x4d, 0xc8, 0x8f, 0x15 } };

static const GUID IID_ITypedEventHandler_ButtonPressed =
    { 0x0557e996, 0x7b23, 0x5bae, { 0xaa, 0x81, 0xea, 0x0d, 0x67, 0x11, 0x43, 0xa4 } };

static const GUID IID_ITypedEventHandler_PlaybackPosition =
    { 0x44e34f15, 0xbdc0, 0x50a7, { 0xac, 0xe4, 0x39, 0xe9, 0x1f, 0xb7, 0x53, 0xf1 } };

// Enums
enum MediaPlaybackStatus {
    MediaPlaybackStatus_Closed = 0,
    MediaPlaybackStatus_Changing = 1,
    MediaPlaybackStatus_Stopped = 2,
    MediaPlaybackStatus_Playing = 3,
    MediaPlaybackStatus_Paused = 4
};

enum MediaPlaybackType {
    MediaPlaybackType_Unknown = 0,
    MediaPlaybackType_Music = 1,
    MediaPlaybackType_Video = 2,
    MediaPlaybackType_Image = 3
};

enum SystemMediaTransportControlsButton {
    SystemMediaTransportControlsButton_Play = 0,
    SystemMediaTransportControlsButton_Pause = 1,
    SystemMediaTransportControlsButton_Stop = 2,
    SystemMediaTransportControlsButton_Record = 3,
    SystemMediaTransportControlsButton_FastForward = 4,
    SystemMediaTransportControlsButton_Rewind = 5,
    SystemMediaTransportControlsButton_Next = 6,
    SystemMediaTransportControlsButton_Previous = 7,
    SystemMediaTransportControlsButton_ChannelUp = 8,
    SystemMediaTransportControlsButton_ChannelDown = 9
};

struct EventRegistrationToken {
    __int64 value;
};

struct TimeSpan {
    __int64 Duration;
};

// COM Interface declarations
struct ISystemMediaTransportControlsInterop : public IInspectable {
    virtual HRESULT STDMETHODCALLTYPE GetForWindow(HWND appWindow, REFIID riid, void **mediaTransportControl) = 0;
};

struct IMusicDisplayProperties : public IInspectable {
    virtual HRESULT STDMETHODCALLTYPE get_Title(HSTRING *value) = 0;
    virtual HRESULT STDMETHODCALLTYPE put_Title(HSTRING value) = 0;
    virtual HRESULT STDMETHODCALLTYPE get_AlbumArtist(HSTRING *value) = 0;
    virtual HRESULT STDMETHODCALLTYPE put_AlbumArtist(HSTRING value) = 0;
    virtual HRESULT STDMETHODCALLTYPE get_Artist(HSTRING *value) = 0;
    virtual HRESULT STDMETHODCALLTYPE put_Artist(HSTRING value) = 0;
};

struct IMusicDisplayProperties2 : public IInspectable {
    virtual HRESULT STDMETHODCALLTYPE get_AlbumTitle(HSTRING *value) = 0;
    virtual HRESULT STDMETHODCALLTYPE put_AlbumTitle(HSTRING value) = 0;
    virtual HRESULT STDMETHODCALLTYPE get_TrackNumber(UINT32 *value) = 0;
    virtual HRESULT STDMETHODCALLTYPE put_TrackNumber(UINT32 value) = 0;
    virtual HRESULT STDMETHODCALLTYPE get_Genres(void **value) = 0;
};

struct ISystemMediaTransportControlsDisplayUpdater : public IInspectable {
    virtual HRESULT STDMETHODCALLTYPE get_Type(MediaPlaybackType *value) = 0;
    virtual HRESULT STDMETHODCALLTYPE put_Type(MediaPlaybackType value) = 0;
    virtual HRESULT STDMETHODCALLTYPE get_AppMediaId(HSTRING *value) = 0;
    virtual HRESULT STDMETHODCALLTYPE put_AppMediaId(HSTRING value) = 0;
    virtual HRESULT STDMETHODCALLTYPE get_Thumbnail(void **value) = 0;
    virtual HRESULT STDMETHODCALLTYPE put_Thumbnail(void *value) = 0;
    virtual HRESULT STDMETHODCALLTYPE get_MusicProperties(IMusicDisplayProperties **value) = 0;
    virtual HRESULT STDMETHODCALLTYPE get_VideoProperties(void **value) = 0;
    virtual HRESULT STDMETHODCALLTYPE get_ImageProperties(void **value) = 0;
    virtual HRESULT STDMETHODCALLTYPE CopyFromFileAsync(MediaPlaybackType type, void *source, void **operation) = 0;
    virtual HRESULT STDMETHODCALLTYPE ClearAll() = 0;
    virtual HRESULT STDMETHODCALLTYPE Update() = 0;
};

struct ISystemMediaTransportControlsButtonPressedEventArgs : public IInspectable {
    virtual HRESULT STDMETHODCALLTYPE get_Button(SystemMediaTransportControlsButton *value) = 0;
};

struct IPlaybackPositionChangeRequestedEventArgs : public IInspectable {
    virtual HRESULT STDMETHODCALLTYPE get_RequestedPlaybackPosition(TimeSpan *value) = 0;
};

struct ISystemMediaTransportControlsTimelineProperties : public IInspectable {
    virtual HRESULT STDMETHODCALLTYPE get_StartTime(TimeSpan *value) = 0;
    virtual HRESULT STDMETHODCALLTYPE put_StartTime(TimeSpan value) = 0;
    virtual HRESULT STDMETHODCALLTYPE get_EndTime(TimeSpan *value) = 0;
    virtual HRESULT STDMETHODCALLTYPE put_EndTime(TimeSpan value) = 0;
    virtual HRESULT STDMETHODCALLTYPE get_MinSeekTime(TimeSpan *value) = 0;
    virtual HRESULT STDMETHODCALLTYPE put_MinSeekTime(TimeSpan value) = 0;
    virtual HRESULT STDMETHODCALLTYPE get_MaxSeekTime(TimeSpan *value) = 0;
    virtual HRESULT STDMETHODCALLTYPE put_MaxSeekTime(TimeSpan value) = 0;
    virtual HRESULT STDMETHODCALLTYPE get_Position(TimeSpan *value) = 0;
    virtual HRESULT STDMETHODCALLTYPE put_Position(TimeSpan value) = 0;
};

struct ISystemMediaTransportControls : public IInspectable {
    virtual HRESULT STDMETHODCALLTYPE get_PlaybackStatus(MediaPlaybackStatus *value) = 0;
    virtual HRESULT STDMETHODCALLTYPE put_PlaybackStatus(MediaPlaybackStatus value) = 0;
    virtual HRESULT STDMETHODCALLTYPE get_DisplayUpdater(ISystemMediaTransportControlsDisplayUpdater **value) = 0;
    virtual HRESULT STDMETHODCALLTYPE get_SoundLevel(int *value) = 0;
    virtual HRESULT STDMETHODCALLTYPE get_IsEnabled(boolean *value) = 0;
    virtual HRESULT STDMETHODCALLTYPE put_IsEnabled(boolean value) = 0;
    virtual HRESULT STDMETHODCALLTYPE get_IsPlayEnabled(boolean *value) = 0;
    virtual HRESULT STDMETHODCALLTYPE put_IsPlayEnabled(boolean value) = 0;
    virtual HRESULT STDMETHODCALLTYPE get_IsStopEnabled(boolean *value) = 0;
    virtual HRESULT STDMETHODCALLTYPE put_IsStopEnabled(boolean value) = 0;
    virtual HRESULT STDMETHODCALLTYPE get_IsPauseEnabled(boolean *value) = 0;
    virtual HRESULT STDMETHODCALLTYPE put_IsPauseEnabled(boolean value) = 0;
    virtual HRESULT STDMETHODCALLTYPE get_IsRecordEnabled(boolean *value) = 0;
    virtual HRESULT STDMETHODCALLTYPE put_IsRecordEnabled(boolean value) = 0;
    virtual HRESULT STDMETHODCALLTYPE get_IsFastForwardEnabled(boolean *value) = 0;
    virtual HRESULT STDMETHODCALLTYPE put_IsFastForwardEnabled(boolean value) = 0;
    virtual HRESULT STDMETHODCALLTYPE get_IsRewindEnabled(boolean *value) = 0;
    virtual HRESULT STDMETHODCALLTYPE put_IsRewindEnabled(boolean value) = 0;
    virtual HRESULT STDMETHODCALLTYPE get_IsPreviousEnabled(boolean *value) = 0;
    virtual HRESULT STDMETHODCALLTYPE put_IsPreviousEnabled(boolean value) = 0;
    virtual HRESULT STDMETHODCALLTYPE get_IsNextEnabled(boolean *value) = 0;
    virtual HRESULT STDMETHODCALLTYPE put_IsNextEnabled(boolean value) = 0;
    virtual HRESULT STDMETHODCALLTYPE get_IsChannelUpEnabled(boolean *value) = 0;
    virtual HRESULT STDMETHODCALLTYPE put_IsChannelUpEnabled(boolean value) = 0;
    virtual HRESULT STDMETHODCALLTYPE get_IsChannelDownEnabled(boolean *value) = 0;
    virtual HRESULT STDMETHODCALLTYPE put_IsChannelDownEnabled(boolean value) = 0;
    virtual HRESULT STDMETHODCALLTYPE add_ButtonPressed(IUnknown *handler, EventRegistrationToken *token) = 0;
    virtual HRESULT STDMETHODCALLTYPE remove_ButtonPressed(EventRegistrationToken token) = 0;
    virtual HRESULT STDMETHODCALLTYPE add_PropertyChanged(void *handler, EventRegistrationToken *token) = 0;
    virtual HRESULT STDMETHODCALLTYPE remove_PropertyChanged(EventRegistrationToken token) = 0;
};

struct ISystemMediaTransportControls2 : public IInspectable {
    virtual HRESULT STDMETHODCALLTYPE get_AutoRepeatMode(int *value) = 0;
    virtual HRESULT STDMETHODCALLTYPE put_AutoRepeatMode(int value) = 0;
    virtual HRESULT STDMETHODCALLTYPE get_ShuffleEnabled(boolean *value) = 0;
    virtual HRESULT STDMETHODCALLTYPE put_ShuffleEnabled(boolean value) = 0;
    virtual HRESULT STDMETHODCALLTYPE get_PlaybackRate(double *value) = 0;
    virtual HRESULT STDMETHODCALLTYPE put_PlaybackRate(double value) = 0;
    virtual HRESULT STDMETHODCALLTYPE UpdateTimelineProperties(ISystemMediaTransportControlsTimelineProperties *value) = 0;
    virtual HRESULT STDMETHODCALLTYPE add_PlaybackPositionChangeRequested(IUnknown *handler, EventRegistrationToken *token) = 0;
    virtual HRESULT STDMETHODCALLTYPE remove_PlaybackPositionChangeRequested(EventRegistrationToken token) = 0;
    virtual HRESULT STDMETHODCALLTYPE add_PlaybackRateChangeRequested(void *handler, EventRegistrationToken *token) = 0;
    virtual HRESULT STDMETHODCALLTYPE remove_PlaybackRateChangeRequested(EventRegistrationToken token) = 0;
    virtual HRESULT STDMETHODCALLTYPE add_ShuffleEnabledChangeRequested(void *handler, EventRegistrationToken *token) = 0;
    virtual HRESULT STDMETHODCALLTYPE remove_ShuffleEnabledChangeRequested(EventRegistrationToken token) = 0;
    virtual HRESULT STDMETHODCALLTYPE add_AutoRepeatModeChangeRequested(void *handler, EventRegistrationToken *token) = 0;
    virtual HRESULT STDMETHODCALLTYPE remove_AutoRepeatModeChangeRequested(EventRegistrationToken token) = 0;
};

// Function pointer types for combase.dll
typedef HRESULT (WINAPI *RoInitializeFunc)(int);
typedef HRESULT (WINAPI *RoGetActivationFactoryFunc)(HSTRING, REFIID, void**);
typedef HRESULT (WINAPI *RoActivateInstanceFunc)(HSTRING, IInspectable**);
typedef HRESULT (WINAPI *WindowsCreateStringFunc)(PCNZWCH, UINT32, HSTRING*);
typedef HRESULT (WINAPI *WindowsDeleteStringFunc)(HSTRING);

// Typed event handler COM interfaces
struct ITypedEventHandler_ButtonPressed : public IUnknown {
    virtual HRESULT STDMETHODCALLTYPE Invoke(ISystemMediaTransportControls *sender, ISystemMediaTransportControlsButtonPressedEventArgs *args) = 0;
};

struct ITypedEventHandler_PlaybackPosition : public IUnknown {
    virtual HRESULT STDMETHODCALLTYPE Invoke(ISystemMediaTransportControls2 *sender, IPlaybackPositionChangeRequestedEventArgs *args) = 0;
};

// Button handler COM implementation
class ButtonHandler final : public ITypedEventHandler_ButtonPressed {
public:
    explicit ButtonHandler(SmtcController *parent) : m_parent(parent), m_ref(1) {}

    HRESULT STDMETHODCALLTYPE QueryInterface(REFIID riid, void **ppv) override {
        if (!ppv) return E_POINTER;
        if (riid == IID_IUnknown || riid == IID_ITypedEventHandler_ButtonPressed) {
            *ppv = static_cast<ITypedEventHandler_ButtonPressed*>(this);
            AddRef();
            return S_OK;
        }
        *ppv = nullptr;
        return E_NOINTERFACE;
    }

    ULONG STDMETHODCALLTYPE AddRef() override {
        return InterlockedIncrement(&m_ref);
    }

    ULONG STDMETHODCALLTYPE Release() override {
        ULONG res = InterlockedDecrement(&m_ref);
        if (res == 0) delete this;
        return res;
    }

    HRESULT STDMETHODCALLTYPE Invoke(ISystemMediaTransportControls *sender, ISystemMediaTransportControlsButtonPressedEventArgs *args) override {
        Q_UNUSED(sender);
        if (!args || !m_parent) return S_OK;
        SystemMediaTransportControlsButton btn;
        if (SUCCEEDED(args->get_Button(&btn))) {
            switch (btn) {
            case SystemMediaTransportControlsButton_Play:
                QMetaObject::invokeMethod(m_parent, "playRequested", Qt::QueuedConnection);
                break;
            case SystemMediaTransportControlsButton_Pause:
                QMetaObject::invokeMethod(m_parent, "pauseRequested", Qt::QueuedConnection);
                break;
            case SystemMediaTransportControlsButton_Next:
                QMetaObject::invokeMethod(m_parent, "nextRequested", Qt::QueuedConnection);
                break;
            case SystemMediaTransportControlsButton_Previous:
                QMetaObject::invokeMethod(m_parent, "previousRequested", Qt::QueuedConnection);
                break;
            default:
                break;
            }
        }
        return S_OK;
    }

private:
    SmtcController *m_parent = nullptr;
    LONG m_ref = 1;
};

// Seek handler COM implementation
class SeekHandler final : public ITypedEventHandler_PlaybackPosition {
public:
    explicit SeekHandler(SmtcController *parent) : m_parent(parent), m_ref(1) {}

    HRESULT STDMETHODCALLTYPE QueryInterface(REFIID riid, void **ppv) override {
        if (!ppv) return E_POINTER;
        if (riid == IID_IUnknown || riid == IID_ITypedEventHandler_PlaybackPosition) {
            *ppv = static_cast<ITypedEventHandler_PlaybackPosition*>(this);
            AddRef();
            return S_OK;
        }
        *ppv = nullptr;
        return E_NOINTERFACE;
    }

    ULONG STDMETHODCALLTYPE AddRef() override {
        return InterlockedIncrement(&m_ref);
    }

    ULONG STDMETHODCALLTYPE Release() override {
        ULONG res = InterlockedDecrement(&m_ref);
        if (res == 0) delete this;
        return res;
    }

    HRESULT STDMETHODCALLTYPE Invoke(ISystemMediaTransportControls2 *sender, IPlaybackPositionChangeRequestedEventArgs *args) override {
        Q_UNUSED(sender);
        if (!args || !m_parent) return S_OK;
        TimeSpan span;
        if (SUCCEEDED(args->get_RequestedPlaybackPosition(&span))) {
            const qint64 ms = span.Duration / 10000;
            QMetaObject::invokeMethod(m_parent, "seekRequested", Qt::QueuedConnection, Q_ARG(qint64, ms));
        }
        return S_OK;
    }

private:
    SmtcController *m_parent = nullptr;
    LONG m_ref = 1;
};
#endif

class SmtcController::Private {
public:
#ifdef Q_OS_WIN
    HMODULE hCombase = nullptr;
    RoInitializeFunc pRoInitialize = nullptr;
    RoGetActivationFactoryFunc pRoGetActivationFactory = nullptr;
    RoActivateInstanceFunc pRoActivateInstance = nullptr;
    WindowsCreateStringFunc pWindowsCreateString = nullptr;
    WindowsDeleteStringFunc pWindowsDeleteString = nullptr;
    ISystemMediaTransportControls *controls = nullptr;
    ISystemMediaTransportControls2 *controls2 = nullptr;
    EventRegistrationToken buttonToken = { 0 };
    EventRegistrationToken seekToken = { 0 };
    bool initialized = false;

    bool loadCombase() {
        if (hCombase) return true;
        hCombase = LoadLibraryW(L"combase.dll");
        if (!hCombase) return false;
        pRoInitialize = reinterpret_cast<RoInitializeFunc>(GetProcAddress(hCombase, "RoInitialize"));
        pRoGetActivationFactory = reinterpret_cast<RoGetActivationFactoryFunc>(GetProcAddress(hCombase, "RoGetActivationFactory"));
        pRoActivateInstance = reinterpret_cast<RoActivateInstanceFunc>(GetProcAddress(hCombase, "RoActivateInstance"));
        pWindowsCreateString = reinterpret_cast<WindowsCreateStringFunc>(GetProcAddress(hCombase, "WindowsCreateString"));
        pWindowsDeleteString = reinterpret_cast<WindowsDeleteStringFunc>(GetProcAddress(hCombase, "WindowsDeleteString"));
        return pRoInitialize && pRoGetActivationFactory && pRoActivateInstance && pWindowsCreateString && pWindowsDeleteString;
    }
#endif
};

SmtcController::SmtcController(PlayerController *player, QObject *parent)
    : QObject(parent)
    , d(new Private())
    , m_player(player)
{
    if (m_player) {
        connect(m_player, &PlayerController::currentTrackChanged, this, &SmtcController::onTrackChanged);
        connect(m_player, &PlayerController::isPlayingChanged, this, &SmtcController::onPlayingChanged);
        connect(m_player, &PlayerController::positionChanged, this, &SmtcController::onPositionChanged);
        connect(this, &SmtcController::seekRequested, m_player, &PlayerController::seek);
    }
}

SmtcController::~SmtcController()
{
#ifdef Q_OS_WIN
    if (d->controls2) {
        if (d->seekToken.value != 0) {
            d->controls2->remove_PlaybackPositionChangeRequested(d->seekToken);
        }
        d->controls2->Release();
        d->controls2 = nullptr;
    }
    if (d->controls) {
        d->controls->put_IsEnabled(FALSE);
        if (d->buttonToken.value != 0) {
            d->controls->remove_ButtonPressed(d->buttonToken);
        }
        d->controls->Release();
        d->controls = nullptr;
    }
    if (d->hCombase) {
        FreeLibrary(d->hCombase);
        d->hCombase = nullptr;
    }
#endif
    delete d;
}

void SmtcController::initialize(quintptr hwnd)
{
#ifdef Q_OS_WIN
    if (!hwnd || d->initialized) return;
    if (!d->loadCombase()) return;

    d->pRoInitialize(1); // RO_INIT_MULTITHREADED

    HSTRING hsClassName = nullptr;
    const wchar_t className[] = L"Windows.Media.SystemMediaTransportControls";
    HRESULT hr = d->pWindowsCreateString(className, static_cast<UINT32>(wcslen(className)), &hsClassName);
    if (FAILED(hr)) return;

    ISystemMediaTransportControlsInterop *interop = nullptr;
    hr = d->pRoGetActivationFactory(hsClassName, IID_ISystemMediaTransportControlsInterop, reinterpret_cast<void**>(&interop));
    d->pWindowsDeleteString(hsClassName);

    if (SUCCEEDED(hr) && interop) {
        hr = interop->GetForWindow(reinterpret_cast<HWND>(hwnd), IID_ISystemMediaTransportControls, reinterpret_cast<void**>(&d->controls));
        interop->Release();
    }

    if (SUCCEEDED(hr) && d->controls) {
        d->controls->put_IsEnabled(TRUE);
        d->controls->put_IsPlayEnabled(TRUE);
        d->controls->put_IsPauseEnabled(TRUE);
        d->controls->put_IsNextEnabled(TRUE);
        d->controls->put_IsPreviousEnabled(TRUE);
        d->controls->put_PlaybackStatus(MediaPlaybackStatus_Closed);

        auto handler = new ButtonHandler(this);
        d->controls->add_ButtonPressed(handler, &d->buttonToken);
        handler->Release();

        hr = d->controls->QueryInterface(IID_ISystemMediaTransportControls2, reinterpret_cast<void**>(&d->controls2));
        if (SUCCEEDED(hr) && d->controls2) {
            auto seekHandler = new SeekHandler(this);
            d->controls2->add_PlaybackPositionChangeRequested(seekHandler, &d->seekToken);
            seekHandler->Release();
        }

        d->initialized = true;
        qDebug() << "[SMTC] Windows System Media Transport Controls initialized successfully!";

        // Sync initial state only if a valid track is already loaded
        if (m_player && !m_player->currentTrack().isEmpty()) {
            onTrackChanged();
            onPlayingChanged();
        }
    } else {
        qWarning() << "[SMTC] Failed to initialize SMTC. hr=" << Qt::hex << hr;
    }
#else
    Q_UNUSED(hwnd);
#endif
}

void SmtcController::updateTrack(const QString &title, const QString &artist, const QString &album, const QString &artworkPath)
{
#ifdef Q_OS_WIN
    if (!d->controls || !d->initialized) return;

    ISystemMediaTransportControlsDisplayUpdater *updater = nullptr;
    if (SUCCEEDED(d->controls->get_DisplayUpdater(&updater)) && updater) {
        if (title.trimmed().isEmpty()) {
            updater->ClearAll();
            updater->put_Type(MediaPlaybackType_Unknown);
            updater->Update();
            updater->Release();
            return;
        }

        updater->put_Type(MediaPlaybackType_Music);

        const QUrl artworkUrl(artworkPath);
        const QString localArtworkPath = artworkUrl.isLocalFile() ? artworkUrl.toLocalFile() : artworkPath;
        if (QFileInfo::exists(localArtworkPath)) {
            try {
                const auto file = winrt::Windows::Storage::StorageFile::GetFileFromPathAsync(
                    localArtworkPath.toStdWString()).get();
                const auto thumbnail = winrt::Windows::Storage::Streams::RandomAccessStreamReference::CreateFromFile(file);
                updater->put_Thumbnail(winrt::get_abi(thumbnail));
            } catch (...) {
                qWarning() << "[SMTC] Failed to load artwork:" << localArtworkPath;
            }
        }

        IMusicDisplayProperties *props = nullptr;
        if (SUCCEEDED(updater->get_MusicProperties(&props)) && props) {
            HSTRING hsTitle = nullptr, hsArtist = nullptr, hsAlbum = nullptr;

            std::wstring wTitle = title.toStdWString();
            std::wstring wArtist = artist.toStdWString();
            std::wstring wAlbum = album.toStdWString();

            d->pWindowsCreateString(wTitle.c_str(), static_cast<UINT32>(wTitle.length()), &hsTitle);
            d->pWindowsCreateString(wArtist.c_str(), static_cast<UINT32>(wArtist.length()), &hsArtist);
            d->pWindowsCreateString(wAlbum.c_str(), static_cast<UINT32>(wAlbum.length()), &hsAlbum);

            props->put_Title(hsTitle);
            props->put_Artist(hsArtist);

            if (!wAlbum.empty()) {
                IMusicDisplayProperties2 *props2 = nullptr;
                if (SUCCEEDED(props->QueryInterface(IID_IMusicDisplayProperties2, reinterpret_cast<void**>(&props2))) && props2) {
                    props2->put_AlbumTitle(hsAlbum);
                    props2->Release();
                }
            }

            d->pWindowsDeleteString(hsTitle);
            d->pWindowsDeleteString(hsArtist);
            d->pWindowsDeleteString(hsAlbum);

            props->Release();
        }

        updater->Update();
        updater->Release();
    }
#else
    Q_UNUSED(title); Q_UNUSED(artist); Q_UNUSED(album);
#endif
}

void SmtcController::updatePlaybackStatus(bool isPlaying)
{
#ifdef Q_OS_WIN
    if (!d->controls || !d->initialized) return;
    d->controls->put_PlaybackStatus(isPlaying ? MediaPlaybackStatus_Playing : MediaPlaybackStatus_Paused);
#else
    Q_UNUSED(isPlaying);
#endif
}

void SmtcController::updateTimeline(qint64 positionMs, qint64 durationMs)
{
#ifdef Q_OS_WIN
    if (!d->controls2 || !d->initialized || durationMs <= 0) return;

    HSTRING hsTimelineClass = nullptr;
    const wchar_t className[] = L"Windows.Media.SystemMediaTransportControlsTimelineProperties";
    HRESULT hr = d->pWindowsCreateString(className, static_cast<UINT32>(wcslen(className)), &hsTimelineClass);
    if (FAILED(hr)) return;

    IInspectable *insp = nullptr;
    hr = d->pRoActivateInstance(hsTimelineClass, &insp);
    d->pWindowsDeleteString(hsTimelineClass);

    if (SUCCEEDED(hr) && insp) {
        ISystemMediaTransportControlsTimelineProperties *props = nullptr;
        hr = insp->QueryInterface(IID_ISystemMediaTransportControlsTimelineProperties, reinterpret_cast<void**>(&props));
        insp->Release();

        if (SUCCEEDED(hr) && props) {
            TimeSpan zero = { 0 };
            TimeSpan end = { std::max<qint64>(0, durationMs) * 10000 };
            TimeSpan pos = { std::max<qint64>(0, std::min(positionMs, durationMs)) * 10000 };

            props->put_StartTime(zero);
            props->put_MinSeekTime(zero);
            props->put_EndTime(end);
            props->put_MaxSeekTime(end);
            props->put_Position(pos);

            d->controls2->UpdateTimelineProperties(props);
            props->Release();
        }
    }
#else
    Q_UNUSED(positionMs);
    Q_UNUSED(durationMs);
#endif
}

void SmtcController::onTrackChanged()
{
    if (!m_player) return;
    const QVariantMap track = m_player->currentTrack();
    if (track.isEmpty()) {
        updateTrack(QString(), QString(), QString(), QString());
        return;
    }
    const QString title = track.value("title").toString().isEmpty()
        ? track.value("fileName").toString()
        : track.value("title").toString();
    const QString artist = track.value("artist").toString();
    const QString album = track.value("album").toString();
    const QString artworkPath = track.value("artworkUrl").toString();

    updateTrack(title, artist, album, artworkPath);
    if (m_player->duration() > 0) {
        updateTimeline(m_player->position(), m_player->duration());
    }
}

void SmtcController::onPlayingChanged()
{
    if (!m_player) return;
    updatePlaybackStatus(m_player->isPlaying());
    if (m_player->duration() > 0) {
        updateTimeline(m_player->position(), m_player->duration());
    }
}

void SmtcController::onPositionChanged()
{
    if (!m_player) return;
    if (m_player->duration() > 0) {
        updateTimeline(m_player->position(), m_player->duration());
    }
}
