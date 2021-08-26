/*
 * Graf Research Corporation
 * Copyright (c) 2021-2021
 * Graf Research Proprietary - Do Not Distribute
 */

#include <stdio.h>
#include <stdlib.h>
#include "Vwalker.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

typedef Vwalker DUT;

void tick(unsigned int tickcount, DUT *tb, VerilatedVcdC *tfp);

int main(int argc, char **argv)
{
    int last_led;
    unsigned int tickcount = 0;
    Verilated::traceEverOn(true);
    Verilated::commandArgs(argc, argv);

    DUT *tb = new DUT;
    VerilatedVcdC *tfp = new VerilatedVcdC;
    tb->trace(tfp, 99);
    tfp->open("trace.vcd");

    for (int k = 0; k < (1<<20); k++)
    {
        tick(++tickcount, tb, tfp);

        if (last_led != tb->led)
        {
            printf("k = %7d, ", k);
            printf("led = %d\n", tb->led);
        }
        last_led = tb->led;
    }

}

void tick(unsigned int tickcount, DUT *tb, VerilatedVcdC *tfp)
{
    tb->eval();
    if (tfp)
    {
        tfp->dump(tickcount * 10 - 2);
    }
    tb->i_clk = 1;
    tb->eval();
    if (tfp)
    {
        tfp->dump(tickcount * 10);
    }
    tb->i_clk = 0;
    tb->eval();
    if (tfp)
    {
        tfp->dump(tickcount * 10 + 5);
        tfp->flush();
    }
}
