
#include <stdint.h>
#include <cstdlib>
#include <pthread.h>

/**
 * @brief      Generates  a connection to one FPGA for data transfer
 */
class Com
{
public:
	Com(const char* ip, int port);
	~Com();

	int
	writeUserReg(uint32_t regadr, uint32_t regval);

	// Receiving
	int
	setupReceive(int port, uint8_t* ptr, size_t size);
	void
	receive(void );
	void
	contReceive(void);

	// Transmitting
	int
	setTransmitPayload(uint8_t* data, size_t size);
	void
	transmit(void);
	uint8_t* rx_data;

private:
	char* ip;
	int tx_port;
	uint8_t tx_tcid; // current send transaction id

	// Receiving
	int rx_port; 	// receive port
	size_t rx_size;

	// Transmitting
	uint8_t* tx_data;
	size_t tx_size;

};