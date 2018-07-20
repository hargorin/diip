
#include "ImageHandler.h"

#include <stdlib.h>
#include <stdio.h>
#include <cv.h>
#include <opencv2/highgui/highgui.hpp>

using namespace cv;
using namespace std;

/**
 * @brief      Constructs the object.
 */
ImageHandler::ImageHandler(const char* fn)
{ 
    // store file name
    fname = new char[strlen(fn)+1];
    strcpy(fname,fn);
    
    // read image and get basic image data
    mimg = imread(fname, CV_8UC1);
    inWidth = mimg.cols;
    inHeight = mimg.rows;

    // init
    out_mat = NULL;
}

/**
 * @brief      Destroys the object.
 */
ImageHandler::~ImageHandler()
{

}

/**
 * @brief      Read image height
 *
 * @return     The height.
 */
int ImageHandler::getHeight()
{
    return inHeight;
}

/**
 * @brief      Read image width
 *
 * @return     The width.
 */
int ImageHandler::getWidth()
{
    return inWidth;
}

/**
 * @brief      Loads the entire image to RAM
 *
 * @return     status, 0 if ok
 */
int ImageHandler::load()
{
    // If the image in opencv is stored in memory confinuously
    // we can access it linearly with a pointer to the Mat's data
    if(mimg.isContinuous())
    {
        imBuf = mimg.ptr<uchar>(0);
    }
    else
    {   
        printf("in Mat is not stored continuous!!\n");

        imBuf = (uint8_t*)malloc(mimg.cols * mimg.rows);

        if(!imBuf)
        {
            printf("[ImageHandler::load] malloc failed : %s\n",fname);
            return -1;
        }

        uint32_t i = 0;
        for (int y = 0; y < mimg.rows; y++) {
            for (int x = 0; x < mimg.cols; x++) {
                imBuf[i++] = mimg.at<uchar>(Point(x, y));
            }
        }
    }

    return 0;
}

/**
 * @brief      Allocates memory to store an output image
 *
 * @param[in]  fname  The filename
 * @param[in]  w   image width
 * @param[in]  h   image height
 *
 * @return     status, 0 if ok
 */
int
ImageHandler::allocateOutputImage(const char* fname, size_t w, size_t h)
{
    int allocSize;
    // store file name
    out_fname = new char[strlen(fname)+1];
    strcpy(out_fname,fname);

    // allocate memory
    // round up to the next multiple of 1024 to make UFT packets safe
    int remainder = (w*h) % 1500;
    if (remainder == 0)
        allocSize = w*h;
    else
        allocSize = (w*h) + 1500 - remainder;

    // printf("alloc size=%d\n",allocSize );
    outBuf = new uint8_t[allocSize];
    
    // store size
    out_width = w;
    out_height = h;

    return 0;
}

/**
 * @brief      Stores the output image to the file
 *
 * @return     status, 0 if ok
 */
int 
ImageHandler::storeOutputImage()
{
    if(out_mat == NULL)
    {
        out_mat = new Mat(out_height, out_width, CV_8UC1, outBuf);
    }
    imwrite(out_fname, *out_mat);

    return 0;
}

/**
 * @brief      Dumps the output image in hex format to the console
 */
void 
ImageHandler::hexDumpOutputImage()
{
    for (int i = 0; i < (out_height*out_width); i++)
    {
        printf("%02x\n", outBuf[i]);
    }
}

/**
 * @brief      Displays the output image
 *
 * @return     status, 0 if ok
 */
int 
ImageHandler::showOutputImage()
{
    if(out_mat == NULL)
    {
        out_mat = new Mat(out_height, out_width, CV_8UC1, outBuf);
    }
    imshow( "Output Image", *out_mat );                  
    waitKey(0);  
    
    return 0;
}

/**
 * @brief      Loads a specified image into a new allocated buffer
 *
 * @param      ptr    return of the image destination pointer
 * @param      fname  filename of the image to be loaded
 *
 * @return     status, 0 if OK
 */
int
ImageHandler::LoadImage(uint8_t* ptr, char* fname)
{
    FILE* f = fopen(fname,"rb");
    
    if (!f) {
        printf("[LoadImage] bad path : %s\n",fname);
        return -1;
    }

    Mat img = imread(fname, CV_8UC1);

    ptr = (uint8_t*)malloc(img.cols * img.rows);

    if(!ptr)
    {
        printf("[LoadImage] malloc failed : %s\n",fname);
        return -1;
    }

    uint32_t i = 0;
    for (int y = 0; y < img.rows; y++) {
        for (int x = 0; x < img.cols; x++) {
            ptr[i++] = img.at<uchar>(Point(x, y));
        }
    }

    fclose(f);
    
    return 0;
}

/**
 * @brief      Store the image in ptr to a file
 *
 * @param      ptr    pointer to the pixel data
 * @param[in]  w      image width
 * @param[in]  h      image height
 * @param      fname  output file name
 *
 * @return     status, 0 if ok
 */
int
ImageHandler::StoreImage(uint8_t* ptr, int w, int h, char* fname)
{
    printf("w=%d h=%d fname=%s ptr=%lu\n",w,h,fname,(unsigned long)ptr);
    Mat img(h, w, CV_8UC1, ptr);

    // imshow( "Sobel", img );                  
    // waitKey(0);  
    imwrite( fname, img);

    return 0;
}