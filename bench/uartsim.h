/*
 * Graf Research Corporation
 * Copyright (c) 2021-2021
 * Graf Research Proprietary - Do Not Distribute
 */

#ifndef uartsim_H
#define uartsim_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <poll.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <signal.h>

#define	TXIDLE	0
#define	TXDATA	1
#define	RXIDLE	0
#define	RXDATA	1

class Uart
{
    int m_baud_counter;

    int m_rx_baudcounter, m_rx_state, m_rx_bits, m_last_tx;
    int m_tx_baudcounter, m_tx_state, m_tx_busy;
    unsigned m_rx_data, m_tx_data;
public:
    Uart(void);
    void setup(unsigned isetup);
    int operator()(int i_tx);
};


#endif
