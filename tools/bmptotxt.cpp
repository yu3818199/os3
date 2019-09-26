#include "stdio.h"
#include "stdlib.h"
#include "memory.h"
#include "string.h"

int main(int argc, char* argv[])
{
	FILE *fp,*fpw,*fpc;
	char buf[1024*16];
	memset(buf,0,sizeof(buf));

	// 读bmp文件
	fp=fopen("os3.bmp","rb");
	// 写txt文件
	fpw=fopen("os3.txt","wb+");
	// 写txt文件
	fpc=fopen("os3.code","wb+");

	if(fp==NULL) {printf("open error\n");return 0 ;}
	if(fpw==NULL) {printf("open w error\n");return 0 ;}
	if(fpc==NULL) {printf("open c error\n");return 0 ;}

	// 读取bmp文件
	fread(buf,sizeof(buf),1,fp);

	// 原图必须为8位灰度bmp图,20*80
	// 54字节图像头 + 1024字节调色板 + width*height字节（从下往上，从左往右）
	// 跳过文件头54+1024字节
	for(int j=19;j>=0;j--)
	{
		fprintf(fpc,"dw ");
		for(int i=0;i<=79;i++)
		{
			if(buf[j*80+i+54+1024]!=0)
			{
				fprintf(fpw,"*");
			}
			else
			{
				fprintf(fpw,"#");
				fprintf(fpc,",");
				// 将12*40，分解为24*80所在的位置
				fprintf(fpc,"%d",(19-j)*80+i);
			}
		}
		fprintf(fpw,"\n");
		fprintf(fpc,"\n");
	}

	

	fclose(fpw);
	fclose(fpc);
	return 0;
}

