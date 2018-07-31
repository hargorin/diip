
#include "uft.h"
#include <printf.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/**
 * @brief      Sends a command packet and sets the target user register
 * to the specified value
 *
 * @param[in]  argc  The argc
 * @param      argv  The argv
 *
 * @return     { description_of_the_return_value }
 */
int main(int argc, char const *argv[])
{
    uint16_t port;
    const char *reg;
    const char *val;
    const char *ip;
    uint32_t regval;
    uint32_t regadr;

    if(argc < 4)
    {
        printf("Usage: ./sender IP [port] register value\n");
        printf("    IP         destination ip\n");
        printf("    port       destination port\n");
        printf("    register   Target user register 0..7\n");
        printf("    value      data, either base 10 or 16 when beginning with 0x\n");
        return 0;
    }
    if(argc < 5)
    {
        printf("Using default destination port 42042\n");
        port = 42042;
        ip = argv[1];
        reg = argv[2];
        val = argv[3];
    }
    else
    {
        ip = argv[1];
        port = atoi(argv[2]);
        reg = argv[3];
        val = argv[4];
    }

    // Convert input value to decimal
    regadr = atoi(reg);
    if(regadr > 7)
    {
    	printf("Error: register addres %d exceeded maximum register address 7\n",regadr);
    	return 1;
    }
    if(strstr(val,"0x"))
    {
    	// is hex
    	regval = (uint32_t)strtol(val, NULL, 0);
    }
    else
    {
    	// is decimal
    	regval = atoi(val);
    }

    // Lets go!
    printf("Writing 0x%08x to user register %d\n",regval,regadr);
    uft_write_user_register(ip,port,regadr,regval);
    return 0;
}