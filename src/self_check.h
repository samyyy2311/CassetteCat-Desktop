#pragma once

#include <QDebug>

// Collects a self-check's results and names each one that fails, so a failing run says what broke.
class SelfCheck {
  public:
    explicit SelfCheck(const char *suite) : m_suite(suite) {}

    void expect(bool result, const char *name) {
        if (result)
            return;
        qWarning().noquote() << m_suite << "self-check failed:" << name;
        m_passed = false;
    }

    bool passed() const { return m_passed; }

  private:
    const char *m_suite;
    bool m_passed = true;
};
