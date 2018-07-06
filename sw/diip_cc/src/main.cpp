

#include <thread>

#include"ImageHandler.h"
#include "Com.h"
#include "util.h"

#define WINDOW_SIZE 21

typedef void * (*THREADFUNCPTR)(void *);

void printProgress(int current, int max)
{
    const int numSigns = 50;
    int i = 0;

    printf("\r"); 
    printf("["); 
    for(; i < current*numSigns/max; i++) printf("=");
    printf(">"); 
    for(; i < numSigns-1; i++) printf(" ");

    printf("]"); 
}

void printUsage()
{
    printf("usage: ./diip_cc infile.jpg\n");
}

int main(int argc, char const *argv[])
{
    const char* infilename;
    const char* ip = "192.168.5.9";

    pthread_t rx_thd; // receive thread
    pthread_t tx_thd; // transmit thread

    tictoc_t tt;

    // get filename
    if(argc < 2) 
    {
        printUsage();
        exit(0);
    }
    infilename = argv[1];

    // load image
    ImageHandler* ih = new ImageHandler(infilename);
    ih->load();
    ih->allocateOutputImage("out.jpg", (ih->getWidth()-WINDOW_SIZE+1),(ih->getHeight()-WINDOW_SIZE+1));
    tt.fp = NULL;
    tt.bytes = ih->getWidth()*ih->getHeight();

    // Start communication
    Com* com = new Com(ip,42042);

    // Send image width
    com->writeUserReg(0, ih->getWidth());


    // Loop through all lines
    printf("Start processing file %s on ip %s\n", infilename, ip);
    tic(&tt);
    for(int currline = 0; currline < (ih->getHeight()-WINDOW_SIZE+1); currline++)
    {
        printProgress(currline, ih->getHeight()-WINDOW_SIZE+1);
        // Start receiver
        com->setupReceive(2222, (ih->getWidth()-WINDOW_SIZE+1));
        std::thread rxth(& Com::receive, com);
        // start transmitter
        com->setTransmitPayload(&ih->imBuf[currline*ih->getWidth()], ih->getWidth()*WINDOW_SIZE);
        std::thread txth(& Com::transmit, com);
        // wait for both to finish
        txth.join();
        rxth.join();
        // copy data to output image
        memcpy(&ih->outBuf[currline*(ih->getWidth()-WINDOW_SIZE+1)], com->rx_data, (ih->getWidth()-WINDOW_SIZE+1));
    }

    printf("\nDone\n");
    toc(&tt);

    ih->showOutputImage();
 
    delete com;
    return 0;
}