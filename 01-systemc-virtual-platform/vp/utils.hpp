#ifndef _UTILS_HPP_
#define _UTILS_HPP_

#include "defines.hpp"
#include <systemc>
#include <iostream>
#include <string.h>
#include <bitset>
#include <math.h>
#include <string>
#include <tlm>
#include <vector>

using namespace std;
using namespace sc_core;
using namespace tlm;
//using namespace cv;
using namespace sc_dt;

int toInt(unsigned char *buf);
void toUchar(unsigned char *buf,int val);

#endif
