#include "stdio.h"
#include "stdlib.h"
#include "memory.h"
#include "string.h"

int main(int argc, char* argv[])
{
	FILE *fp,*fpw,*fpc;
	char buf[1024*16];
	memset(buf,0,sizeof(buf));

	// ��bmp�ļ�
	fp=fopen("os3.bmp","rb");
	// дtxt�ļ�
	fpw=fopen("os3.txt","wb+");
	// дtxt�ļ�
	fpc=fopen("os3.code","wb+");

	if(fp==NULL) {printf("open error\n");return 0 ;}
	if(fpw==NULL) {printf("open w error\n");return 0 ;}
	if(fpc==NULL) {printf("open c error\n");return 0 ;}

	// ��ȡbmp�ļ�
	fread(buf,sizeof(buf),1,fp);

	// ԭͼ����Ϊ8λ�Ҷ�bmpͼ,20*80
	// 54�ֽ�ͼ��ͷ + 1024�ֽڵ�ɫ�� + width*height�ֽڣ��������ϣ��������ң�
	// �����ļ�ͷ54+1024�ֽ�
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
				// ��12*40���ֽ�Ϊ24*80���ڵ�λ��
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

