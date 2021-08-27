/*
 * Graf Research Corporation
 * Copyright (c) 2021-2021
 * Graf Research Proprietary - Do Not Distribute
 */

#include <stdio.h>
#include <stdlib.h>
#include "Vwb_walker.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

typedef Vwb_walker DUT;

void tick(unsigned int tickcount, DUT *tb, VerilatedVcdC *tfp);
unsigned wb_read(unsigned a);
void wb_write(unsigned a, unsigned v);

unsigned int tickcount = 0;
DUT *tb;
VerilatedVcdC *tfp;

void tick(void)
{
    tickcount++;
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

unsigned wb_read(unsigned a)
{
    tb->i_cyc = tb->i_stb = 1;
    tb->i_we = 0; tb->eval();
    tb->i_addr = a;

    while(tb->o_stall)
        tick();
    tick();
    tb->i_stb = 0;
    while(!tb->o_ack)
        tick();
    tb->i_cyc = 0;
    return tb->o_data;
}

void wb_write(unsigned a, unsigned v)
{
    tb->i_cyc = tb->i_stb = 1;
    tb->i_we = 1; tb->eval();
    tb->i_addr = 1;
    tb->i_data = v;
    while(tb->o_stall)
        tick();
    tick();
    tb->i_stb = 0;
    while(!tb->o_ack)
        tick();
    tb->i_cyc = 0;
}

int main(int argc, char **argv) {
    int last_led, last_state = 0, state = 0;
  Verilated::traceEverOn(true);
  Verilated::commandArgs(argc, argv);

  // init tb
  tb = new DUT;
  tfp = new VerilatedVcdC;
  tb->trace(tfp, 99);
  tfp->open("wb_walker.vcd");

  printf("Intial state is: 0x%02x\n", wb_read(0));

  for (int cycle = 0; cycle < 2; cycle++)
  {
      for (int i=0;i<5;i++)
          tick();

      wb_write(0,0);
      tick();
      while((state = wb_read(0)) != 0)
      {
          if ((state != last_state) || (tb->o_led != last_led))
          {
              printf("%7d: State #%2d ", tickcount, state);
              for(int j = 0; j < 8; j++)
              {
                  if (tb->o_led & (1<<j))
                      printf("O");
                  else
                      printf("-");
              }
              printf("\n");
          }
          tick();

          last_state = state;
          last_led = tb->o_led;
      }
  }

  tfp->close();
  delete tfp;
  delete tb;
}
