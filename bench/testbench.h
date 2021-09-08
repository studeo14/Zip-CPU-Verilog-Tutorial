/*
 * Graf Research Corporation
 * Copyright (c) 2021-2021
 * Graf Research Proprietary - Do Not Distribute
 */

#ifndef testbench_H
#define testbench_H

#include "verilated.h"
#include "verilated_vcd_c.h"
#include <cstdlib>
#include <cstdio>
#include <string>
#include <memory>

template <class VA>
class Testbench
{
public:
    std::unique_ptr<VA> m_core;
    std::unique_ptr<VerilatedVcdC> m_trace;
    uint64_t m_tickcount;

    Testbench(void) : m_trace(nullptr), m_tickcount(0L)
    {
        m_core = std::make_unique<VA>();
        Verilated::traceEverOn(true);
        m_core->i_clk = 0;
        eval();
    }

    virtual ~Testbench(void)
    {
        closetrace();
    }

    virtual void opentrace(std::string vcdname)
    {
        if (!m_trace)
        {
            m_trace = std::make_unique<VerilatedVcdC>();
            m_core->trace(m_trace.get(), 99);
            m_trace->open(vcdname.c_str());
        }
    }

    virtual void closetrace(void)
    {
        if (!m_trace)
        {
            m_trace->close();
        }
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
        m_core->i_clk = 1;
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
