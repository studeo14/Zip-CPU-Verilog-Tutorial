/*
 * Graf Research Corporation
 * Copyright (c) 2021-2021
 * Graf Research Proprietary - Do Not Distribute
 */

#include <Vpassthrough.h>
#include "uartsim.h"
#include "testbench.h"
#include <memory>

typedef Vpassthrough DUT;

int main(int argc, char **argv)
{
    Verilated::commandArgs(argc, argv);
    auto tb = std::make_unique<Testbench<DUT>>();
    auto uart = std::make_unique<Uart>();
    auto baudclocks = tb->m_core->o_setup;
    uart->setup(baudclocks);

    tb->opentrace("helloworld.vcd");

    for (auto clocks = 0; clocks < 16*32*baudclocks; clocks++)
    {
        tb->tick();
        // apply uart simulation driver
        (*uart)(tb->m_core->o_uart_tx);
    }
}
