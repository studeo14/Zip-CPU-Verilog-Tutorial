#include "btnsim.h"
#include <stdlib.h>

Btn::Btn(void)
    : m_state(UNPRESSED), m_timeout(0)
{
    // empty
}

void Btn::press(void)
{
    m_state = PRESSED;
    m_timeout = TIME_PERIOD;
}

void Btn::release(void)
{
    m_state = UNPRESSED;
    m_timeout = TIME_PERIOD;
}

bool Btn::pressed(void)
{
    return m_state == PRESSED;
}

STATE Btn::operator()(void)
{
    if (0 < m_timeout)
    {
        m_timeout--;
    }
    if (TIME_PERIOD - 1 == m_timeout)
    {
        return m_state;
    }
    else if (0 < m_timeout)
    {
        return static_cast<STATE>(rand() & 1);
    }
    // else
    return m_state;
}
