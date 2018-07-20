

#include <stdio.h>
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
    for(; i < current*numSigns/max; i++) printf("-");
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
    bool showImage = false;

    pthread_t rx_thd; // receive thread
    pthread_t tx_thd; // transmit thread

    tictoc_t tt;
    
    // for debugging
    tictoc_t dt;
    double mean = 0.0;
    dt.fp = NULL;
    dt.bytes = 1024;

    // get filename
    if(argc < 2) 
    {
        printUsage();
        exit(0);
    }
    infilename = argv[1];

    // check for show flag
    if(argc > 2)
    {
        if(strcmp(argv[2], "-s") == 0)
        {
            showImage = true;
        }
    }

    // load image
    ImageHandler* ih = new ImageHandler(infilename);
    ih->load();
    ih->allocateOutputImage("out.tif", (ih->getWidth()-WINDOW_SIZE+1),(ih->getHeight()-WINDOW_SIZE+1));
    tt.fp = NULL;
    tt.bytes = ih->getWidth()*ih->getHeight();

    // Start communication
    Com* com = new Com(ip,42042);

    // Send image width
    com->writeUserReg(1, WINDOW_SIZE); // win size
    com->writeUserReg(2, ih->getWidth());
    com->writeUserReg(0, 1); // new image start
    com->writeUserReg(0, 0);


    // Loop through all lines
    // printf("Start processing file %s on ip %s\n", infilename, ip);
    tic(&tt);
    // for(int currline = 0; currline < (ih->getHeight()-WINDOW_SIZE+1); currline++)
    // {
    //     printProgress(currline, ih->getHeight()-WINDOW_SIZE+1);
        
    //     // Start receiver
    //     com->setupReceive(2222, &ih->outBuf[currline*(ih->getWidth()-WINDOW_SIZE+1)], (ih->getWidth()-WINDOW_SIZE+1));
    //     std::thread rxth(& Com::receive, com);
        
    //     // start transmitter
    //     com->setTransmitPayload(&ih->imBuf[currline*ih->getWidth()], ih->getWidth()*WINDOW_SIZE);
    //     std::thread txth(& Com::transmit, com);

        
    //     // wait for both to finish
    //     txth.join();
    //     tic(&dt);
    //     rxth.join();
    //     // toc(&dt);

    //     mean += (dt.end-dt.start);
    // }
    // For VHDL controller
    int currline = 0;
    
    // First send 20 lines to fill buffers
    for (currline = 0; currline < 20; currline++)
    {
        // printProgress(currline, ih->getHeight());

        // start transmitter
        com->setTransmitPayload(&ih->imBuf[currline*ih->getWidth()], ih->getWidth());
        std::thread txth(& Com::transmit, com);
        txth.join();        
    }

    // send the rest while receiving
    for( ;currline < ih->getHeight(); currline++)
    {
        // printProgress(currline, ih->getHeight());
        
        // Start receiver
        com->setupReceive(2222, &ih->outBuf[currline*(ih->getWidth()-WINDOW_SIZE+1)], (ih->getWidth()-WINDOW_SIZE+1));
        std::thread rxth(& Com::receive, com);
        
        // start transmitter
        com->setTransmitPayload(&ih->imBuf[currline*ih->getWidth()], ih->getWidth());
        std::thread txth(& Com::transmit, com);

        // wait for both to finish
        txth.join();
        // tic(&dt);
        rxth.join();
        // toc(&dt);

        mean += (dt.end-dt.start);
    }

    // printf("Mean time %.2fus\n", mean / (ih->getHeight()-WINDOW_SIZE+1));

    // printf("\nDone\n");
    // toc(&tt);
    double outsize = (ih->getWidth()-WINDOW_SIZE+1)*(ih->getHeight()-WINDOW_SIZE+1);
    // printf("Pixels per second (output): %.2f\n", (outsize) / (tt.end-tt.start) * 1000000.0);
    // printf("Output pixels: %.0f\n", outsize);

    ih->hexDumpOutputImage();
    // ih->storeOutputImage();
    // if(showImage)
    // {
    //     ih->showOutputImage();
    // }
 
    return 0;
}
