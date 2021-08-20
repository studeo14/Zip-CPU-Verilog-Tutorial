/*
 * Graf Research Corporation
 * Copyright (c) 2021-2021
 * Graf Research Proprietary - Do Not Distribute
 */

#include <stdio.h>
#include <stdlib.h>
#include "Vthruwire.h"
#include "verilated.h"

int main(int argc, char **argv)
{
    Verilated::commandArgs(argc, argv);

    Vthruwire *tb = new Vthruwire;

    tb->btn = 0;
    for (int k = 0; k < 20; k++)
    {
        tb->btn = k & 0x1ff;
        tb->eval();

        printf("k = %2d, ", k);
        printf("btn = %3x, ", tb->btn);
        printf("led = %3x\n", tb->led);
    }

}
