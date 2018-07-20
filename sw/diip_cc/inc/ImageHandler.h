
#include <stdint.h>
#include <cv.h>
#include <opencv2/highgui/highgui.hpp>

class ImageHandler
{
public:
	ImageHandler(const char* fname);
	~ImageHandler();

	int getHeight();
	int getWidth();
	int load();
	int allocateOutputImage(const char* fname, size_t w, size_t h);
	int storeOutputImage();
	void hexDumpOutputImage();
	int showOutputImage();


	static int
	LoadImage(uint8_t* ptr, char* fname);

	static int
	StoreImage(uint8_t* ptr, int w, int h, char* fname);

	uint8_t* imBuf; // loaded image buffer
	uint8_t* outBuf; // output image buffer

private:
	char* fname; // file name of input image
	int inWidth;
	int inHeight;
	cv::Mat mimg;

	// output image
	char* out_fname; // file name of input image
	cv::Mat* out_mat;
	int out_width;
	int out_height;


};


