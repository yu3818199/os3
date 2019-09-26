// rwdisk.cpp 
//

#include "stdafx.h"
#include "windows.h"
#include "winioctl.h"
#include "stdio.h"
#include "stdlib.h"
#include "string.h"

/* 通过Error值拼装错误信息字符串 */
static char ErrorMessage[1024];
char* GetErrorString()
{
	HLOCAL LocalAddress=NULL;
	DWORD ErrorCode=0;
	
	memset(ErrorMessage,0,sizeof(ErrorMessage));

	// 取错误码
	ErrorCode= GetLastError();
	FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER|FORMAT_MESSAGE_IGNORE_INSERTS|FORMAT_MESSAGE_FROM_SYSTEM,  
		NULL,ErrorCode,0,(PTSTR)&LocalAddress,0,NULL);

	// 拼装输出串
	sprintf(ErrorMessage,"[%05d]%s",ErrorCode,(LPSTR)LocalAddress);
	
	// 去回车和换行
	if(ErrorMessage[strlen(ErrorMessage)-1]==0x0a || ErrorMessage[strlen(ErrorMessage)-1]==0x0d)
		ErrorMessage[strlen(ErrorMessage)-1]=0;
	if(ErrorMessage[strlen(ErrorMessage)-1]==0x0a || ErrorMessage[strlen(ErrorMessage)-1]==0x0d)
		ErrorMessage[strlen(ErrorMessage)-1]=0;

    return ErrorMessage;  

}

/* 在屏幕上打印buf内容 */
void display(unsigned char *buf,int size)
{
	char hex[100],asc[100];

	for(int i=0;i<size/16+1;i++)
	{
		memset(hex,0,sizeof(hex));
		memset(asc,0,sizeof(asc));

		for(int j=0;j<16;j++)
		{
			if(i*16+j+1>size)
			{
				break;
			}
			// 打印16进制
			sprintf(hex,"%s %02X",hex,buf[i*16+j]);
			// 打印可见字符
			if(buf[i*16+j]>0x20 && buf[i*16+j]<0x7e)
				sprintf(asc,"%s%c",asc,buf[i*16+j]);
			else
				sprintf(asc,"%s%c",asc,' ');
		}
		if(hex[0]!=0)
			printf("%05X %s %s\n",i*16,hex,asc);
		if((i+1)%32==0 && i!=0)
			printf("-----------------------------------------------------------------------\n");
	}

}


/* 返回磁盘容量 */
double getdisksize_gb(HANDLE hDev)
{

	DWORD BytesReturned;
	GET_MEDIA_TYPES media_types;

	if(DeviceIoControl(hDev,IOCTL_STORAGE_GET_MEDIA_TYPES_EX,NULL,NULL,&media_types,sizeof(media_types),&BytesReturned,(LPOVERLAPPED)NULL)==0)
	{
		printf("DeviceIoControl=[%s]\n",GetErrorString());
		return -1;
	}

	/* 柱面数 */
	double Cylinders=(double)media_types.MediaInfo[0].DeviceSpecific.DiskInfo.Cylinders.HighPart * 256 * 256 * 256 + 
		(double)media_types.MediaInfo[0].DeviceSpecific.DiskInfo.Cylinders.LowPart;
	/* 每柱面磁道数 */
	double TracksPerCylinder=(double)media_types.MediaInfo[0].DeviceSpecific.DiskInfo.TracksPerCylinder;
	/* 每柱面扇区数 */
	double SectorsPerTrack=(double)media_types.MediaInfo[0].DeviceSpecific.DiskInfo.SectorsPerTrack;
	/* 每扇区字节数 */
	double BytesPerSector=(double)media_types.MediaInfo[0].DeviceSpecific.DiskInfo.BytesPerSector;

	/* 返回磁盘容量(GB) */
	return Cylinders*TracksPerCylinder*SectorsPerTrack*BytesPerSector/1024/1024/1024;

}

// 对磁盘扇区数据的读取
BOOL ReadSectors (BYTE bDrive, DWORD dwStartSector, DWORD dwSectors, LPBYTE lpSectBuff)
{
	if (bDrive == 0) return 0;
	char devName[] = "\\\\.\\PhysicalDrive1";
	devName[17]=bDrive;

	// 打开磁盘
	HANDLE hDev = CreateFile(devName, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_FLAG_NO_BUFFERING, NULL);
	if (hDev == INVALID_HANDLE_VALUE){
		printf("CreateFile devName=[%s] ErrorMsg=[%s]\n",devName,GetErrorString());
		return FALSE;
	}

	// 读取内容
	SetFilePointer(hDev, 512 * dwStartSector, 0, FILE_BEGIN);
	DWORD dwCB;
	if(ReadFile(hDev, lpSectBuff, 512 * dwSectors, &dwCB, NULL)==0)
	{
		printf("ReadSectors ErrorMsg=[%s]\n",GetErrorString());
		return FALSE;
	}

	CloseHandle(hDev);

	return TRUE;
}

// 对磁盘扇区数据的写入
BOOL WriteSectors(BYTE bDrive, DWORD dwStartSector, DWORD dwSectors, LPBYTE lpSectBuff)
{
	if (bDrive == 0) return 0;
	char devName[] = "\\\\.\\PhysicalDrive1";
	devName[17]=bDrive;

	// 打开磁盘
	HANDLE hDev = CreateFile(devName, GENERIC_WRITE, FILE_SHARE_WRITE, NULL, OPEN_EXISTING, FILE_FLAG_NO_BUFFERING, NULL);
	if (hDev == INVALID_HANDLE_VALUE){
		printf("CreateFile devName=[%s] ErrorMsg=[%s]\n",devName,GetErrorString());
		return FALSE;
	}

	if(getdisksize_gb(hDev)>16)
	{
		printf("磁盘容量大于16G，不允许写入\n");		
		CloseHandle(hDev);
		return FALSE;
	}

	// 显示磁盘容量
	printf("准备写入磁盘[%s],容量%0.1lfGB,从%d扇区开始写入%d个扇区,是否继续?[Y/N]",devName,getdisksize_gb(hDev),dwStartSector,dwSectors);
	char get_ch=getchar();
	if(get_ch!='Y' && get_ch!='y')
	{
		CloseHandle(hDev);
		return FALSE;
	}

	// 写入内容
	SetFilePointer(hDev, 512 * dwStartSector, 0, FILE_BEGIN);
	DWORD dwCB;
	if(WriteFile(hDev, lpSectBuff, 512 * dwSectors, &dwCB, NULL)==0)
	{
		printf("WriteSectors ErrorMsg=[%s]\n",GetErrorString());
		return FALSE;
	}

	CloseHandle(hDev);

	return TRUE;
}

/* 读取文件内容至缓存中 */
BOOL ReadFile(char *filename,char *readbuf,unsigned int size)
{
	FILE *fp;
	if((fp=fopen(filename,"rb"))==NULL)
	{
		printf("fopen filename=[%s] ErrorMsg=[%s]\n",filename,GetErrorString());
		return FALSE;
	}
	if(fread(readbuf,1,size,fp)!=size)
	{
		printf("fread 文件数据不足 filename=[%s] size=[%d]\n",filename,size);
		fclose(fp);
		return FALSE;
	}
	fclose(fp);
	return TRUE;
}

/* 将缓存内容保存至文件中 */
BOOL WriteFile(char *filename,char *readbuf,unsigned int size)
{
	FILE *fp;
	if((fp=fopen(filename,"wb+"))==NULL)
	{
		printf("fopen filename=[%s] ErrorMsg=[%s]\n",filename,GetErrorString());
		return FALSE;
	}
	if(fwrite(readbuf,1,size,fp)!=size)
	{
		printf("fwrite 文件数据不足 filename=[%s] size=[%d]\n",filename,size);
		fclose(fp);
		return FALSE;
	}
	fclose(fp);
	return TRUE;
}

#define MSG_DISPLAY "打印: rwdisk display [读取磁盘号] [起始扇区] [读取扇区数]"
#define MSG_READ    "读取: rwdisk read    [读取磁盘号] [起始扇区] [读取扇区数] [写入文件名]"
#define MSG_WRITE   "写入: rwdisk write   [写入磁盘号] [起始扇区] [写入扇区数] [读取文件名]"

/* 主程序 */
int main(int argc, char* argv[])
{

	BYTE *readbuff;
	char sFilename[1024];
	BYTE bDrive;
	DWORD StartSectors;
	DWORD Sectors;

	printf("硬盘扇区读取写入工具 @2019\n");

	if(argc<2)
	{
		printf("%s\n%s\n%s\n",MSG_DISPLAY,MSG_READ,MSG_WRITE);
		return -1;
	}
	if(strcmp(argv[1],"display")!=0 &&
		strcmp(argv[1],"write")!=0 &&
		strcmp(argv[1],"read")!=0
		)
	{
		printf("%s\n%s\n%s\n",MSG_DISPLAY,MSG_READ,MSG_WRITE);
		return -1;
	}

	if(strcmp(argv[1],"display")==0)
	{
		if(argc!=5)
		{
			printf("%s\n",MSG_DISPLAY);
			return -1;
		}
		bDrive=argv[2][0];
		StartSectors=atoi(argv[3]);
		Sectors=atoi(argv[4]);
		if(bDrive<'0' || bDrive>'9')
		{
			printf("磁盘号有误\n");
			return -1;
		}
		if(StartSectors<0)
		{
			printf("起始扇区不能小于0\n");
			return -1;
		}
		if(Sectors==0)
		{
			printf("扇区数不能为0\n");
			return -1;
		}

		printf("读取磁盘%c，从%d扇区开始读取%d扇区 \n",bDrive,StartSectors,Sectors);

		readbuff=(BYTE *)malloc(Sectors*512);
		if(readbuff==NULL)
		{
			printf("内存分配失败\n");
			return -1;
		}

		/* 读取扇区内容 */
		if(ReadSectors(bDrive, StartSectors, Sectors, readbuff)==FALSE) {
			return -1;
		}

		display(readbuff,Sectors*512);

		free(readbuff);

		return 0;

	}


	if(strcmp(argv[1],"read")==0)
	{
		if(argc!=6)
		{
			printf("%s\n",MSG_READ);
			return -1;
		}
		bDrive=argv[2][0];
		StartSectors=atoi(argv[3]);
		Sectors=atoi(argv[4]);
		strcpy(sFilename,argv[5]);
		if(bDrive<'0' || bDrive>'9')
		{
			printf("磁盘号有误\n");
			return -1;
		}
		if(StartSectors<0)
		{
			printf("起始扇区不能小于0\n");
			return -1;
		}
		if(Sectors==0)
		{
			printf("扇区数不能为0\n");
			return -1;
		}

		printf("读取磁盘%c，从%d扇区开始读取%d个扇区写入%s文件\n",bDrive,StartSectors,Sectors,sFilename);

		readbuff=(BYTE *)malloc(Sectors*512);
		if(readbuff==NULL)
		{
			printf("内存分配失败\n");
			return -1;
		}

		/* 读取扇区内容 */
		if(ReadSectors(bDrive, StartSectors, Sectors, readbuff)==FALSE) {
			return -1;
		}

		if(WriteFile(sFilename,(char *)readbuff,Sectors*512)==FALSE) {
			return -1;
		}

		printf("写入文件成功\n");

		free(readbuff);

		return 0;

	}


	if(strcmp(argv[1],"write")==0)
	{
		if(argc!=6)
		{
			printf("%s\n",MSG_WRITE);
			return -1;
		}
		bDrive=argv[2][0];
		StartSectors=atoi(argv[3]);
		Sectors=atoi(argv[4]);
		strcpy(sFilename,argv[5]);
		if(bDrive=='0')
		{
			printf("0磁盘是系统盘，不允许写入0磁盘\n");
			return -1;
		}
		if(bDrive<'1' || bDrive>'9')
		{
			printf("磁盘号有误\n");
			return -1;
		}
		if(StartSectors<0)
		{
			printf("起始扇区不能小于0\n");
			return -1;
		}
		if(Sectors==0)
		{
			printf("扇区数不能为0\n");
			return -1;
		}

		printf("读取%s文件，写入磁盘%c，从%d扇区开始写入%d个扇区\n",sFilename,bDrive,StartSectors,Sectors);

		readbuff=(BYTE *)malloc(Sectors*512);
		if(readbuff==NULL)
		{
			printf("内存分配失败\n");
			return -1;
		}

		/* 读取扇区内容并备份 */
		if(ReadSectors(bDrive, StartSectors, Sectors, readbuff)==FALSE) {
			return -1;
		}
		if(WriteFile("Sectors.bak",(char *)readbuff,Sectors*512)==FALSE) {
			return -1;
		}

		/* 读取文件内容 */
		if(ReadFile(sFilename,(char *)readbuff,Sectors*512)==FALSE) {
			return -1;
		}

		/* 写入扇区 */
		if(WriteSectors(bDrive, StartSectors, Sectors, readbuff)==FALSE) {
			return -1;
		}

		printf("写入磁盘成功\n");

		free(readbuff);

		return 0;

	}



	return 0;

}


