#include "stdio.h"
#include "memory.h"
#include "string.h"
#include "stdlib.h"

int main(int argc, char* argv[])
{
	FILE *fpi,*fpo;
	char *buf;
	int skip,size,i;

	if(argc!=5)
	{
		printf("dd [infile] [outfile] [skip] [size] \n");
		printf("例:将boot.com写入boot.img文件的0字节至512字节\n");
		printf("   dd boot.com boot.img 0 512 \n");
		return 0;
	}

	printf("infile=%s ",argv[1]);
	printf("outfile=%s ",argv[2]);
	printf("skip=%s ",argv[3]);
	printf("size=%s \n",argv[4]);
	skip=atoi(argv[3]);
	size=atoi(argv[4]);

	if((fpi=fopen(argv[1],"rb"))==NULL)
	{
		printf("open infile [%s] error!",argv[1]);
		return -1;
	}

	if((fpo=fopen(argv[2],"rb+"))==NULL)
	{
		printf("open outfile [%s] error!",argv[2]);
		return -1;
	}

	printf("write [%s] to [%s] .\n",argv[1],argv[2]);

	fseek(fpo,(long)skip,0);

	buf=(char *)malloc(size);
	if(buf==NULL)
	{
		printf("malloc error!\n");
		return -1;
	}
	i=fread(buf,1,size,fpi);
	printf("read %d size.\n",i);
	if(i!=size)
	{
		printf("fread error![%d]\n",i);
		return -1;
	}
	i=fwrite(buf,1,size,fpo);
	printf("write %d size.\n",i);
	if(i!=size)
	{
		printf("fwrite error![%d]\n",i);
		return -1;
	}
	free(buf);
	fclose(fpi);
	fclose(fpo);

	return 0;

}

