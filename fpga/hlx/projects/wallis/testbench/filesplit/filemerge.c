
#include <string.h>
#include <stdlib.h>

#include <stdio.h>

/**
 * @brief Merges files together
 * 
 * @return [description]
 */
int main(int argc, char const *argv[])
{
    char str[80];

    if (argc < 3) 
    {
        printf("Usage: ./filemerge outfile.bin <list of in files>\n");
        return 1;
    }

    FILE* fd;
    long fsize;
	FILE* fo = fopen(argv[1],"wb");

    // Iterate over every line
    for(int i = 0; i < (argc-2); i++)
    {
        // open file
        fd = fopen(argv[i+2],"rb");

        fseek(fd, 0, SEEK_END);
        fsize = ftell(fd);
        fseek(fd, 0, SEEK_SET);  //same as rewind(f);
        char *data = malloc(fsize + 1);
        fread(data, fsize, 1, fd);
        fclose(fd);

        if(fo != NULL)
        {
            fwrite (data , sizeof(char), fsize, fo);
        }
    }

    fclose(fo);
	return 0;
}