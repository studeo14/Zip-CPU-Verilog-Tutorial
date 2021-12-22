/*
 * Graf Research Corporation
 * Copyright (c) 2021-2021
 * Graf Research Proprietary - Do Not Distribute
 */

#include <Vhellopsalm.h>
#include "uartsim.h"
#include "testbench.h"

typedef Vhellopsalm DUT;

int main(int argc, char **argv)
{
    Verilated::commandArgs(argc, argv);
    auto tb = std::make_unique<Testbench<DUT>>();
    auto uart = std::make_unique<Uart>();
    auto baudclocks = tb->m_core->o_setup;
    uart->setup(baudclocks);

    tb->opentrace("hellopsalm.vcd");

    for (auto clocks = 0; clocks < 16*2000*baudclocks; clocks++)
    {
        tb->tick();
        // apply uart simulation driver
        (*uart)(tb->m_core->o_uart_tx);
    }
}
