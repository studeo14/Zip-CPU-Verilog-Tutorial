
#include <ncurses.h>
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <time.h>
#include <sys/types.h>
#include <signal.h>
#include "verilated.h"
#include "Vdata_debugger.h"
#include "testbench.h"
#include "uartsim.h"

typedef Vdata_debugger DUT;

#define KEY_ESCAPE 27
#define CTRL(X) ((X)&0x01f)

#ifdef OLD_VERILATOR
#define VVAR(A) v__DOT_ ## A
#else
#define VVAR(A) data_debugger__DOT_ ## A
#endif

#define counterv VVAR(_counterv)

int main(int argc, char **argv)
{
    Verilated::commandArgs(argc, argv);
    Testbench<DUT> *tb = new Testbench<DUT>;
    Uart *uart = new Uart();
    unsigned baudclocks;
    baudclocks = tb->m_core->o_setup;
    uart->setup(baudclocks);
    tb->opentrace("data_debugger.vcd");

    initscr();
    raw();
    noecho();
    keypad(stdscr, true);
    halfdelay(1);

    bool done = false;
    unsigned keypresses = 0;
    do
    {
        int chv;
        done = false;
        tb->m_core->i_event = 0;

        chv = getch();
        if (KEY_ESCAPE == chv)
        {
            done = true;
        }
        else if (CTRL('C') == chv)
        {
            done = true;
        }
        else if (ERR != chv)
        {
            tb->m_core->i_event = 1;
        }

        for (int k = 0; k < 1000; k++)
        {
            tb->tick();
            (*uart)(tb->m_core->o_uart_tx);
            keypresses += tb->m_core->i_event;
            tb->m_core->i_event = 0;
        }
    } while(!done);

    endwin();
    printf("\n\nSimulation complete\n");
    printf("%4d key presses sent\n", keypresses);
    printf("%4d key presses registered\n", tb->m_core->counterv);
}
