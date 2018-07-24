


#include "Com.h"

#include <stdlib.h>
#include <stdio.h>
#include <pthread.h>
#include <errno.h>

#include "uft.h"

using namespace std;


/**
 * @brief      Constructs the object.
 */
Com::Com(const char* ip, int port)
{
	// Store IP and port
	this->ip = new char[strlen(ip)+1];
    strcpy(this->ip,ip);
	tx_port = port;

	// Init some stuff
	tx_tcid = 0;

	// set verbosity
	uft_set_verbosity(0);
}

/**
 * @brief      Destroys the object.
 */
Com::~Com()
{

}

/**
 * @brief      Write user register value
 *
 * @param[in]  regadr  register address from 0 to 7
 * @param[in]  regval  register value
 */
int
Com::writeUserReg(uint32_t regadr, uint32_t regval)
{
	uft_set_verbosity(0);
	return uft_write_user_register((const char*)this->ip, (uint16_t)this->tx_port, regadr, regval);
}

/**
 * @brief      set the receive listen port
 *
 * @param[in]  port  The port
 * @param[out] ptr   memory location to write to
 * @param[in]  size  Maximum receive size
 *
 * @return     nothing
 */
int
Com::setupReceive(int port, uint8_t* ptr, size_t size)
{
	rx_port = port;
	rx_size = size;
	rx_data = ptr;
}

/**
 * @brief      Receives data
 */
void
Com::receive(void)
{	
	// this->rx_data = new uint8_t[rx_size];
	this->rx_size = uft_receive_data(this->rx_data, this->rx_port);
}

void
Com::contReceive(void)
{	
    int ret = 0, oldret = 42;
    uint32_t stat, oldstat = 42;

    int ctr = 0;
    int ctr2 = 0;
    do
    {
        ret = uft_continuous_receive(this->rx_data, this->rx_size, this->rx_port, UFT_CONT_CNONE, &stat);

        if(stat != oldstat)
        {
        	oldstat = stat;
            ctr2 = 0;
            switch(stat) {
                case UFT_CONT_SINIT: printf("Rx: SINIT\n"); break;
                case UFT_CONT_SWAITFTS: printf("Rx: SWAITFTS\n"); break;
                case UFT_CONT_SRX: printf("Rx: SRX\n"); break;
                case UFT_CONT_SFTP: printf("Rx: SFTP\n"); break;
                case UFT_CONT_SMEMFULL: printf("Rx: SMEMFULL\n"); break;
                default: printf("Rx: stat = %d\n",stat);
            }
        }
        // oldstat = stat;
        // if (oldret != ret | ctr++ == 1000000)
        // {
        //     ctr = 0;
        //     printf("\nret = %d size = %d\n",ret, rx_size);
        //     hexDump(rx_data, 216, 8);
        //     oldret = ret;
        // }
        
    } while(ret < rx_size);
    // printf("Hurray! %d of requested %d bytes received\n", ret, rx_size );
}


/**
 * @brief      Set data to be transmitted
 *
 * @param      data  pointer to the data
 * @param[in]  size  data size in bytes to send
 *
 * @return     status, 0 if ok
 */
int
Com::setTransmitPayload(uint8_t* data, size_t size)
{
	tx_data = data;
	tx_size = size;
}

/**
 * @brief      Transmits data
 */
void
Com::transmit(void)
{
    uft_set_verbosity(0);
	int s = uft_send_data(tx_data, tx_size, this->ip, (uint16_t)this->tx_port);
}