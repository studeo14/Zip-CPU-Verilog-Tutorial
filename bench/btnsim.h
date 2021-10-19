#ifndef BTNSIM_H
#define BTNSIM_H

#define TIME_PERIOD 10000

enum STATE
{
    PRESSED = 1,
    UNPRESSED = 0
};

class Btn
{
    STATE m_state;
    int m_timeout;

public:
    Btn(void);
    void press(void);
    void release(void);
    bool pressed(void);
    STATE operator()(void);
};


#endif //BTNSIM_H
