/*
* @Author: Noah Huetter
* @Date:   2017-10-27 08:44:34
* @Last Modified by:   Noah Huetter
* @Last Modified time: 2018-04-05 16:39:16
*/
/**
 * diip wallis filter tool for wallis filtering on the fpga
 */
#include <stdio.h>
#include <stdint.h>

#include "uft.h"

// ============================================================================
// Settings
// ============================================================================
#define FPGA_UFT_DEFAULT_PORT 	42042


// ============================================================================
// Data types
// ============================================================================
typedef struct parms {
	const char* ifile;
	const char* ofile;
	int port;
	const char* ip;
} parms_t;

// ============================================================================
// Function declarations
// ============================================================================
void printUsage(void);
int parseArgs(parms_t* p, int argc, char const *argv[]);
char* findArgKeyValue (const char* key, int argc, char const *argv[]);

// ============================================================================
// Module static data
// ============================================================================


// ============================================================================
// Macros
// ============================================================================


// ============================================================================
// MAIN
// ============================================================================
int main(int argc, char const *argv[])
{
	parms_t par;

	// Parse input arguments
	if(parseArgs(&par, argc, argv))
	{
		printUsage();
		return 0;
	}

	// Read input file
	

	return 0;
}


// ============================================================================
// Module static functions
// ============================================================================

/**
 * @brief      Prints module usage
 */
void printUsage(void)
{
	printf("usage: ./diipwallis [-P port] IP infile outfile\n");
}

/**
 * @brief      Parses input arguments and stores them in params structure
 *
 * @param      p     pointer to an empty parameter structure
 * @param[in]  argc  argument count
 * @param      argv  argument calues
 *
 * @return     0 if success, -1 if error
 */
int parseArgs(parms_t* p, int argc, char const *argv[])
{
	int ret;
	char * val;

	// count arguments
	if (argc < 4) return -1;
	p->port = FPGA_UFT_DEFAULT_PORT;

	if(argc > 4)
	{
		// Check for port information
		val = findArgKeyValue("-P", argc, argv);
		if(val)
		{
			// Use default port
			p->port = FPGA_UFT_DEFAULT_PORT;
		}
		else
		{
			p->port = atoi(val);
		}
	}

	// parse ifile/ofile/IP
	p->ofile = argv[argc-1];
	p->ifile = argv[argc-2];
	p->ip = argv[argc-3];

	return 0;
}

/**
 * @brief      Searches in argv for key and returns its value 
 * after the key 
 *
 * @param[in]  key   the key to search for
 * @param[in]  argc  argument count
 * @param      argv  argument values
 *
 * @return     key value or NULL if no value
 */
char* findArgKeyValue (const char* key, int argc, char const *argv[])
{
	for(int i = 0; i < argc; i++)
	{
		if(strcmp(key, argv[i]) == 0)
		{
			// key found!
			if(i == (argc-1))
			{
				// key is in last position
				return NULL;
			}
			else
			{
				return (char*)argv[i+1];
			}
		}
	}
	return NULL;
}