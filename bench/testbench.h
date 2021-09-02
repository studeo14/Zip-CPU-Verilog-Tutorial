
#ifndef testbench_H
#define testbench_H

#include "verilated.h"
#include "verilated_vcd_c.h"
#include <cstdlib>
#include <cstdio>
#include <string>

using namespace std;

template <class VA>
class testbench
{
public:
    VA *m_core;
    VerilatedVcdC *m_trace;
    uint64_t m_tickcount;

    testbench(void) : m_trace(nullptr), m_tickcount(0L)
    {
        m_core = new VA;
        Verilated::traceEverOn(true);
        m_core->i_clk = 0;
        eval();
    }

    virtual ~testbench(void)
    {
        closetrace();
        delete m_core;
        m_core = nullptr;
    }

    virtual void opentrace(string vcdname)
    {
        m_trace = new VerilatedVcdC;
        m_core->trace(m_trace, 99);
        m_trace->open(vcdname.c_str());
    }

    virtual void closetrace(void)
    {
        m_trace->close();
        delete m_trace;
        m_trace = nullptr;
    }

    virtual void eval(void)
    {
        m_core->eval();
    }

    virtual void tick(void)
    {
      m_tickcount++;
      eval();
      if (m_trace) {
        m_trace->dump(m_tickcount * 10 - 2);
      }
      m_trace->i_clk = 1;
      eval();
      if (m_trace) {
        m_trace->dump(m_tickcount * 10);
      }
      m_core->i_clk = 0;
      eval();
      if (m_trace) {
        m_trace->dump(m_tickcount * 10 + 5);
        m_trace->flush();
      }
    }
};

#endif
