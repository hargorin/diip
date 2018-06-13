
#include <string.h>
#include <stdlib.h>

#include <stdio.h>

/**
 * @brief Splits the input file into seperate files for each wallis processing line
 * @details [long description]
 * 
 * @param argc [description]
 * @param argv 1: File name
 * 			   2: Image width
 * 
 * @return [description]
 */
int main(int argc, char const *argv[])
{
    char str[80];

    if (argc < 4) 
    {
        printf("Usage: ./filesplit infile.bin <imgwidth> <outdir>\n");
        return 1;
    }

	FILE* fd = fopen(argv[1],"rb");
    int w = atoi(argv[2]);

    if(fd == NULL) return 1;


    fseek(fd, 0, SEEK_END);
    long fsize = ftell(fd);
    fseek(fd, 0, SEEK_SET);  //same as rewind(f);

    char *data = malloc(fsize + 1);
    fread(data, fsize, 1, fd);
    fclose(fd);

    int h = fsize/w;

    printf("File: %s Width: %d Height: %d\n", argv[1], w, h);
    printf("Buffer size: %ld\n", fsize + 1);

    // Iterate over every line
    for(int i = 0; i < (h-21+1); i++)
    {
        // open file
        sprintf(str, "%s/row_%03d.bin",argv[3], i);
        fd = fopen(str,"wb");
        if(fd != NULL)
        {
            fwrite (&data[w*i] , sizeof(char), 21*w, fd);
        }

        fclose(fd);
    }

	return 0;
}